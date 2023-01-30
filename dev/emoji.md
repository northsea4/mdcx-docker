直接在没有安装`fonts-noto-color-emoji`的容器内操作，会报错。
```
root@296fbe486bd2:/tmp# apt-get install fonts-noto-color-emoji --no-install-recommends
Reading package lists... Done
Building dependency tree       
Reading state information... Done
The following NEW packages will be installed:
  fonts-noto-color-emoji
0 upgraded, 1 newly installed, 0 to remove and 4 not upgraded.
Need to get 7102 kB of archives.
After this operation, 7762 kB of additional disk space will be used.
Get:1 http://mirrors.ustc.edu.cn/ubuntu bionic-updates/main amd64 fonts-noto-color-emoji all 0~20180810-0ubuntu1 [7102 kB]
Fetched 7102 kB in 0s (18.7 MB/s)               
debconf: delaying package configuration, since apt-utils is not installed
dpkg: unrecoverable fatal error, aborting:
 unknown group 'crontab' in statoverride file
W: No sandbox user '_apt' on the system, can not drop privileges
E: Sub-process /usr/bin/dpkg returned an error code (2)
```

/var/lib/dpkg/statoverride
```
root crontab 2755 /usr/bin/crontab
root messagebus 4754 /usr/lib/dbus-1.0/dbus-daemon-launch-helper
```

```
sed -i '/crontab/d' /var/lib/dpkg/statoverride
sed -i '/messagebus/d' /var/lib/dpkg/statoverride
```

但在构建镜像时安装`fonts-noto-color-emoji`，没有问题。