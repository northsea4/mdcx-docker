## 1. mdcx-base示例
[stainless403/mdcx-base](https://hub.docker.com/r/stainless403/mdcx-base)镜像没有内置MDCx，如果想使用内置的，请移步到下面的[mdcx示例](#2-mdcx示例)。

下面主要讲述`docker-compose`的部署方式。
`docker-run`的方式也有简单的示例。

### 1.1 准备项目目录
建议使用 [示例项目](https://github.com/northsea4/mdcx-docker/archive/refs/heads/main.zip) 结构，解压到合适的位置后，进入项目目录，之后的操作，如无特殊说明，都是在该目录(假设名为`mdcx-docker`)内进行。

### 1.2 准备应用源码
   
1. 访问 [MDCx发布仓库](https://github.com/anyabc/something/releases/tag/MDCx)，
下载源码版的压缩包(`MDCx-py-`开头)，如`MDCx-py-20230127.rar`。

2. 将`MDCx-py-20230127.rar`里的文件放到`app`目录。
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
  |-- docker-compose.mdcx-base.sample.yml
  |-- docker-compose.mdcx.sample.yml
  |-- docker-compose.yml
```

### 1.2 设置参数
复制一份`docker-compose.mdcx-base.sample.yml`：
```bash
cp docker-compose.mdcx-base.sample.yml docker-compose.yml
```

#### 1.2.1 映射
修改`docker-compose.yml`，在`volumes`下添加映射。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2:rslave`，这样在MDCx内访问也是一样的路径。

#### 1.2.2 环境变量
复制一份`.env.sample`：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
> 如果有在公网远程访问的需求，建议设置一下`VNC_PASSWORD`


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

      # 配置文件
      - ./config:/mdcx_config

      # 日志目录
      - ./logs:/app/Log

      # 影片所在位置
      - /volume2:/volume2:rslave
      - /volume3:/volume3:rslave
    environment:
      - TZ=${TZ}
      # 应用窗口宽度
      - DISPLAY_WIDTH=${DISPLAY_WIDTH}
      # 应用窗口高度
      - DISPLAY_HEIGHT=${DISPLAY_HEIGHT}
      # 访问密码
      - VNC_PASSWORD=${VNC_PASSWORD}
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

> 首次运行时会自动安装依赖，并在app目录 和 容器根目录生成一个名为`.mdcx_initialized`的标记文件。
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
  -v /volume2:/volume2:rslave \
  -e TZ=Asia/Shanghai \
  -e DISPLAY_WIDTH=1200 \
  -e DISPLAY_HEIGHT=750 \
  -e VNC_PASSWORD=123456 \
  --restart unless-stopped \
  stainless403/mdcx-base
```


## 2. mdcx示例
[stainless403/mdcx](https://hub.docker.com/r/stainless403/mdcx)镜像已内置MDCx。

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
  |-- docker-compose.mdcx-base.sample.yml
  |-- docker-compose.mdcx.sample.yml
  |-- docker-compose.yml
```

### 2.2 设置参数
复制一份`docker-compose.mdcx.sample.yml`：
```bash
cp docker-compose.mdcx.sample.yml docker-compose.yml
```

#### 2.2.1 映射
修改`docker-compose.yml`，在`volumes`下添加映射。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2:rslave`，这样在MDCx内访问也是一样的路径。


#### 2.2.2 环境变量

复制一份`.env.sample`：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
> 如果有在公网远程访问的需求，建议设置一下`VNC_PASSWORD`


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
      - /volume2:/volume2:rslave
      - /volume3:/volume3:rslave
    environment:
      - TZ=${TZ}
      # 应用窗口宽度
      - DISPLAY_WIDTH=${DISPLAY_WIDTH}
      # 应用窗口高度
      - DISPLAY_HEIGHT=${DISPLAY_HEIGHT}
      # 访问密码
      - VNC_PASSWORD=${VNC_PASSWORD}
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
  # 配置文件
  -v /path/to/mdcx-docker/config:/mdcx_config \
  # 日志
  -v /path/to/mdcx-docker/logs:/app/Log \
  # 你的影片所在位置
  -v /volume2:/volume2:rslave \
  -e TZ=Asia/Shanghai \
  -e DISPLAY_WIDTH=1200 \
  -e DISPLAY_HEIGHT=750 \
  -e VNC_PASSWORD=123456 \
  stainless403/mdcx
```

## 3. 更新
### 3.0 mdcx-base更新应用
如果使用的是没有内置MDCx应用的`stainless403/mdcx-base`镜像，需要先自行下载新版应用并将应用文件解压到`app`目录。
`stainless403/mdcx`则可以省略这一步。

这里提供了一个一键更新脚本 [update-app.sh](update-app.sh) 自动为你完成更新处理。
请确保`update-app.sh` 文件位于 `/path/to/mdcx-docker`目录下。
```bash
cd /path/to/mdcx-docker

# 确保有执行权限（执行一次即可）
chmod +x ./update-app.sh

# 阅读脚本，或使用`--help`参数查看相关帮助说明
./update-app.sh --help
```

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
- [build-mdcx-base.sh](build-mdcx-base.sh)
- [build-mdcx.sh](build-mdcx.sh)
- [build-gui-base.sh](build-gui-base.sh)
  


## TODO
- [x] ~~emoji乱码。比如日志里的 ✅ 这类emoji，都是乱码，暂时没找到解决方法。~~ 已解决：安装`fonts-noto-color-emoji`
- [x] ~~编写脚本自动完成`stainless403/mdcx`镜像的处理流程。~~
- [x] ~~编写脚本自动完成本地应用的更新流程~~