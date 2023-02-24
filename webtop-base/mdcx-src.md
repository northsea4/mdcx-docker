[![GitHub stars](https://img.shields.io/github/stars/northsea4/mdcx-docker.svg?style=flat&label=Stars&maxAge=2592000)](https://GitHub.com/northsea4/mdcx-docker) [![GitHub release](https://img.shields.io/github/release/northsea4/mdcx-docker.svg?style=flat&label=Release)](https://github.com/northsea4/mdcx-docker/releases/tag/latest) [![Docker Pulls](https://img.shields.io/docker/pulls/stainless403/mdcx-src-webtop-base.svg?style=flat&label=DockerHub&nbsp;mdcx-src-webtop-base)](https://hub.docker.com/r/stainless403/mdcx-src-webtop-base/)

## 0. 关于镜像
[stainless403/mdcx-src-webtop-base](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base)，是基于 [linuxserver/webtop](https://hub.docker.com/r/linuxserver/webtop) 构建的适合python+QT5应用运行的镜像。

> 优点是`远程桌面`、`文件管理`和`浏览器`，缺点是资源占用相对高一些，上手难度也稍高。



## 1. mdcx-src示例
[stainless403/mdcx-src-webtop-base](https://hub.docker.com/r/stainless403/mdcx-src-webtop-base)镜像没有内置MDCx，如果想使用内置的，请使用[stainless403/mdcx-builtin-webtop-base](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base)镜像。


> Tips: mdcx-src-webtop-base支持运行已编译的应用，但mdcx-builtin-webtop-base默认情况下不能运行应用源码。

下面主要讲述`docker-compose`的部署方式。`docker-run`的方式也有简单的示例。

### 1.1 准备项目目录
下载 [示例项目](https://github.com/northsea4/mdcx-docker/releases/download/latest/template-mdcx-src-webtop-base.zip)，解压到合适的位置后，进入项目目录，如无特别说明，之后的操作都是在该目录(假设名为`mdcx-docker`)内进行。

### 1.2 准备应用源码
   
1. 执行`update-src.sh`即可自动下载源码到`app`目录。
```bash
./update-src.sh
```

整个项目的结构大致如下：
```
mdcx-docker
  |-- app   ------应用源码目录
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
  |-- data ------容器系统数据
    ...
  |-- mdcx-config --------应用配置文件目录
    |-- config.ini
    |-- MDCx.config
  |-- logs --------应用日志目录
    |-- 2023-02-04-01-15-00.txt
  |-- .env ------环境变量文件
  |-- .env.sample ------环境变量示例文件
  |-- .env.versions ------应用版本文件
  |-- mdcx-builtin.sample.yml
  |-- mdcx-src.sample.yml -------容器部署配置示例
  |-- docker-compose.yml -------容器部署配置
  |-- update-app.sh
```

### 1.3 设置参数
编辑`.env`文件，按需修改。
文件里每个参数都有具体的说明，`.env.sample`文件里可以查看原始的数值。

一般需要修改的参数：`RDP_PORT`, `WEB_PORT`, `PUID`, `PGID`
| 参数名称 | 说明 | 默认值 | 必填 |
| --- | --- | --- | --- |
| RDP_PORT | RDP远程桌面端口 | 3389 | 是 |
| WEB_PORT | Web访问端口 | 3000 | 是 |
| PUID | 运行应用的用户ID，通过`id -u`命令可以查看当前用户ID，`id -u user1`则可以查看用户user1的用户ID | 0 | 是 |
| PGID | 运行应用的用户组ID，通过`id -g`命令可以查看当前用户组ID，`id -g user1`则可以查看用户user1的用户组ID | 0 | 是 |

### 1.4 完整docker-compose.yml示例
```yml
version: '3'

services:
  mdcx_src_webtop:
    image: stainless403/mdcx-src-webtop-base:${MDCX_SRC_IMAGE_TAG}
    container_name: ${MDCX_SRC_CONTAINER_NAME}
    env_file:
      - .env
    volumes:
      # 系统数据目录
      - ./data:/config

      # 源码目录
      - ./app:/app

      # 配置文件目录
      - ./mdcx-config:/mdcx-config
      # `配置文件目录`标记文件
      - ./mdcx-config/MDCx.config:/app/MDCx.config

      # 日志目录
      - ./logs:/app/Log

      # 影片目录
      - /path/to/movies:/movies
    ports:
      - ${WEB_PORT}:3000
      - ${RDP_PORT}:3389
    restart: unless-stopped
    network_mode: bridge
    stdin_open: true
```

### 1.5 运行容器
```bash
docker-compose up -d

# 查看容器日志
# docker logs -f mdcx_src_webtop
```

> 首次运行时会自动安装依赖，并在app目录 和 容器内的`/tmp`目录生成一个名为`.mdcx_initialized`的标记文件。
> 当启动脚本检查到这两个文件同时存在时，就认为已安装过依赖。而当重建容器时，由于新容器里没有标记文件，所以会进行一次安装依赖的处理。
> 如果由于网络等原因没有成功安装依赖，但`.mdcx_initialized`又已生成，删除app目录下的`.mdcx_initialized`文件即可(容器内的标记文件不需要删除)。

### 1.6 使用

> ⚠️ 默认的账号密码是abc/abc。如果需要公网访问，请记得修改密码。
> 修改密码方式1：docker exec -it mdcx_src_webtop passwd abc
> 修改密码方式2：进入系统后，打开`konsole`，然后执行`passwd abc`

`webtop-base`重点是支持[RDP](https://zh.wikipedia.org/zh-cn/%E9%81%A0%E7%AB%AF%E6%A1%8C%E9%9D%A2%E5%8D%94%E5%AE%9A)，也就是常说的`远程桌面`。默认端口是`3389`。
可以使用支持RDP协议的客户端连接使用。常见的客户端：
- Microsoft Remote Desktop / 微软远程桌面，多平台支持
- Windows自带的「远程桌面」

另外，也支持网页访问。
假设服务器IP为`192.168.1.100`，使用默认端口`3000`。
则访问地址为：http://192.168.1.100:3000。

进入桌面后，点击桌面上的应用图标即可运行。
> ⚠️ 初次运行需要安装依赖，请耐心等待30秒到两分钟，不要重复点击！
> ⚠️ 初次运行需要安装依赖，请耐心等待30秒到两分钟，不要重复点击！
> ⚠️ 初次运行需要安装依赖，请耐心等待30秒到两分钟，不要重复点击！

### 1.7 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
# 选一个合适的目录
MDCX_DOCKER_DIR=/path/to/mdcx-docker
mkdir -p $MDCX_DOCKER_DIR && cd $MDCX_DOCKER_DIR
# 必须：相关数据或日志目录
mkdir -p app mdcx-config logs data
# 必须：配置文件目录标记文件
echo "/mdcx-config/config.ini" > mdcx-config/MDCx.config

# ！！！下载源码！！！最方便的就是使用`update-src.sh`脚本，自动下载源码文件到`app`目录
./update-src.sh

docker run -d --name mdcx \
  -p 3000:3000 `#Web访问端口` \
  -p 3389:3389 `#RDP访问端口` \
  -v $(pwd)/app:/app `#源码目录，请确保已下载好源码` \
  -v $(pwd)/data:/config `#容器系统数据` \
  -v $(pwd)/mdcx-config:/mdcx-config `#配置文件目录` \
  -v $(pwd)/mdcx-config/MDCx.config:/app/MDCx.config `#配置文件目录标记文件` \
  -v $(pwd)/logs:/app/Log `#日志目录` \
  -v /volume2:/volume2 `#影片目录` \
  -e TZ=Asia/Shanghai \
  -e AUTO_LOGIN=false `#使用默认密码(abc)，且通过网页访问时，是否自动登录` \
  -e PUID=$(id -u) `#运行应用的用户ID` \
  -e PGID=$(id -g) `#运行应用的用户组ID` \
  --restart unless-stopped \
  stainless403/mdcx-src-webtop-base:latest
```



## 2. 更新
### 2.1 mdcx-src更新应用

```bash
cd /path/to/mdcx-docker

./update-src.sh --verbose

# 完成更新源码之后，重启容器
# docker restart mdcx_src_webtop
```

> ⚠️ 如果你选择不使用脚本而是手动进行更新，请记得删除`app`目录下的`.mdcx_initialized`文件。

### 2.2 docker-compose方式更新镜像
```bash
cd /path/to/mdcx-docker
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
  容器名称
```

2. 定时任务方式：
> 个人不太建议自动更新，请自行斟酌。

示例：每天的凌晨2点进行更新
```bash
docker run -d --name watchtower-mdcx \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  -c  --schedule "0 0 2 * * *" 容器名称
```

`0 0 2 * * *`
6个部分分别为：
`秒 分 时 日 月 星期`

参考：[CRON_Expression_Format](https://pkg.go.dev/github.com/robfig/cron@v1.2.0#hdr-CRON_Expression_Format)

取消定时更新：
```bash
docker rm -f watchtower-mdcx
```