## 更新日志

### [v0.6.13] - 2021-05-25
- 1.修复: `ImportError: libQt5Core.so.5: cannot open shared object file: No such file or directory`错误，#18

### [v0.6.12] - 2021-05-22
- 1.优化: 部署脚本(`install.sh`)发生错误时的处理逻辑。

### [v0.6.10] - 2023-04-04
- 1.修复: `mdcx-src-webtop-base`镜像`run-src.sh`没有正确读取容器环境变量的问题
- 2.优化: `mdcx-src-gui-base`镜像`run-src.sh`在启动失败时会清理`已初始化`标记文件

### [v0.6.8] - 2021-04-04
- ~~1.修复: `mdcx-src-webtop-base`镜像`run-src.sh`没有正确读取容器环境变量的问题~~
- 2.优化: `mdcx-src-webtop-base`镜像`run-src.sh`在启动失败时会清理`已初始化`标记文件