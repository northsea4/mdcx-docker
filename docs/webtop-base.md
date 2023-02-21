## 0. 关于镜像
`webto-base`，即基于 [linuxserver/webtop](https://hub.docker.com/r/linuxserver/webtop) 构建的适合python+QT5应用运行的容器。

## 1. mdcx-src示例
[stainless403/webtop-base_mdcx-src](https://hub.docker.com/r/stainless403/webtop-basemdcx-src)镜像没有内置MDCx，如果想使用内置的，请使用[stainless403/webtop-base_mdcx-builtin](https://hub.docker.com/r/stainless403/webtop-base_mdcx-builtin)镜像。

🔗 [stainless403/webtop-base_mdcx-builtin示例](#2-mdcx-builtin示例)

> Tips: webtop-base_mdcx-src支持运行已编译的应用，但webtop-base_mdcx-builtin默认情况下不能运行应用源码。

下面主要讲述`docker-compose`的部署方式。`docker-run`的方式也有简单的示例。

### 1.1 准备项目目录
下载 [示例项目](https://github.com/northsea4/mdcx-docker/releases/download/latest/template-webtop-base-src.zip)，解压到合适的位置后，进入项目目录，之后的操作，如无特殊说明，都是在该目录(假设名为`mdcx-docker`)内进行。

### 1.2 准备应用源码
   
1. 执行`update-src.sh`即可自动下载并解压应用源码到项目目录下的`app`目录。
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
  |-- docker-compose.built.sample.yml
  |-- docker-compose.src.sample.yml -------容器部署配置示例
  |-- docker-compose.yml -------容器部署配置
  |-- update-app.sh
```

### 1.2 设置参数
编辑`.env`文件，按需修改。
文件里每个参数都有具体的说明，`.env.sample`文件里可以查看原始的数值。


#### 1.2.3 完整docker-compose.yml示例
```yml
version: '3'

services:
  webtop_base_src:
    image: stainless403/webtop-base_mdcx-src:${MDCX_SRC_IMAGE_TAG}
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

### 1.3 运行容器
```bash
docker-compose up -d

# 查看容器日志
# docker logs -f webtop_base_src
```

> 首次运行时会自动安装依赖，并在app目录 和 容器内的`/tmp`目录生成一个名为`.mdcx_initialized`的标记文件。
> 当启动脚本检查到这两个文件同时存在时，就认为已安装过依赖。而当重建容器时，由于新容器里没有标记文件，所以会进行一次安装依赖的处理。
> 如果由于网络等原因没有成功安装依赖，但`.mdcx_initialized`又已生成，删除app目录下的`.mdcx_initialized`文件即可(容器内的标记文件不需要删除)。

### 1.4 使用

> ⚠️ 默认的账号密码是abc/abc。如果需要公网访问，请记得修改密码。
> 修改密码方式1：docker exec -it webtop_base_src passwd abc
> 修改密码方式2：进入系统后，打开`konsole`，然后执行`passwd abc`

`webtop-base`重点是支持[RDP](https://zh.wikipedia.org/zh-cn/%E9%81%A0%E7%AB%AF%E6%A1%8C%E9%9D%A2%E5%8D%94%E5%AE%9A)，也就是平常常说的`远程桌面`。默认端口是`3389`。
可以使用所有支持RDP协议的客户端连接到容器进行使用。常见的客户端：
- Microsoft Remote Desktop / 微软远程桌面，多平台支持
- Windows自带的「远程桌面」

另外，也可以使用网页进行访问。
假设服务器IP为`192.168.1.100`，使用默认端口`3000`。
则访问地址为：http://192.168.1.100:3000。


### 1.5 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
mkdir -p /path/to/mdcx-docker
cd /path/to/mdcx-docker
# 如果没有使用示例项目，请自行创建需要的目录
# mkdir app mdcx-config logs data

docker run --name mdcx \
  # 网页访问端口
  -p 3000:3000 \
  # 远程桌面端口
  -p 3389:3389 \
  # 容器系统数据
  -v /path/to/mdcx-data/data:/config \
  # 源码目录
  -v /path/to/mdcx-docker/app:/app \
  # 配置文件目录
  -v /path/to/mdcx-docker/mdcx-config:/mdcx-config \
  # `配置文件目录`标记文件
  -v /path/to/mdcx-docker/mdcx-config/MDCx.config:/app/MDCx.config \
  # 日志目录
  -v /path/to/mdcx-docker/logs:/app/Log
  # 影片目录
  -v /volume2:/volume2 \
  -e TZ=Asia/Shanghai \
  # 运行应用的用户ID和分组ID，替换为你实际需要的ID
  -e PUID=0 \
  -e PGID=0 \
  --restart unless-stopped \
  stainless403/webtop-base_mdcx-src
```


## 2. mdcx-builtin示例
[stainless403/webtop-base_mdcx-builtin](https://hub.docker.com/r/stainless403/webtop-base_mdcx-builtin)镜像已内置MDCx。如果想使用本地MDCx源码版的，请使用[stainless403/webtop-base_mdcx-src](https://hub.docker.com/r/stainless403/webtop-base_mdcx-src)镜像。

🔗 [stainless403/webtop-base_mdcx-src示例](#1-mdcx-src示例)

### 2.1 准备项目目录
下载 [示例项目](https://github.com/northsea4/mdcx-docker/releases/download/latest/template-webtop-base-builtin.zip)，解压到合适的位置后，进入项目目录，之后的操作，如无特殊说明，都是在该目录(假设名为`mdcx-docker`)内进行。

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
  |-- docker-compose.src.sample.yml
  |-- docker-compose.built.sample.yml -------容器部署配置示例
  |-- docker-compose.yml -------容器部署配置
```


### 2.2 设置参数
编辑`.env`文件，按需修改。
文件里每个参数都有具体的说明，`.env.sample`文件里可以查看原始的数值。


#### 2.3 完整docker-compose.yml示例
```yml
version: '3'

services:
  webtop_base_builtin:
    image: stainless403/webtop-base_mdcx-builtin:${MDCX_BUILTIN_IMAGE_TAG}
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
      - ${WEB_PORT}:3000
      - ${RDP_PORT}:3389
    restart: unless-stopped
    network_mode: bridge
    stdin_open: true
```

### 2.3 运行容器
```bash
docker-compose up -d

# 查看容器日志
# docker logs -f webtop_base_builtin
```

### 2.4 使用

> ⚠️ 默认的账号密码是abc/abc。如果需要公网访问，请记得修改密码。
> 修改密码方式1：docker exec -it webtop_base_builtin passwd abc
> 修改密码方式2：进入系统后，打开`konsole`，然后执行`passwd abc`

`webtop-base`重点是支持[RDP](https://zh.wikipedia.org/zh-cn/%E9%81%A0%E7%AB%AF%E6%A1%8C%E9%9D%A2%E5%8D%94%E5%AE%9A)，也就是平常常说的`远程桌面`。默认端口是`3389`。
可以使用所有支持RDP协议的客户端连接到容器进行使用。常见的客户端：
- Microsoft Remote Desktop / 微软远程桌面，多平台支持
- Windows自带的「远程桌面」

另外，也可以使用网页进行访问。
假设服务器IP为`192.168.1.100`，使用默认端口`3000`。
则访问地址为：http://192.168.1.100:3000。

### 2.5 docker run运行示例
`/path/to/` 替换为你实际的路径。

```bash
mkdir -p /path/to/mdcx-docker
cd /path/to/mdcx-docker
# 如果没有使用示例项目结构，请自行创建需要的目录
# mkdir mdcx-docker logs data

docker run --name mdcx \
  --restart unless-stopped \
  # 网页访问端口
  -p 3000:3000 \
  # 远程桌面端口
  -p 3389:3389 \
  # 容器系统数据
  -v /path/to/mdcx-data/data:/config \
  # 源码目录
  -v /path/to/mdcx-docker/app:/app \
  # 配置文件目录
  -v /path/to/mdcx-docker/mdcx-config:/mdcx-config \
  # 日志目录
  -v /path/to/mdcx-docker/logs:/app/Log
  # 影片目录
  -v /volume2:/volume2 \
  -e TZ=Asia/Shanghai \
  # 运行应用的用户ID和分组ID，替换为你实际需要的ID
  -e PUID=0 \
  -e PGID=0 \
  stainless403/webtop-base_mdcx-builtin
```

## 3. 更新
### 3.0 mdcx-src更新应用

这里提供了一个一键更新脚本 [update-app.sh](https://github.com/northsea4/mdcx-docker/blob/dev/update-app.sh) 自动为你完成更新处理。
请确保`update-app.sh` 文件位于 `/path/to/mdcx-docker`目录下。
```bash
cd /path/to/mdcx-docker

# 确保有执行权限（执行一次即可）
chmod +x ./update-app.sh

# 阅读脚本，或使用`--help`参数查看相关帮助说明
# ./update-app.sh --help

./update-app.sh --verbose

# 完成更新源码之后，重启容器
# docker restart 容器名称
```

> 如果你选择不使用脚本而是手动进行更新，请记得删除app目录下的`.mdcx_initialized`文件！

### 3.1 docker-compose方式更新镜像
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

1. 定时任务方式：
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