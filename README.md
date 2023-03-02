[![GitHub stars](https://img.shields.io/github/stars/northsea4/mdcx-docker.svg?style=flat&label=Stars&maxAge=2592000)](https://GitHub.com/northsea4/mdcx-docker) [![GitHub release](https://img.shields.io/github/release/northsea4/mdcx-docker.svg?style=flat&label=Release)](https://github.com/northsea4/mdcx-docker/releases/tag/latest)





## 镜像
⚠️ 更改了镜像名称：`gui-base_mdcx-builtin` 更改为 `mdcx-builtin-gui-base`

⚠️ 更改了镜像名称：`webtop-base_mdcx-builtin` 更改为 `mdcx-builtin-webtop-base`

> 短期内旧名称镜像仍会存在，但建议尽快使用新名称镜像。
---


| 镜像 | 部署说明 | 网页查看 | 远程桌面 | 文件管理 | 浏览器 |
| --- | --- | --- | --- | --- | --- |
| [mdcx-builtin-gui-base](https://hub.docker.com/r/stainless403/mdcx-builtin-gui-base/tags) | [查看](https://github.com/northsea4/mdcx-docker/blob/main/gui-base/mdcx-builtin.md) | ✅ | ❌ | ❌ | ❌ |
| [mdcx-builtin-webtop-base](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base/tags) | [查看](https://github.com/northsea4/mdcx-docker/blob/main/webtop-base/mdcx-builtin.md) | ✅ | ✅ | ✅ | ✅ |

### mdcx-builtin-gui-base示例
⚠️ 这里只给出一个简单的运行示例，建议查看 [部署说明](https://github.com/northsea4/mdcx-docker/blob/main/gui-base/mdcx-builtin.md) 了解更多细节。

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

浏览器访问 http://192.168.1.100:5800 使用。

### mdcx-builtin-webtop-base示例
⚠️ 这里只给出一个简单的运行示例，建议查看 [部署说明](https://github.com/northsea4/mdcx-docker/blob/main/webtop-base/mdcx-builtin.md) 了解更多细节。

```bash
MDCX_DOCKER_DIR=/path/to/mdcx-docker
mkdir -p $MDCX_DOCKER_DIR && cd $MDCX_DOCKER_DIR
# 必须：相关数据或日志目录
mkdir -p mdcx-config logs data
# 必须：配置文件目录标记文件
echo "/mdcx-config/config.ini" > mdcx-config/MDCx.config

docker run -d --name mdcx \
  -p 3000:3000 `#Web访问端口` \
  -p 3389:3389 `#RDP访问端口` \
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
  stainless403/mdcx-builtin-webtop-base:latest
```

- 使用`Windows远程桌面`或`Microsoft Remote Desktop`连接 `192.168.1.100:3389` 使用，账号密码`abc/abc`。
- 浏览器访问 http://192.168.1.100:3000 使用。


## 公网访问
如果公网访问的需求，请自行设置好访问密码（<b>不要使用默认密码</b>）。

| 镜像 | 默认 | 方式1 |
| --- | --- | --- |
| [mdcx-builtin-gui-base](https://hub.docker.com/r/stainless403/mdcx-builtin-gui-base/tags) | 空 | 设置环境变量`VNC_PASSWORD` |
| [mdcx-builtin-webtop-base](https://hub.docker.com/r/stainless403/mdcx-builtin-webtop-base/tags) | abc/abc | `docker exec -it 容器名称 passwd abc`<br>或进入桌面使用命令行工具执行`passwd abc` |


## 申明
当你查阅、下载了本项目源代码或二进制程序，即代表你接受了以下条款：

- 本项目和项目成果仅供技术，学术交流和docker测试使用
- 本项目贡献者编写该项目旨在学习docker和python应用在linux平台上的打包处理
- 用户在使用本项目和项目成果前，请用户了解并遵守当地法律法规，如果本项目及项目成果使用过程中存在违反当地法律法规的行为，请勿使用该项目及项目成果
- 法律后果及使用后果由使用者承担
- [GPL LICENSE](https://github.com/northsea4/mdcx-docker/blob/main/LICENSE.md)
- 若用户不同意上述条款任意一条，请勿使用本项目和项目成果


## TODO 
- [x] 镜像独立文档
- [x] 自动编译新版应用并发布
- [x] 自动同步文档到Docker Hub
- [ ] Github Actions缓存的利用