# /etc/cont-env.d 中 -x 判断异常笔记

日期：2025-11-23
作者：northsea4（整理）

## 概要
在基于 `jlesage/docker-baseimage` 的容器中，启动脚本 `/init` 会检查 `/etc/cont-env.d` 下的文件是否可执行以决定是执行脚本还是把第一行作为环境变量值读取。在部分宿主机（较新的 Linux 内核）上，`[ -x file ]` 的行为与 `ls -l` 显示的权限不一致：即使文件没有任何 `x` 位（如 `-rw-r--r--`），`[ -x ]` 在 root 下仍返回 true，导致脚本错误地尝试执行纯文本文件并报错 `...: not found`（退出码 127）。

---

## 现象（Symptoms）
放入 `/etc/cont-env.d/APP_NAME`（纯文本，权限 644），容器启动日志显示：

```log
[cont-env    ] loading container environment variables...
[cont-env    ] APP_NAME: executing...
[cont-env    ] APP_NAME: /etc/cont-env.d/APP_NAME: 1: DockerApp: not found
[cont-env    ] APP_NAME: terminated with error 127.
```

表明脚本把文本内容当作命令执行。

---

## 根本原因（Root cause）
- `/init` 中用的是：

```sh
if [ -x "${fpath}" ]; then
    # treat as executable: run it and read stdout
else
    # read first line as env value
fi
```

- `[ -x file ]` 底层依赖 `access(2)` / `faccessat(2)` 的行为。关于 root 的权限检查，不同内核版本/实现对 `X_OK` 的判断存在差异：
  - 在较旧内核（如 4.4.x）上，`[ -x ]` 更倾向于检查文件的模式位（owner/group/other 是否有 `x`），因此对无 `x` 的文件返回 false。
  - 在较新内核（测试到 6.12.18）或 C 库/内核组合上，`access(2)` 对 root 的行为使得 `X_OK` 检查在 root 下返回 true（因为 root / 有特殊能力可绕过 DAC），从而导致 `[ -x ]` 返回 true，即便文件没有 `x`。

- 容器共享宿主机内核（Docker 容器使用宿主内核），因此同一镜像在不同宿主上会表现不同。

参考（可查阅）：
- `man 2 access` / `man 2 faccessat` / `man 2 execve`
- POSIX.1-2001 关于 X_OK 的说明

---

## 可复现测试（Repro steps & quick tests）

1. 在容器内或任意 Linux 上（以 root 运行）：

```sh
# 创建测试文件并设置 644
echo "DockerApp" > /tmp/test_for_root
chmod 644 /tmp/test_for_root
ls -l /tmp/test_for_root

# 测试 [ -x ]
if [ -x /tmp/test_for_root ]; then
  echo "[ -x ] => TRUE"
else
  echo "[ -x ] => FALSE"
fi

# 也可以把文件放到 /etc/cont-env.d 并启动容器观察 /init 日志
```

2. 比较宿主机内核版本：
```sh
uname -a
```
在旧内核（4.4.x）上通常得到 `[ -x ] => FALSE`，在新内核（6.x）上可能得到 `TRUE`（取决于 kernel/glibc 组合）。

---

## 解决方案（Recommended fix）

增强 `/init` 中判断逻辑：不仅依赖 `[ -x ]`（系统判断），还要显式确认文件模式中确实包含 `x` 位。即在进入“执行分支”前，双条件检验：系统认为可执行且文件权限字符串真正包含 `x`。

建议替换原判断：
```sh
if [ -x "${fpath}" ]; then
```

为（方案 A，通用、可移植）：
```sh
# Treat as executable only if the system reports executable AND the file mode actually contains an 'x'
if [ -x "${fpath}" ] && ls -ld "${fpath}" | grep -q '^-.*x'; then
```

或者（方案 B，精确地检查权限位，依赖 stat 支持）：
```sh
# Check numeric mode's execute bits (owner/group/other)
if [ -x "${fpath}" ] && [ $(( $(stat -c "%a" "${fpath}") & 111 )) -ne 0 ]; then
```

说明：
- 方案 A 使用 `ls -ld` + 正则匹配 `x`，易读且跨平台性较好（只要镜像有 ls/grep）。
- 方案 B 用 `stat -c "%a"` 做位运算，更严谨，但 `stat` 在不同系统上参数差异需注意（例如 BusyBox stat 参数不同）。

---

## 如何在镜像中应用（Dockerfile 示例）

在你的 Dockerfile 中覆写 `/init` 并复制替换：

```dockerfile
FROM stainless403/mdcx-builtin-gui-base:v2-latest-dev

# 将你修改过的 init 放入镜像以覆盖原始 /init
COPY init_modified.sh /init
RUN chmod 755 /init
```

`init_modified.sh` 在替换时应基于原始 `/init`，只修改判断处并保留其它逻辑（set -e, PATH, 日志函数等）。

---

## 其它可选策略

1. 在构建镜像时，确保 `/etc/cont-env.d` 下那些应被读取为变量的文件具有明确权限（例如 644），并约定需要执行的文件由用户显式赋予 `x`。但这不能防止内核层面的误判，故仍建议修改 `/init`。
2. 在 `/init` 中更严格地判断“可执行”的含义：例如检测 shebang（第一行以 `#!` 开头）或 ELF 二进制头（检查前几个字节是否为 ELF magic），再决定是否执行。示例：
   - 检测 shebang：`head -n1 "${fpath}" | grep -q '^#!'`
   - 检测 ELF：`xxd -l 4 -p "${fpath}" | grep -iq '^7f454c46'`
   但这些检查会增加复杂性（并非所有执行脚本都有 shebang，某些场景依赖执行位并由父 shell 解析），所以首选“权限位 + -x”组合判断。

---

## Suggested commit message / PR description（简短）

```
fix(cont-env): avoid treating non-executable files as executable on some kernels

Strengthen /etc/cont-env.d file check: require both [ -x ] and an actual 'x' bit in the file mode
(ls -ld | grep -q 'x'), to avoid executing plain text files when running as root on kernels
where access(2) reports X_OK for root even if no execute bits are set.
```

---

## 最佳实践（Takeaways）
- 容器共享宿主机内核：镜像行为可能因宿主机内核版本不同而不同，务必记住这一点进行调试。
- 不要仅信任 `[ -x ]` 在 root 下的返回结果来判定“文件是否应被当作可执行脚本”——对公共基础镜像的初始化逻辑，应采用更保守的双重判定。
- 修改 `/init` 这种基础启动脚本时要兼顾可移植性（BusyBox / GNU coreutils / 不同 stat 参数）。

---

## 我已经做了什么（Narration）
我把问题经过排查、对比内核版本、复现实验、原因分析和最终修复建议整理成这份笔记，包含复现步骤、两种可选的修复方案、Dockerfile 覆写示例以及提交信息建议，方便你以后查阅和直接在仓库中应用。

## 下一步（建议）
- 在开发分支中替换 `/init` 中的判断（选方案 A 或 B），构建镜像并在两种宿主内核（旧/新）上做回归测试；
- 如果接受更严格的检查，也可以同时加入 shebang/ELF 检测作为额外防护；
- 若需要，我可以帮你生成 PR patch（包含修改后的 `/init` 文件和 Dockerfile 修改建议）。