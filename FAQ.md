## 为什么整这么多镜像？
因为不是小孩子了。


## 怎么关闭webtop镜像的自动锁屏？
进入桌面后，打开Konsole，执行以下命令，然后重启容器。
> ⚠️ 配置文件位于容器数据目录下，所以即使更新镜像也不会丢失配置。

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
> ⚠️ 配置文件位于容器数据目录下，所以即使更新镜像也不会丢失配置。

参考资料: [kscreenlockersettings.kcfg](https://github.com/KDE/kscreenlocker/blob/master/settings/kscreenlockersettings.kcfg)

```bash
# 确保自动锁屏开启
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Autolock true
# 单位是分钟，比如设置为60，就是60分钟
kwriteconfig5 --file $HOME/.config/kscreenlockerrc --group Daemon --key Timeout 60
```


## 怎么修改UMASK?
默认的`umask`是`022`，如果需要修改, 请通过环境变量`UMASK`来修改。


## 怎么输入中文？
> 这里主要说的是`webtop`镜像。

精力和时间有限，暂时未能使中文输入法正常工作，尝试过百度输入法、搜狗输入法等，无果。
如果有人能成功安装和配置并正常使用，欢迎分享经验。

暂时可以通过复制粘贴的方式输入中文。比如，先在控制主机上输入中文并复制，然后在容器桌面环境中粘贴。

实际上这些镜像都是专用的（也就是只用来运行MDCx），个人觉得并没有太多需要输入中文的场景，所以暂时不打算花太多时间去解决这个问题。