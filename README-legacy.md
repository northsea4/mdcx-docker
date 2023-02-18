## ⚠️⚠️⚠️ IMPORTANT ⚠️⚠️⚠️
当前为旧版说明，新版说明在 [这里](https://github.com/northsea4/mdcx-docker)。
旧版不再维护也不建议参考。

## 0. 必看

## 0.1 USER_ID和GROUP_ID
```bash
# 获取当前用户的
id
# 获取指定用户的
id admin

# 获取USER_ID
id -u admin
# 获取GROUP_ID
id -g admin
```
容器内置了一个用户，名为`app`，其`用户ID`和`分组ID`对应了部署容器时指定的`USER_ID`和`GROUP_ID`这两个环境变量。
默认都为`0`，即`root`用户。
`app`是运行MDCx的用户，也就是MDCx产生的文件，比如nfo、海报等，默认都是归属于`app`这个用户的。
进一步说，如果`app`用户不具备某些文件的权限，则MDCx可能会运行异常。
比如，如下场景：
- 配置目录映射：`./config:/mdcx_config`，且在MDCx设置了配置目录为`/mdcx_config`
- `./config`目录归属于`root`且权限不是`777`，比如是`755`
- 使用普通用户的`USER_ID`和`GROUP_ID`
  
这个情况下，MDCx由于没有`/mdcx_config`目录的写入权限，在保存配置文件时，会报错，导致容器退出：
> 关键日志：PermissionError: [Errno 13] Permission denied
```log
mdcx   | [app         ] Traceback (most recent call last):
mdcx   | [app         ]   File "/app/MDCx_Main.py", line 3971, in pushButton_save_new_config_clicked
mdcx   | [app         ]     self.pushButton_save_config_clicked()
mdcx   | [app         ]   File "/app/MDCx_Main.py", line 3958, in pushButton_save_config_clicked
mdcx   | [app         ]     self.save_config_clicked()
mdcx   | [app         ]   File "/app/MDCx_Main.py", line 4939, in save_config_clicked
mdcx   | [app         ]     cf.save_config(json_config)
mdcx   | [app         ]   File "/app/Function/config.py", line 557, in save_config
mdcx   | [app         ]     with open(config_path, "wt", encoding='UTF-8') as code:
mdcx   | [app         ] PermissionError: [Errno 13] Permission denied: '/mdcx_config/config3.ini'
mdcx   | [app         ] Fatal Python error: Aborted
mdcx   | [app         ] Current thread 0x00007fd625215740 (most recent call first):
mdcx   | [app         ]   File "/app/MDCx_Main.py", line 13568 in <module>
mdcx   | [app         ] Aborted (core dumped)
mdcx   | [supervisor  ] service 'app' exited (with status 134).
mdcx   | [supervisor  ] service 'app' exited, shutting down...
```


## 1. mdcx-base示例
[stainless403/mdcx-base](https://hub.docker.com/r/stainless403/mdcx-base)镜像没有内置MDCx，如果想使用内置的，请使用[stainless403/mdcx](https://hub.docker.com/r/stainless403/mdcx)镜像。

🔗 [stainless403/mdcx示例](#2-mdcx示例)

下面主要讲述`docker-compose`的部署方式。
`docker-run`的方式也有简单的示例。

### 1.1 准备项目目录
建议使用 [示例项目](https://github.com/northsea4/mdcx-docker/archive/refs/heads/main.zip) 结构，解压到合适的位置后，进入项目目录，之后的操作，如无特殊说明，都是在该目录(假设名为`mdcx-docker`)内进行。

### 1.2 准备应用源码
   
1. 访问 [MDCx发布仓库](https://github.com/anyabc/something/releases/tag/MDCx)，
下载源码版的压缩包(`MDCx-py-`开头)，如`MDCx-py-20230127.rar`。

> 也可以使用`update-app.sh`工具，现在已支持完成第1次源码的部署工作。但请注意，该工具只是为你下载并解压应用源码，不会部署docker容器。

1. 将`MDCx-py-20230127.rar`里的文件放到`app`目录。
整个docker项目的结构大致如下：
```
mdcx-docker
  |-- app
    |-- Data
    |-- Function
    |-- Getter
    |-- Img
    |-- LICENSE
    |-- MDCx_Main.py
    |-- requirements.txt
    |-- setup.py
    |-- Ui
    ...
  |-- config
    |-- config.ini
    |-- config-vip.ini
    |-- config-test.ini
  |-- logs
    |-- 2023-02-04-01-15-00.txt
  |-- .env
  |-- .env.sample
  |-- .env.versions
  |-- docker-compose.mdcx-base.sample.yml
  |-- docker-compose.mdcx.sample.yml
  |-- docker-compose.yml
  |-- update-app.sh
```

### 1.2 设置参数
复制一份`docker-compose.mdcx-base.sample.yml`：
```bash
cp docker-compose.mdcx-base.sample.yml docker-compose.yml
```

#### 1.2.1 映射
修改`docker-compose.yml`，在`volumes`下添加映射。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2`，这样在MDCx内访问也是一样的路径。

#### 1.2.2 环境变量
复制一份`.env.sample`：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
```shell
TZ=Asia/Shanghai

# 应用窗口宽度
DISPLAY_WIDTH=1200
# 应用窗口高度
DISPLAY_HEIGHT=750

# 访问密码，如不需要，留空。如果有在公网远程访问的需求，建议设置
VNC_PASSWORD=

# 网页访问端口
WEB_LISTENING_PORT=5800
# VNC监听端口
VNC_LISTENING_PORT=5900

# 运行应用的用户ID
USER_ID=0
# 运行应用的用户组ID
GROUP_ID=0

# python软件包加速镜像
# 豆瓣
PYPI_MIRROR=https://pypi.doubanio.com/simple
# 清华
# PYPI_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple
# 默认
# PYPI_MIRROR=https://pypi.org/simple

# 容器名称
CONTAINER_NAME=mdcx
```

#### 1.2.3 完整docker-compose.yml示例
```yml
version: '3'

services:
  mdcx:
    image: stainless403/mdcx-base:latest
    container_name: ${CONTAINER_NAME}
    volumes:
      # `stainless403/mdcx-base`镜像没有内置MDCx，需要自行将代码解压到app目录并映射到容器内
      - ./app:/app

      # 配置目录
      - ./config:/mdcx_config

      # 日志目录
      - ./logs:/app/Log

      # 影片目录
      - /volume2:/volume2
      - /volume3:/volume3
    environment:
      - TZ=${TZ}
      # 应用窗口宽度
      - DISPLAY_WIDTH=${DISPLAY_WIDTH}
      # 应用窗口高度
      - DISPLAY_HEIGHT=${DISPLAY_HEIGHT}
      # 访问密码
      - VNC_PASSWORD=${VNC_PASSWORD}
      # 运行应用的用户ID
      - USER_ID=${USER_ID}
      # 运行应用的用户分组ID
      - GROUP_ID=${GROUP_ID}
      # python软件包镜像地址
      - PYPI_MIRROR=${PYPI_MIRROR}
    ports:
      - ${WEB_LISTENING_PORT}:5800
      - ${VNC_LISTENING_PORT}:5900
    restart: unless-stopped
    network_mode: bridge
    stdin_open: true
```

### 1.3 运行容器
```bash
docker-compose up -d
```

> 首次运行时会自动安装依赖，并在app目录 和 容器内的`/config/my_home`目录生成一个名为`.mdcx_initialized`的标记文件。
> 当启动脚本检查到这两个文件同时存在时，就认为已安装过依赖。而当重建容器时，由于新容器里没有标记文件，所以会进行一次安装依赖的处理。
> 如果由于网络等原因没有成功安装依赖，但`.mdcx_initialized`又已生成，删除app目录下的`.mdcx_initialized`文件即可(容器内的标记文件不需要删除)。

### 1.4 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`。
则访问地址为：http://192.168.1.100:5800


### 1.5 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
docker run --name mdcx \
  -p 5800:5800 \
  -p 5900:5900 \
  # 源码目录
  -v /path/to/mdcx-docker/app:/app \
  # 配置目录
  -v /path/to/mdcx-docker/config:/mdcx_config \
  # 日志目录
  -v /path/to/mdcx-docker/logs:/app/Log
  # 影片所在位置
  -v /volume2:/volume2 \
  -e TZ=Asia/Shanghai \
  -e DISPLAY_WIDTH=1200 \
  -e DISPLAY_HEIGHT=750 \
  -e VNC_PASSWORD=123456 \
  # 运行应用的用户ID和分组ID，替换为你实际的ID
  -e USER_ID=0 \
  -e GROUP_ID=0 \
  --restart unless-stopped \
  stainless403/mdcx-base
```


## 2. mdcx示例
[stainless403/mdcx](https://hub.docker.com/r/stainless403/mdcx)镜像已内置MDCx。如果想使用本地MDCx源码版的，请使用[stainless403/mdcx-base](https://hub.docker.com/r/stainless403/mdcx-base)镜像。

🔗 [stainless403/mdcx-base示例](#1-mdcx-base示例)

### 2.1 准备项目目录
建议使用 [示例项目](https://github.com/northsea4/mdcx-docker/archive/refs/heads/main.zip) 结构，解压到合适的位置后，进入项目目录，之后的操作，如无特殊说明，都是在该目录(假设名为`mdcx-docker`)内进行。

整个docker项目的结构大致如下：
```
mdcx-docker
  |-- config
    |-- config.ini
    |-- config-vip.ini
    |-- config-test.ini
  |-- logs
    |-- 2023-02-04-01-15-00.txt
  |-- .env
  |-- .env.sample
  |-- .env.versions
  |-- docker-compose.mdcx-base.sample.yml
  |-- docker-compose.mdcx.sample.yml
  |-- docker-compose.yml
  |-- update-app.sh
```

### 2.2 设置参数
复制一份`docker-compose.mdcx.sample.yml`，手动或使用如下命令：
```bash
cp docker-compose.mdcx.sample.yml docker-compose.yml
```

#### 2.2.1 映射
修改`docker-compose.yml`，在`volumes`下添加映射。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2`，这样在MDCx内访问也是一样的路径。


#### 2.2.2 环境变量

复制一份`.env.sample`，手动或使用如下命令：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
```shell
TZ=Asia/Shanghai

# 应用窗口宽度
DISPLAY_WIDTH=1200
# 应用窗口高度
DISPLAY_HEIGHT=750

# 访问密码，如不需要，留空。如果有在公网远程访问的需求，建议设置
VNC_PASSWORD=

# 网页访问端口
WEB_LISTENING_PORT=5800
# VNC监听端口
VNC_LISTENING_PORT=5900

# 运行应用的用户ID
USER_ID=0
# 运行应用的用户组ID
GROUP_ID=0

# python软件包加速镜像
# 豆瓣
PYPI_MIRROR=https://pypi.doubanio.com/simple
# 清华
# PYPI_MIRROR=https://pypi.tuna.tsinghua.edu.cn/simple
# 默认
# PYPI_MIRROR=https://pypi.org/simple

# 容器名称
CONTAINER_NAME=mdcx
```


#### 2.2.3 完整docker-compose.yml示例
```yml
version: '3'

services:
  mdcx:
    image: stainless403/mdcx:latest
    container_name: ${CONTAINER_NAME}
    volumes:
      # 配置目录
      - ./config:/mdcx_config

      # 日志目录
      - ./logs:/app/Log
      
      # 影片所在位置  
      - /volume2:/volume2
      - /volume3:/volume3
    environment:
      - TZ=${TZ}
      # 应用窗口宽度
      - DISPLAY_WIDTH=${DISPLAY_WIDTH}
      # 应用窗口高度
      - DISPLAY_HEIGHT=${DISPLAY_HEIGHT}
      # 访问密码
      - VNC_PASSWORD=${VNC_PASSWORD}
      # 运行应用的用户ID
      - USER_ID=${USER_ID}
      # 运行应用的用户分组ID
      - GROUP_ID=${GROUP_ID}
      # python软件包镜像地址
      - PYPI_MIRROR=${PYPI_MIRROR}
    ports:
      - ${WEB_LISTENING_PORT}:5800
      - ${VNC_LISTENING_PORT}:5900
    restart: unless-stopped
    network_mode: bridge
    stdin_open: true
```

### 2.3 运行容器
```bash
docker-compose up -d
```

### 2.4 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`。
则访问地址为：http://192.168.1.100:5800

### 2.5 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
docker run --name mdcx \
  --restart unless-stopped \
  -p 5800:5800 \
  -p 5900:5900 \
  # 配置目录
  -v /path/to/mdcx-docker/config:/mdcx_config \
  # 日志目录
  -v /path/to/mdcx-docker/logs:/app/Log \
  # 影片目录
  -v /volume2:/volume2 \
  -e TZ=Asia/Shanghai \
  -e DISPLAY_WIDTH=1200 \
  -e DISPLAY_HEIGHT=750 \
  -e VNC_PASSWORD=123456 \
  # 运行应用的用户ID和分组ID，替换为你实际的ID
  -e USER_ID=0 \
  -e GROUP_ID=0 \
  stainless403/mdcx
```

## 3. 更新
### 3.0 mdcx-base更新应用
如果使用的是没有内置MDCx应用的`stainless403/mdcx-base`镜像，需要先自行下载新版应用并将应用文件解压到`app`目录。
`stainless403/mdcx`则可以省略这一步。

这里提供了一个一键更新脚本 [update-app.sh](https://github.com/northsea4/mdcx-docker/blob/dev/update-app.sh) 自动为你完成更新处理。
请确保`update-app.sh` 文件位于 `/path/to/mdcx-docker`目录下。
```bash
cd /path/to/mdcx-docker

# 确保有执行权限（执行一次即可）
chmod +x ./update-app.sh

# 阅读脚本，或使用`--help`参数查看相关帮助说明
./update-app.sh --help
```

> ⚠️ 同目录下必须要有`.env`和`.env.versions`这个两个文件！`.env`示例文件为`.env.sample`。
> 另外`update-app.sh`脚本也可以完成第1次源码的部署处理。

> 如果你选择手动进行更新，请记得删除app目录下的`.mdcx_initialized`文件！

### 3.1 docker-compose方式更新镜像
```bash
cd /path/to/项目目录
docker-compose pull
docker-compose up -d
```
> 注意，只有使用docker-compose方式部署的才能用该方式更新镜像。
> 另外其实使用docker-compose方式部署的，也可以使用下面说的`watchtower`进行更新。

### 3.2 docker-run方式更新
推荐使用`watchtower`工具更新。

1. 一次性更新
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once \
  mdcx
```

1. 定时任务方式：
> 个人不太建议自动更新，请自行斟酌。

示例：每天的凌晨2点进行更新
```bash
docker run -d --name watchtower-mdcx \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  -c  --schedule "0 0 2 * * *" mdcx
```

`0 0 2 * * *`
6个部分分别为：
`秒 分 时 日 月 星期`

参考：[CRON_Expression_Format](https://pkg.go.dev/github.com/robfig/cron@v1.2.0#hdr-CRON_Expression_Format)

取消定时更新：
```bash
docker rm -f watchtower-mdcx
```

## 3. 镜像说明
### 3.1 已有镜像

- [stainless403/mdcx-base](https://hub.docker.com/r/stainless403/mdcx-base)
  > 没有内置MDCx，需要自行下载MDCx源码并做相关准备。
  > 对应的docker-compose yml示例文件：docker-compose.mdcx-base.sample.yml

- [stainless403/mdcx](https://hub.docker.com/r/stainless403/mdcx)
  > 内置了MDCx，相对方便一些，但不一定能跟上MDCx的更新进度。
  > 对应的docker-compose yml示例文件：docker-compose.mdcx.sample.yml
  
- [stainless403/gui-base](https://hub.docker.com/r/stainless403/gui-base)
  > 支持运行MDCx的基础环境，非开发人员可以忽略。

### 3.2 构建镜像
参考如下文件：
- [build-mdcx-base.sh](https://github.com/northsea4/mdcx-docker/blob/dev/build-mdcx-base.sh)
- [build-mdcx.sh](https://github.com/northsea4/mdcx-docker/blob/dev/build-mdcx.sh)
- [build-gui-base.sh](https://github.com/northsea4/mdcx-docker/blob/dev/build-gui-base.sh)


## TODO
- [x] emoji乱码。比如日志里的 ✅ 这类emoji，都是乱码，暂时没找到解决方法。已解决：安装`fonts-noto-color-emoji`
- [x] 编写脚本自动完成`stainless403/mdcx`镜像的处理流程。
- [x] 编写脚本自动完成本地应用的更新流程
- [x] 内置CJK字体，免去容器初次运行时才去安装
- [ ] 使用Github Actions构建
- [ ] rdesktop