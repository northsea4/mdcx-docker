## This README is in progress.

## 镜像说明
| 镜像 | 描述 | Web | RDP | 文件管理 | 浏览器 |
| --- | --- | --- | --- | --- | --- |
| stainless403/gui-base | 内容2 | ✅ | ❌ | ❌ | ❌ |
| stainless403/webtop-base | 内容7 | ✅ | ✅ | ✅ | ✅ |

## 配置文件目录
为了避免不必要的麻烦，我将MDCx的`配置文件目录`默认设置为`/mdcx-config`。

基础镜像默认使用`/config`目录保存一些数据文件，虽然有可能可以设置其他目录，但这里我不做这方面的研究。

如果你需要设置`/mdcx-config`之外的目录，请了解上面的描述，并尽量避免使用`/config`。

## 添加中文语言
https://askubuntu.com/questions/1232927/there-are-no-additional-languages-available-on-this-system

## 不能设置时区
https://github.com/EXALAB/AnLinux-App/issues/325

file:///usr/share/plasma/plasmoids/org.kde.plasma.keyboardlayout/contents/ui/main.qml:7:1: module "Qt.labs.platform" is not installed

System has not been booted with systemd as init system (PID 1). Can't operate.
Failed to connect to bus: Host is down
Failed to talk to init daemon.


TODO Image build-mdcx CI 卡在很久：
#51 5.196 3981 INFO: checking Analysis
#51 5.299 4084 INFO: Appending 'datas' from .spec
#51 5.327 4112 INFO: checking PYZ
#51 5.381 4166 WARNING: Ignoring icon; supported only on Windows and macOS!
#51 5.385 4170 INFO: checking PKG
#51 5.413 4198 INFO: Building because toc changed
#51 5.416 4199 INFO: Building PKG (CArchive) MDCx.pkg