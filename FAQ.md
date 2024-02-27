## 为什么整这么多镜像？
因为不是小孩子了。


## 怎么关闭webtop镜像的自动锁屏？
进入桌面后，打开Konsole，执行以下命令，然后重启容器。
> ⚠️ 配置文件等数据实际是存放在宿主的目录，所以即使更新镜像也不会丢失配置。

参考资料: [kscreenlockersettings.kcfg](https://github.com/KDE/kscreenlocker/blob/master/settings/kscreenlockersettings.kcfg), [kwin.kcfg](https://github.com/KDE/kwin/blob/master/src/kwin.kcfg)

```bash
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Autolock false

# 这个测试过不设置也可以，但加上也不会有什么问题
kwriteconfig5 --file $HOME/.config/kwinrc --group Compositing --key Enabled false
```

恢复自动锁屏。执行以下命令，然后重启容器。
```bash
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Autolock true

# 如果之前修改了`kwinrc`，这里也要恢复
kwriteconfig5 --file $HOME/.config/kwinrc --group Compositing --key Enabled true
```


## 怎么设置webtop镜像的自动锁屏时间？
进入桌面后，打开Konsole，执行以下命令，然后重启容器。
> ⚠️ 配置文件等数据实际是存放在宿主的目录，所以即使更新镜像也不会丢失配置。

参考资料: [kscreenlockersettings.kcfg](https://github.com/KDE/kscreenlocker/blob/master/settings/kscreenlockersettings.kcfg)

```bash
# 确保自动锁屏开启
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Autolock true
# 单位是分钟，比如设置为60，就是60分钟
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Timeout 60
```


## 怎么修改UMASK?
默认的`umask`是`022`，可以通过修改容器环境变量`UMASK`进行设置。


## 怎么输入中文？
> 这里主要说的是`webtop`镜像。

精力和时间有限，暂时未能使中文输入法正常工作，尝试过百度输入法、搜狗输入法等，无果。
如果有人能成功安装和配置并正常使用，欢迎分享经验。

暂时可以通过复制粘贴的方式输入中文。比如，先在控制主机上输入中文并复制，然后在容器桌面环境中粘贴。

实际上这些镜像都是专用的（也就是只用来运行MDCx），个人觉得并没有太多需要输入中文的场景，暂时不会去解决这个问题。


## 选择目录对话框卡顿
如果你有跟 [这个issue](https://github.com/northsea4/mdcx-docker/issues/16) 相似的情况，即点击诸如「选择目录」进行选择时会卡顿，可以尝试以下方法。
进入「设置 - 高级」，找到「选择对话框」，然后勾选「使用 QT 选择对话框」，接着「保存」即可。
![image](https://user-images.githubusercontent.com/94440029/230776296-3cba7601-bc14-4e78-a5aa-83913869893b.png)


## 重新部署容器后，黑屏，无法正常进入桌面
如果你有跟 [这个issue](https://github.com/northsea4/mdcx-docker/issues/17) 相似的情况，即重新部署容器后，无法正常进入桌面，只看到如下图所示的界面(`To run a command as administrator (user "root"), use "sudo <command>".`)。

![image](https://user-images.githubusercontent.com/73220226/232524022-167d8333-62b9-422d-bf90-e0bc07463c73.png)

可以尝试以下解决方法：
```bash
# 进入部署目录
cd /path/to/mdcx-docker
# 停止容器
docker-compose stop
# 备份数据目录
mv data data-backup
# 创建新的数据目录
mkdir data
# 启动容器
docker-compose up -d
```

> 容器数据目录存放的一般是用户数据，比如桌面环境的配置文件、一些运行时生成的文件等。比如需要找回之前在桌面放置的一些文件，可以在`data-backup`目录下的`Desktop`目录中找到。


## 运行失败，提示libQt5Core.so.5不存在
如果你有跟 [这个issue](https://github.com/northsea4/mdcx-docker/issues/18) 相似的情况，即启动失败或不能进入桌面，查看容器日志有`ImportError: libQt5Core.so.5: cannot open shared object file: No such file or directory`，可以尝试以下处理。

1. 首先你需要使用`mdcx-src-gui-base`或者`mdcx-src-webtop-base`镜像，即源码版；
2. 修改`.env`文件里的`STRIP_LIBQT5CORE`为`true`。如果在`.env`文件里没有找到这个变量，可以自行添加。[变量说明](https://github.com/northsea4/mdcx-docker/blob/main/gui-base/.env.sample#L58)。
3. 重新部署容器(`docker-compose up -d`)。


## 通过nginx反代访问时，一分钟断线
如果你通过nginx反代访问`mdcx-builtin/src-gui-base`容器时，发现一分钟左右就断线了，可以尝试以下方法。
https://github.com/novnc/noVNC/issues/658 ，更详细的说明请参考[这里](https://github.com/novnc/noVNC/wiki/Proxying-with-nginx)。