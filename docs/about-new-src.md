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

### 历史说明
本文中的“新源码”指的是用于构建builtin镜像的上游应用源码，不是“源码版运行镜像”。

当前仓库已不再维护`mdcx-src-*`这类源码版运行镜像，若你只使用builtin镜像，可忽略历史的源码版流程。