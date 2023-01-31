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
目录结构大致如下：
```
mdcx-docker
  |-- app
    |-- Data
    |-- Function
    |-- Getter
    |-- Img
    |-- LICENSE
    |-- Mac无法打开看这里.txt
    |-- MDCx_Main.py
    |-- requirements.txt
    |-- setup.py
    |-- Ui
    |-- Win闪退看这里.txt
    |-- 使用说明.txt
    `-- 打包方法.txt
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

### 1.3 运行容器
```bash
docker-compose up -d
```

> 首次运行时会自动安装依赖，并在容器内的根目录生成一个名为`.mdcx_initialized`的标记文件。
> 如果由于网络等原因没有成功安装依赖，但`/.mdcx_initialized`又已生成，记得先删除该文件后再重启容器。删除方法：执行`clear-initialized.sh`脚本，或者自己用其他方式删除该文件。

### 1.4 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`。
则访问地址为：http://192.168.1.100:5800


### 1.5 docker run运行示例
```bash
docker run --name mdcx \
  -p 5800:5800 \
  -p 5900:5900 \
  # 源码目录
  -v $(pwd)/app:/app \
  # 你的影片所在位置
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

### 2.2 设置参数
复制一份`docker-compose.mdcx.sample.yml`：
```bash
cp docker-compose.mdcx.sample.yml docker-compose.yml
```

#### 2.2.1 映射
修改`docker-compose.yml`，在`volumes`下添加映射。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2:rslave`，这样在MDCx内访问也是一样的路径。

建议将配置文件映射到主机：
> 请先创建空的配置文件，否则会映射失败。
```yml
  volumes:
    # 默认config
    - ./config/config.ini:/app/config.ini
    # 多个config
    - ./config/config2.ini:/app/config2.ini
    - ./config/config3.ini:/app/config3.ini
```

另外，也可以将日志目录映射到主机：
```bash
mkdir -p ./logs
```

```yml
  volumes:
    - ./logs:/Log
```

#### 2.2.2 环境变量

复制一份`.env.sample`：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
> 如果有在公网远程访问的需求，建议设置一下`VNC_PASSWORD`

### 2.3 运行容器
```bash
docker-compose up -d
```

### 2.4 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`。
则访问地址为：http://192.168.1.100:5800

### 2.5 docker run运行示例
```bash
docker run --name mdcx \
  --restart unless-stopped \
  -p 5800:5800 \
  -p 5900:5900 \
  # 配置文件
  -v $(pwd)/config.ini:/app/config.ini \
  -v $(pwd)/config-other.ini:/app/config-other.ini \
  # 你的影片所在位置
  -v /volume2:/volume2:rslave \
  # 日志（确保有logs目录，不需要就去掉这个映射）
  -v $(pwd)/logs:/app/Log \
  -e TZ=Asia/Shanghai \
  -e DISPLAY_WIDTH=1200 \
  -e DISPLAY_HEIGHT=750 \
  -e VNC_PASSWORD=123456 \
  stainless403/mdcx
```

## 3. 升级
### 3.1 docker-compose方式升级
```bash
cd /path/to/项目目录
docker-compose pull
docker-compose up -d
```

### 3.2 docker-run方式升级
除了删除容器后重新执行`docker run ...`之外，推荐使用`watchtower`工具更新。

1. 一次性更新
```bash
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  --run-once \
  mdcx
```

2. 定时任务方式：
示例：每天的凌晨2点进行更新
```bash
docker run -d --name watchtower \
  --restart unless-stopped \
  -v /var/run/docker.sock:/var/run/docker.sock \
  containrrr/watchtower \
  -c  --schedule "0 0 2 * * *" mdcx
```

`0 0 2 * * *`
6个部分分别为：
秒 分 时 日 月 星期
参考：[CRON_Expression_Format](https://pkg.go.dev/github.com/robfig/cron@v1.2.0#hdr-CRON_Expression_Format)

取消定时更新：
```bash
docker rm -f watchtower
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
- [build-gui-base.sh](build-gui-base.sh)
- [build-mdcx-base.sh](build-mdcx-base.sh)
- [build-mdcx.sh](build-mdcx.sh)
  


## TODO
- [x] ~~emoji乱码。比如日志里的 ✅ 这类emoji，都是乱码，暂时没找到解决方法。~~ 已解决：安装`fonts-noto-color-emoji`
- [ ] 使用Github Actions自动构建和推送镜像。
- [ ] 当有新版应用时，自动构建新版镜像。