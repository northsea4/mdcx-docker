## 平台支持说明

**当前状态**：
- ✅ **AMD64 构建**：已跟进上游 PyQt6 构建链路
- ✅ **ARM64 构建**：已并入同一发布链路

**验证结果（2026-05）**：
- ✅ `mdcx-builtin-gui-base` 在 AMD64 本地回归验证通过。
- ✅ `mdcx-builtin-gui-base` 在 ARM64 试验环境验证通过。

**说明**：当前 CI 已发布 `linux/amd64,linux/arm64` 单一标签多架构 manifest。

**详细信息**：参见 [ARM64 构建问题调查报告](arm64-building-issue.md)

### PyQt6 标签策略

- 新增/默认标签统一使用 `-pyqt6` 后缀。
- 多架构统一使用“单一标签”发布（同一个 tag 下同时包含 amd64 与 arm64）。
- 建议发布链路按以下顺序：`build-mdcx-base` -> `build-mdcx` -> `gui-base` -> `webtop-base` -> `mdcx-builtin-gui-base`/`mdcx-builtin-webtop-base`。
- 在 `workflow_dispatch` 中，相关 workflow 的默认输入已切换到 `v2-latest-pyqt6`。

### 单一标签多架构发布流程（推荐）

> 目标：一次发布同一 tag，产出 `linux/amd64` + `linux/arm64` manifest。

1. 触发 `build-mdcx-base.yml`
  - 产物：`build-mdcx-base:<tag>`（多架构）
2. 触发 `build-mdcx.yml`
  - 输入：上一步 base tag
  - 产物：`build-mdcx:<tag>`（多架构，仅存储 `/MDCx`）
3. 触发 `gui-base.yml` 与 `webtop-base.yml`
  - 产物：`gui-base:<tag>`、`webtop-base:<tag>`（多架构）
4. 触发 `mdcx-builtin-gui-base.yml` 与 `mdcx-builtin-webtop-base.yml`
  - 输入：`MDCX_BIN_IMAGE_TAG` 指向 `build-mdcx` 同版 tag
  - 产物：最终运行镜像（多架构）

### 单标签多架构构建命令（参考单架构流程）

> 这一节是“命令版”流程：构建顺序与单架构一致，只是把 `--platform` 改为双架构，并使用 `--push` 发布同一 tag 的 manifest。

```bash
# 0) 前置：准备源码并登录镜像仓库
bash prepare-src.sh --context build-mdcx --repo Hazard804/mdcx --tag latest
docker login

# 1) 统一版本变量（示例）
export BASE_TAG=v2-latest-pyqt6
export BIN_TAG=v2-hazard804-latest-pyqt6
export PLATFORMS=linux/amd64,linux/arm64
```

```bash
# 2) build-mdcx-base（单标签多架构）
docker buildx build \
  --platform ${PLATFORMS} \
  --push \
  -t stainless403/build-mdcx-base:${BASE_TAG} \
  -f build-mdcx/Dockerfile.build-mdcx-base .

# 3) build-mdcx（单标签多架构）
docker buildx build \
  --platform ${PLATFORMS} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --push \
  -t stainless403/build-mdcx:${BIN_TAG} \
  -f build-mdcx/Dockerfile.build-mdcx .

# 4) gui-base（单标签多架构）
docker buildx build \
  --platform ${PLATFORMS} \
  --push \
  -t stainless403/gui-base:${BASE_TAG} \
  -f gui-base/Dockerfile.gui-base .

# 5) webtop-base（单标签多架构）
docker buildx build \
  --platform ${PLATFORMS} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --push \
  -t stainless403/webtop-base:${BASE_TAG} \
  -f webtop-base/Dockerfile.webtop-base .

# 6) mdcx-builtin-gui-base（单标签多架构）
docker buildx build \
  --platform ${PLATFORMS} \
  --build-arg MDCX_BIN_IMAGE_TAG=${BIN_TAG} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --push \
  -t stainless403/mdcx-builtin-gui-base:${BIN_TAG} \
  -f gui-base/Dockerfile.mdcx-builtin-gui-base .

# 7) mdcx-builtin-webtop-base（单标签多架构）
docker buildx build \
  --platform ${PLATFORMS} \
  --build-arg MDCX_BIN_IMAGE_TAG=${BIN_TAG} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --push \
  -t stainless403/mdcx-builtin-webtop-base:${BIN_TAG} \
  -f webtop-base/Dockerfile.mdcx-builtin-webtop-base .
```

