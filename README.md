## 镜像说明
### 1. 已有镜像
- [stainless403/gui-base](https://hub.docker.com/r/stainless403/gui-base)
  > 支持运行MDCx的基础环境，非开发人员可以忽略。

- [stainless403/mdcx-base](https://hub.docker.com/r/stainless403/mdcx-base)
  > 没有内置MDCx，需要自行下载MDCx源码并做相关准备。但建议使用，方便升级。
  > 对应的docker-compose yml示例文件：docker-compose.mdcx-base.sample.yml

- [stainless403/mdcx](https://hub.docker.com/r/stainless403/mdcx)
  > 内置了MDCx，相对方便一些，但不一定能跟上MDCx的更新进度。
  > 对应的docker-compose yml示例文件：docker-compose.mdcx.sample.yml
  
### 2. 自己构建
参考如下文件：
- [build-gui-base.sh](build-gui-base.sh)
- [build-mdcx-base.sh](build-mdcx-base.sh)
- [build-mdcx.sh](build-mdcx.sh)
  
## mdcx-base示例
mdcx-base镜像没有内置MDCx，如果想使用内置的，请移步到下面的[mdcx示例](#mdcx示例)。

### 1. 准备应用源码
1. 访问 https://github.com/anyabc/something/releases/tag/MDCx ，
下载源码版的压缩包(`MDCx-py-`开头)，如`MDCx-py-20230127.rar`。

2. 将`MDCx-py-20230127.rar`里的文件放到`app`目录。
目录结构大致如下：
   ```
   app
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

### 2. 设置参数
复制一份`docker-compose.mdcx-base.sample.yml`：
```bash
cp docker-compose.mdcx-base.sample.yml docker-compose.yml
```

修改`docker-compose.yml`，在`volumes`下添加映射。不需要的示例映射删除即可。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2:rslave`，这样在MDCx内访问也是一样的路径。


复制一份`.env.sample`：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
> 如果有在公网远程访问的需求，建议设置一下`VNC_PASSWORD`

### 3. 运行容器
```bash
docker-compose up -d
```

> 首次运行时会自动安装依赖，并在容器内的`/home`目录生成一个名为`.mdcx_initialized`的标记文件。
> 如果由于网络等原因没有成功安装依赖，但`/home/.mdcx_initialized`又已生成，记得先删除该文件后再重启容器。删除方法：执行`clear-initialized.sh`脚本，或者自己用其他方式删除该文件。

### 4. 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`。
则访问地址为：http://192.168.1.100:5800

## mdcx示例
mdcx镜像已内置MDCx。
### 1. 设置参数
复制一份`docker-compose.mdcx.sample.yml`：
```bash
cp docker-compose.mdcx.sample.yml docker-compose.yml
```

修改`docker-compose.yml`，在`volumes`下添加映射。不需要的示例映射删除即可。
> 比如影片存放在`/volume2`，可以简单地添加这样的映射：`/volume2:/volume2:rslave`，这样在MDCx内访问也是一样的路径。


复制一份`.env.sample`：
```bash
cp .env.sample .env
```

修改`.env`，按需求修改相关参数
> 如果有在公网远程访问的需求，建议设置一下`VNC_PASSWORD`

### 3. 运行容器
```bash
docker-compose up -d
```

### 4. 使用
假设服务器IP为`192.168.1.100`，使用默认端口`5800`。
则访问地址为：http://192.168.1.100:5800



## TODO
- [x] ~~emoji乱码。比如日志里的 ✅ 这类emoji，都是乱码，暂时没找到解决方法。~~ 已解决：安装`fonts-noto-color-emoji`