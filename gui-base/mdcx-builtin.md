[![GitHub stars](https://img.shields.io/github/stars/northsea4/mdcx-docker.svg?style=flat&label=Stars&maxAge=2592000)](https://GitHub.com/northsea4/mdcx-docker) [![GitHub release](https://img.shields.io/github/release/northsea4/mdcx-docker.svg?style=flat&label=Release)](https://github.com/northsea4/mdcx-docker/releases/tag/latest) [![Docker Pulls](https://img.shields.io/docker/pulls/stainless403/mdcx-builtin-gui-base.svg?style=flat&label=DockerHub&nbsp;mdcx-builtin-gui-base)](https://hub.docker.com/r/stainless403/mdcx-builtin-gui-base/)

## 0. 关于镜像
[stainless403/mdcx-builtin-gui-base](https://hub.docker.com/r/stainless403/mdcx-builtin-gui-base)，是基于 [jlesage/baseimage-gui](https://hub.docker.com/r/jlesage/baseimage-gui) 构建的适合python+QT5应用运行的镜像。

> 优点是`轻量`，缺点是只支持通过网页查看，且没有文件管理。



## 1. mdcx-builtin示例
[stainless403/mdcx-builtin-gui-base](https://hub.docker.com/r/stainless403/mdcx-builtin-gui-base)镜像已内置编译好的MDCx。如果想使用本地MDCx源码版的，请使用[stainless403/mdcx-src-gui-base](https://hub.docker.com/r/stainless403/mdcx-src-gui-base)镜像。


### 1.1 准备项目目录
下载 [示例项目](https://github.com/northsea4/mdcx-docker/releases/download/latest/template-mdcx-builtin-gui-base.zip)，解压到合适的位置后，进入项目目录。如无特别说明，之后的操作都是在该目录(假设名为`mdcx-docker`)内进行。

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
  |-- gui-base-src.sample.yml
  |-- gui-base-builtin.sample.yml -------容器部署配置示例
  |-- docker-compose.yml -------容器部署配置
```


### 1.2 设置参数
编辑`.env`文件，按需修改。
文件里每个参数都有具体的说明，`.env.sample`文件里可以查看原始的数值。

一般需要修改的参数：`VNC_PASSWORD`, `WEB_PORT`, `VNC_PORT`, `USER_ID`, `GROUP_ID`
| 参数名称 | 说明 | 默认值 | 必填 |
| --- | --- | --- | --- |
| VNC_PASSWORD | 访问密码，如不需要，留空。如果有在公网远程访问的需求，建议设置 | 无 | 否 |
| WEB_PORT | 网页访问端口 | 5800 | 是 |
| VNC_PORT | VNC监听端口 | 5900 | 是 |
| USER_ID | 运行应用的用户ID，通过`id -u`命令可以查看当前用户ID，`id -u user1`则可以查看用户user1的用户ID | 0 | 是 |
| GROUP_ID | 运行应用的用户组ID，通过`id -g`命令可以查看当前用户组ID，`id -g user1`则可以查看用户user1的用户组ID | 0 | 是 |
| DISPLAY_WIDTH | 应用窗口宽度 | 1200 | 否 |
| DISPLAY_HEIGHT | 应用窗口高度 | 750 | 否 |


### 1.3 完整docker-compose.yml示例
```yml
version: '3'

services:
  mdcx_builtin_gui:
    image: stainless403/mdcx-builtin-gui-base:${MDCX_BUILTIN_IMAGE_TAG}
    container_name: ${MDCX_BUILTIN_CONTAINER_NAME}
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
      - ${WEB_PORT}:5800
      - ${VNC_PORT}:5900
    restart: unless-stopped
    network_mode: bridge
    stdin_open: true
```

### 1.4 运行容器
```bash
docker-compose up -d

# 查看容器日志
# docker logs -f mdcx_builtin_gui
```

### 1.5 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`，则访问地址为：http://192.168.1.100:5800

### 1.6 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
# 选一个合适的目录
MDCX_DOCKER_DIR=/path/to/mdcx-docker
mkdir -p $MDCX_DOCKER_DIR && cd $MDCX_DOCKER_DIR
# 必须：相关数据或日志目录
mkdir -p mdcx-config logs data
# 必须：配置文件目录标记文件
echo "/mdcx-config/config.ini" > mdcx-config/MDCx.config

docker run -d --name mdcx \
  -p 5800:5800 `#Web访问端口` \
  -p 5900:5900 \
  -v $(pwd)/data:/config `#容器系统数据` \
  -v $(pwd)/mdcx-config:/mdcx-config `#配置文件目录` \
  -v $(pwd)/mdcx-config/MDCx.config:/app/MDCx.config `#配置文件目录标记文件` \
  -v $(pwd)/logs:/app/Log `#日志目录` \
  -v /volume2:/volume2 `#影片目录` \
  -e TZ=Asia/Shanghai \
  -e DISPLAY_WIDTH=1200 \
  -e DISPLAY_HEIGHT=750 \
  -e VNC_PASSWORD=  `#查看密码` \
  -e USER_ID=$(id -u) `#运行应用的用户ID` \
  -e GROUP_ID=$(id -g) `#运行应用的用户组ID` \
  --restart unless-stopped \
  stainless403/mdcx-builtin-gui-base:latest
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