补充说明：
- 单标签多架构发布必须使用 `--push`（或 `--output=type=registry`），不能使用 `--load`。
- `--load` 仅适合本地单架构调试；本地分架构测试请继续使用下方“本地 AMD64/ARM64 构建与测试流程”。

### 多架构验收命令

发布后可用以下方式确认 tag 已包含双架构：

```bash
docker buildx imagetools inspect stainless403/build-mdcx:v2-latest-pyqt6
docker buildx imagetools inspect stainless403/gui-base:v2-latest-pyqt6
docker buildx imagetools inspect stainless403/mdcx-builtin-gui-base:v2-latest-pyqt6
```

期望输出中包含：
- `Platform: linux/amd64`
- `Platform: linux/arm64`

### 回滚建议

- 如果某个版本的 arm64 构建异常，优先回滚到上一个可用 tag，避免覆盖稳定 tag。
- 回滚时保持“同一 tag 双架构”原则，避免临时拆分出单架构 tag 导致下游拉取行为不一致。

### 运行问题记录

- 现象：`ImportError: libEGL.so.1: cannot open shared object file`。
- 原因：运行镜像缺少 EGL 运行库。
- 修复：在 `gui-base` 运行层安装 `libegl1`（见 `gui-base/Dockerfile.gui-base`）。
- ARM64 下额外缺库：`libSM.so.6`、`libtiff.so.6`、`libwebpdemux.so.2`。
- 对应修复：补充 `libsm6`、`libtiff6`、`libwebpdemux2`（见 `gui-base/Dockerfile.gui-base`）。

---

## 镜像构建流程

### 准备源码

```bash
bash prepare-src.sh --context build-mdcx --repo Hazard804/mdcx --tag latest
```

### build-mdcx-base镜像

```bash
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t stainless403/build-mdcx-base:v2-amd64-pyqt6 \
  -f build-mdcx/Dockerfile.build-mdcx-base .
```

### build-mdcx镜像

```bash
export BASE_IMAGE_TAG=v2-amd64-pyqt6
docker buildx build \
  --platform linux/amd64 \
  --build-arg BASE_IMAGE_TAG \
  --load \
  -t stainless403/build-mdcx:v2-hazard804-amd64-pyqt6 \
  -f build-mdcx/Dockerfile.build-mdcx .
```

### gui-base镜像

```bash
docker buildx build \
  --platform linux/amd64 \
  --load \
  -t stainless403/gui-base:v2-amd64-pyqt6 \
  -f gui-base/Dockerfile.gui-base .
```

> 说明：`gui-base` 需要补齐 PyQt6 运行时依赖（如 `libxkbcommon0`、`libdbus-1-3`、`libglib2.0-0`、`libx11-6`、`libfreetype6` 等），以保证可运行 `build-mdcx` 产出的 PyQt6 二进制。

### mdcx-builtin-gui-base镜像

```bash
export MDCX_BIN_IMAGE_TAG=v2-hazard804-amd64-pyqt6
export BASE_IMAGE_TAG=v2-amd64-pyqt6
docker buildx build \
  --platform linux/amd64 \
  --build-arg MDCX_BIN_IMAGE_TAG \
  --build-arg BASE_IMAGE_TAG \
  --load \
  -t stainless403/mdcx-builtin-gui-base:$MDCX_BIN_IMAGE_TAG \
  -f gui-base/Dockerfile.mdcx-builtin-gui-base .
```

### webtop-base镜像

> TODO: 暂时未测试构建。

```bash
export MDCX_BIN_IMAGE_TAG=v2-hazard804-amd64-pyqt6
docker buildx build \
  --platform linux/amd64 \
  --build-arg MDCX_BIN_IMAGE_TAG \
  --load \
  -t stainless403/mdcx-builtin-webtop-base:$MDCX_BIN_IMAGE_TAG \
  -f webtop-base/Dockerfile.mdcx-builtin-webtop-base .
```

---

## 本地 AMD64/ARM64 构建与测试流程

> 适用场景：在本地机器上分别构建 amd64 与 arm64 镜像，并快速做可运行性验证。

### 前置准备

```bash
# 1) 准备源码
bash prepare-src.sh --context build-mdcx --repo Hazard804/mdcx --tag latest

# 2) 确认 buildx 可用
docker buildx version

# 3) 如需跨架构构建，确保已安装并启用 qemu/binfmt
docker run --privileged --rm tonistiigi/binfmt --install all
```

