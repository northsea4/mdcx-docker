## This README is in progress.

[Legacy README](https://github.com/northsea4/mdcx-docker/blob/main/README-legacy.md)

## 镜像
| 镜像 | Web | RDP | 文件管理 | 浏览器 |
| --- | --- | --- | --- | --- |
| stainless403/gui-base_xxx | ✅ | ❌ | ❌ | ❌ |
| stainless403/webtop-base_xxx | ✅ | ✅ | ✅ | ✅ |

## 关于公网访问
如果公网访问的需求，请自行设置好访问密码。

| 镜像 | 默认 | 方式1 |
| --- | --- | --- |
| [stainless403/gui-base_mdcx-builtin](https://hub.docker.com/r/stainless403/gui-base_mdcx-builtin/tags) | 空 | 设置环境变量`VNC_PASSWORD` |
| [stainless403/webtop-base_mdcx-builtin](https://hub.docker.com/r/stainless403/webtop-base_mdcx-builtin/tags) | abc/abc | `docker exec -it 容器名称 passwd abc`<br>或进入桌面使用命令行工具执行`passwd abc` |

## 申明
当你查阅、下载了本项目源代码或二进制程序，即代表你接受了以下条款：

- 本项目和项目成果仅供技术，学术交流和docker测试使用
- 本项目贡献者编写该项目旨在学习docker和python应用在linux平台上的打包处理
- 用户在使用本项目和项目成果前，请用户了解并遵守当地法律法规，如果本项目及项目成果使用过程中存在违反当地法律法规的行为，请勿使用该项目及项目成果
- 法律后果及使用后果由使用者承担
- [GPL LICENSE](https://github.com/northsea4/mdcx-docker/blob/main/LICENSE.md)
- 若用户不同意上述条款任意一条，请勿使用本项目和项目成果


## TODO 
- [ ] 新版README
- [ ] 部署桌面快捷方式的正确姿势
- [ ] 自动编译新版应用并发布