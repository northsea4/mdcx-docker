[![GitHub stars](https://img.shields.io/github/stars/northsea4/mdcx-docker.svg?style=flat&label=Stars&maxAge=3600)](https://GitHub.com/northsea4/mdcx-docker) [![GitHub release](https://img.shields.io/github/release/northsea4/mdcx-docker.svg?style=flat&label=Release)](https://github.com/northsea4/mdcx-docker/releases/tag/latest) [![Docker Pulls](https://img.shields.io/docker/pulls/stainless403/mdcx-builtin-webtop-base.svg?style=flat&label=DockerHub&nbsp;mdcx-builtin-webtop-base)](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base/)

## 0. 关于镜像
[stainless403/mdcx-builtin-webtop-base](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base)，是基于 [linuxserver/webtop](https://hub.docker.com/r/linuxserver/webtop) 构建的适合python+QT5应用运行的镜像。

> 优点是`远程桌面`、`文件管理`和`浏览器`，缺点是资源占用相对高一些，上手难度也稍高。


## 1. mdcx-builtin示例
### 使用脚本部署
复制以下命令到终端运行，第一步选择模版 `2) mdcx-builtin-webtop-base` ，然后根据提示输入几个参数即可完成部署。

使用curl：
```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/northsea4/mdcx-docker/main/install.sh)"
```
使用wget：
```bash
bash -c "$(wget https://raw.githubusercontent.com/northsea4/mdcx-docker/main/install.sh -O -)"
```

---
> 以下的步骤是手动部署的详细说明，即使使用了脚本部署，也请务必阅读一下了解更多细节，如安全、更新等。

[stainless403/mdcx-builtin-webtop-base](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base)镜像已内置编译好的MDCx。如果想使用本地MDCx源码版的，请使用[stainless403/mdcx-src-webtop-base](https://hub.docker.com/r/stainless403/mdcx-src-webtop-base)镜像 ([🔗 查看部署说明](https://github.com/northsea4/mdcx-docker/blob/main/webtop-base/mdcx-src.md))。


### 1.1 准备项目目录
下载 [示例项目](https://github.com/northsea4/mdcx-docker/releases/download/latest/template-mdcx-builtin-webtop-base.zip)，解压到合适的位置后，进入项目目录，如无特别说明，之后的操作都是在该目录(假设名为`mdcx-docker`)内进行。

整个项目的结构大致如下：
```
mdcx-docker
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
  |-- mdcx-src.sample.yml
  |-- mdcx-builtin.sample.yml -------容器部署配置示例
  |-- docker-compose.yml -------容器部署配置
```


### 1.2 设置参数
编辑`.env`文件，按需修改。
文件里每个参数都有具体的说明，`.env.sample`文件里可以查看原始的数值。

一般需要修改的参数：`RDP_LISTEN_PORT`, `WEB_PORT`, `PUID`, `PGID`
| 参数名称 | 说明 | 默认值 | 必填 |
| --- | --- | --- | --- |
| RDP_LISTEN_PORT | RDP远程桌面端口 | 3389 | 是 |
| WEB_PORT | Web访问端口 | 3000 | 是 |
| PUID | 运行应用的用户ID，通过`id -u`命令可以查看当前用户ID，`id -u user1`则可以查看用户user1的用户ID | 0 | 是 |
| PGID | 运行应用的用户组ID，通过`id -g`命令可以查看当前用户组ID，`id -g user1`则可以查看用户user1的用户组ID | 0 | 是 |


### 1.3 完整docker-compose.yml示例
```yml
version: '3'

services:
  mdcx:
    image: stainless403/mdcx-builtin-webtop-base:${MDCX_BUILTIN_IMAGE_TAG}
    container_name: ${MDCX_CONTAINER_NAME}
    env_file:
      - .env
    volumes:
      # 系统数据目录
      - ./data:/config
          
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
      - ${RDP_LISTEN_PORT}:3389
    restart: unless-stopped
    network_mode: bridge
    stdin_open: true
```

### 1.4 运行容器
```bash
docker-compose up -d

# 查看容器日志，容器名称请根据实际情况修改
# docker logs -f mdcx_webtop
# 或者
# docker-compose logs -f
```

### 1.5 使用

> ⚠️ 默认的账号密码是abc/abc。如果需要公网访问，请记得修改密码。

> 修改密码方式1：docker exec -it mdcx_webtop passwd abc

> 修改密码方式2：进入系统后，打开`konsole`，然后执行`passwd abc`

本镜像支持[RDP](https://zh.wikipedia.org/zh-cn/%E9%81%A0%E7%AB%AF%E6%A1%8C%E9%9D%A2%E5%8D%94%E5%AE%9A)，也就是常说的`远程桌面`，默认端口是`3389`。
可以使用支持RDP协议的客户端连接使用。常见的客户端：
- Microsoft Remote Desktop / 微软远程桌面，多平台支持
- Windows自带的「远程桌面」

另外，也支持网页访问。
假设服务器IP为`192.168.1.100`，使用默认端口`3000`。
则访问地址为：http://192.168.1.100:3000。

进入桌面后，点击桌面上的应用图标即可运行。

### 1.6 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
MDCX_DOCKER_DIR=/path/to/mdcx-docker
mkdir -p $MDCX_DOCKER_DIR && cd $MDCX_DOCKER_DIR
# 必须：相关数据或日志目录
mkdir -p mdcx-config logs data
# 必须：配置文件目录标记文件
echo "/mdcx-config/config.ini" > mdcx-config/MDCx.config
# 确保有config.ini文件
touch mdcx-config/config.ini

docker run -d --name mdcx \
  -p 3000:3000 `#Web访问端口` \
  -p 3389:3389 `#RDP访问端口` \
  -v $(pwd)/data:/config `#容器系统数据` \
  -v $(pwd)/mdcx-config:/mdcx-config `#配置文件目录` \
  -v $(pwd)/mdcx-config/MDCx.config:/app/MDCx.config `#配置文件目录标记文件` \
  -v $(pwd)/logs:/app/Log `#日志目录` \
  -v /volume2:/volume2 `#影片目录` \
  -e TZ=Asia/Shanghai \
  -e AUTO_LOGIN=false `#使用默认密码(abc)，且通过网页访问时，是否自动登录(true/false)` \
  -e PUID=$(id -u) `#运行应用的用户ID` \
  -e PGID=$(id -g) `#运行应用的用户组ID` \
  --restart unless-stopped \
  stainless403/mdcx-builtin-webtop-base:latest
```



## 2. 更新

### 2.1 docker-compose方式更新镜像
```bash
cd /path/to/mdcx-docker
docker-compose pull
docker-compose up -d
```
> 注意，只有使用docker-compose方式部署的才能用该方式更新镜像。
> 另外其实使用docker-compose方式部署的，也可以使用下面说的`watchtower`进行更新。

### 2.2 docker-run方式更新
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