### 本地构建约定

- 使用 `--load` 时，每次只能加载单一架构镜像到本地 Docker images。
- 因此本地测试建议“同一套流程跑两次”：一次 `linux/amd64`，一次 `linux/arm64`。
- 推荐标签后缀：`-amd64-pyqt6`、`-arm64-pyqt6`，避免本地镜像互相覆盖。

### 本地 AMD64 构建

```bash
export ARCH=amd64
export PLATFORM=linux/amd64
export BASE_TAG=v2-${ARCH}-pyqt6
export BIN_TAG=v2-hazard804-${ARCH}-pyqt6

# build-mdcx-base
docker buildx build \
  --platform ${PLATFORM} \
  --load \
  -t stainless403/build-mdcx-base:${BASE_TAG} \
  -f build-mdcx/Dockerfile.build-mdcx-base .

# build-mdcx
docker buildx build \
  --platform ${PLATFORM} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --load \
  -t stainless403/build-mdcx:${BIN_TAG} \
  -f build-mdcx/Dockerfile.build-mdcx .

# gui-base
docker buildx build \
  --platform ${PLATFORM} \
  --load \
  -t stainless403/gui-base:${BASE_TAG} \
  -f gui-base/Dockerfile.gui-base .

# mdcx-builtin-gui-base
docker buildx build \
  --platform ${PLATFORM} \
  --build-arg MDCX_BIN_IMAGE_TAG=${BIN_TAG} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --load \
  -t stainless403/mdcx-builtin-gui-base:${BIN_TAG} \
  -f gui-base/Dockerfile.mdcx-builtin-gui-base .
```

### 本地 ARM64 构建

```bash
export ARCH=arm64
export PLATFORM=linux/arm64
export BASE_TAG=v2-${ARCH}-pyqt6
export BIN_TAG=v2-hazard804-${ARCH}-pyqt6

# build-mdcx-base
docker buildx build \
  --platform ${PLATFORM} \
  --load \
  -t stainless403/build-mdcx-base:${BASE_TAG} \
  -f build-mdcx/Dockerfile.build-mdcx-base .

# build-mdcx
docker buildx build \
  --platform ${PLATFORM} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --load \
  -t stainless403/build-mdcx:${BIN_TAG} \
  -f build-mdcx/Dockerfile.build-mdcx .

# gui-base
docker buildx build \
  --platform ${PLATFORM} \
  --load \
  -t stainless403/gui-base:${BASE_TAG} \
  -f gui-base/Dockerfile.gui-base .

# mdcx-builtin-gui-base
docker buildx build \
  --platform ${PLATFORM} \
  --build-arg MDCX_BIN_IMAGE_TAG=${BIN_TAG} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --load \
  -t stainless403/mdcx-builtin-gui-base:${BIN_TAG} \
  -f gui-base/Dockerfile.mdcx-builtin-gui-base .

# webtop-base
docker buildx build \
  --platform ${PLATFORM} \
  --load \
  -t stainless403/webtop-base:${BASE_TAG} \
  -f webtop-base/Dockerfile.webtop-base .

# mdcx-builtin-webtop-base
docker buildx build \
  --platform ${PLATFORM} \
  --build-arg MDCX_BIN_IMAGE_TAG=${BIN_TAG} \
  --build-arg BASE_IMAGE_TAG=${BASE_TAG} \
  --load \
  -t stainless403/mdcx-builtin-webtop-base:${BIN_TAG} \
  -f webtop-base/Dockerfile.mdcx-builtin-webtop-base .
```

### 本地快速测试

```bash
# 检查镜像存在
docker image ls | rg 'build-mdcx|gui-base|mdcx-builtin-gui-base'

# 验证内置镜像可启动二进制（amd64 示例）
docker run --rm --platform linux/amd64 \
  stainless403/mdcx-builtin-gui-base:v2-hazard804-amd64-pyqt6 \
  cat /app-version

# 验证内置镜像可启动二进制（arm64 示例）
docker run --rm --platform linux/arm64 \
  stainless403/mdcx-builtin-gui-base:v2-hazard804-arm64-pyqt6 \
  cat /app-version
```

### 注意事项

- Apple Silicon 主机运行 amd64 镜像时，出现平台转换提示属于预期。
- 若使用 compose，请在镜像 tag 中显式区分架构，避免误拉取。
- 在 OrbStack 场景下，若 UI 面板状态异常，建议优先以 `http://localhost:<端口>` 直连确认服务可用性。
