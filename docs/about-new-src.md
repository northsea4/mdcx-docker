## 更改新源码后的更新说明
由于上游源码变更，本项目也做了相应的调整。如果需要使用`20231014`之后的版本，请参考以下说明进行更新。

### 建议的操作
直接部署新容器，然后将旧容器的配置文件等数据复制到新容器目录中。

如果想更新已有的容器，请参考下面的说明。

### builtin镜像
即`mdcx-builtin-gui-base`和`mdcx-builtin-webtop-base`镜像。

简单来说，拉取新版镜像，然后重新部署即可。

> 注意`.env`里的`MDCX_BUILTIN_IMAGE_TAG`应该是`latest`或者最新的版本号。

> 建议先备份配置文件等数据，以免部署失败或未知问题导致数据丢失。

  docker-compose方式，适用于`mdcx-builtin-gui-base`和`mdcx-builtin-webtop-base`
```shell
cd /path/to/mdcx-docker
# 拉取新版镜像
docker-compose pull
# 重新部署
docker-compose up -d
```

docker-cli方式，适用于`mdcx-builtin-gui-base`
```shell
cd /path/to/mdcx-docker
# 拉取新版镜像
docker pull stainless403/mdcx-builtin-gui-base:latest
# 停止并删除容器，容器名称请根据实际情况修改
docker stop mdcx_builtin_gui
docker rm mdcx_builtin_gui
# 重新部署，此处省略具体命令，请根据部署文档执行相关命令
docker run ...
```

docker-cli方式，适用于`mdcx-builtin-webtop-base`
```shell
cd /path/to/mdcx-docker
# 拉取新版镜像
docker pull stainless403/mdcx-builtin-webtop-base:latest
# 停止并删除容器，容器名称请根据实际情况修改
docker stop mdcx_builtin_webtop
docker rm mdcx_builtin_webtop
# 重新部署，此处省略具体命令，请根据部署文档执行相关命令
docker run ...
```

### src镜像
即`mdcx-src-gui-base`和`mdcx-src-webtop-base`镜像。

简单来说，下载新版源码，拉取新版镜像，然后重新部署即可。

> 注意`.env`里的`MDCX_SRC_IMAGE_TAG`应该是`latest`或者最新的版本号。

> 建议先备份配置文件等数据，以免部署失败或未知问题导致数据丢失。

#### 下载新版源码
##### mdcx-src-gui-base
```shell
cd /path/to/mdcx-docker
# 备份旧版源码
mv app app-bak
# 下载新版`下载源码脚本`
mv update-src.sh update-src.sh-bak
curl -fsSL https://github.com/northsea4/mdcx-docker/raw/main/gui-base/update-src.sh -o update-src.sh
# 下载新版源码
bash update-src.sh --verbose
```

##### mdcx-src-webtop-base
```shell
cd /path/to/mdcx-docker
# 备份旧版源码
mv app app-bak
# 下载新版`下载源码脚本`
mv update-src.sh update-src.sh-bak
curl -fsSL https://github.com/northsea4/mdcx-docker/raw/main/webtop-base/update-src.sh -o update-src.sh
# 下载新版源码
bash update-src.sh --verbose
```

#### 重新部署
##### docker-compose方式，适用于`mdcx-src-gui-base`和`mdcx-src-webtop-base`
```shell
cd /path/to/mdcx-docker
# 拉取新版镜像
docker-compose pull
# 重新部署
docker-compose up -d
```

##### docker-cli方式，适用于`mdcx-src-gui-base`
```shell
cd /path/to/mdcx-docker
# 拉取新版镜像
docker pull stainless403/mdcx-src-gui-base:latest
# 停止并删除容器，容器名称请根据实际情况修改
docker stop mdcx_src_gui
docker rm mdcx_src_gui
# 重新部署，此处省略具体命令，请根据部署文档执行相关命令
docker run ...
```

##### docker-cli方式，适用于`mdcx-src-webtop-base`
```shell
cd /path/to/mdcx-docker
# 拉取新版镜像
docker pull stainless403/mdcx-src-webtop-base:latest
# 停止并删除容器，容器名称请根据实际情况修改
docker stop mdcx_src_webtop
docker rm mdcx_src_webtop
# 重新部署，此处省略具体命令，请根据部署文档执行相关命令
docker run ...
```