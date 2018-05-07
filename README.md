# tun2socks 全局透明代理脚本(Processing)
运行此脚本需要的依赖（环境）：
- iproute2 工具
- iptables + ipset 工具
- curl（获取大陆地址段列表）
- 本地 socks5 代理（SS、SSR），需支持 UDP Relay
- ChinaDNS https://github.com/shadowsocks/ChinaDNS
- dnsforwarder https://github.com/holmium/dnsforwarder

附带的 `tun2socks` 可执行文件支持的 CPU 架构有：
- `linux/386`：x86 32位处理器
- `linux/amd64`：x86 64位处理器
- `linux/arm`：arm 32位处理器
- `linux/arm64`：arm 64位处理器
- `linux/mips`：mips 32位处理器
- `linux/mips64`：mips 64位处理器

> 如果你使用的 CPU 架构不在上述列表中，请发 Issues！

## 原理简述
在 Linux 中（尤其是命令行界面）进行 SS/SSR 全局代理远不如 Windows/MacOS/Android/iOS 上方便，因为这些系统中的 SS/SSR 基本都有图形界面，启用它们后，无需用户手动干预，它们会自动的使用平台适应的全局代理模式（比如 Android 上普遍使用的 VPN 模式）。

这里以 shadowsocks-libev 作为说明例子（此脚本不限定 SS/SSR 版本），安装后，可以看到这几个程序：
- `ss-server`：ss 服务端
- `ss-local`：ss 客户端
- `ss-redir`：ss 透明代理工具
- `ss-tunnel`：ss 端口转发工具

后两个先不管，后面会讲到，先看前面两个，ss-server、ss-local。这两个组件应该是所有 shadowsocks/shadowsocksR 分支版本都有的，ss-server 是运行在墙外 VPS 上的，作为服务端，ss-local 是运行在本地的（一般运行在本机）程序，这里只讨论 ss-local。

运行 ss-local（json 配置文件或命令行参数指定），默认情况下，它会监听两个地址，使用 ss 查看：
```bash
$ /bin/ss -lnptu | grep ss-local
udp    UNCONN   0        0                 0.0.0.0:1080          0.0.0.0:*       users:(("ss-local",pid=2060,fd=6))
tcp    LISTEN   0        128               0.0.0.0:1080          0.0.0.0:*       users:(("ss-local",pid=2060,fd=5))
```
分别是：`0.0.0.0:1080/tcp`、`0.0.0.0:1080/udp`。很明显，这是我们要连接的代理地址，看得出，它支持 TCP 和 UDP 代理。那么它们是什么代理协议呢？答案是 socks5。也就是说，我们需要使用 socks5 协议与 ss-local 进行通信，从而完成 FQ。

为了更好的陈述，这里先理清楚 `本机进程` 与 `ss-local` 之间的关系（角色）：
- `ss-local`：角色，socks5 服务器。
- `本机进程`：角色，socks5 客户端。
- `通信协议`：当然是 socks5 协议了。

因此，在 Linux 中，一个程序如果想要通过 ss-local 翻墙，首先它得使用 socks5 协议与 ss-local 交谈。比较可惜的是，大部分程序都没有直接支持 socks5 代理协议。这里使用 curl 工具演示，如何使用 socks5 协议，与 ss-local 交谈，从而翻墙。
```bash
$ curl -4sSkL -x socks5://127.0.0.1:1080 https://www.google.com
<!doctype html><html itemscope="" itemtype="http://schema.org/WebPage" lang="en"><head><meta content="Search the world's information, including webpages, images, videos and more. Google has many special features to help you find exactly what you're looking for." name="description"><meta content="noodp" name="robots"><meta content="text/html; charset=UTF-8" http-equiv="Content-Type"><meta content="/images/branding/googleg/1x/googleg_standard_color_128dp.png" itemprop="image"><title>Google</title><script nonce="+sL44P1JLi/ac6I3cdxWSQ==">(function(){window.google={kEI:'3dPvWu2iOMHM0gSI06GADQ',kEXPI:'0,1353746,58,472,639,846,131,887,440,678,215,103,183,224,80,336,168,203,6,2340647,258,169,32,329244,1344,12383,2349,2506,32692,15247,867,769,7,804,7,543,4562,5471,6381,853,2482,2,2,1624,5177,363,554,332,332,2102,113,1149,1052,2882,309,224,843,1375,57,73,130,5107,444,131,1119,2,579,352,26,285,64,311,886,465,402,367,59,2,4,685,612,394,4,141,638,1113,1149,154,730,1616,155,14,311,38,7,3,149,412,685,8,538,836,195,713,10,51,1232,19,545,454,281,2,840,284,219,910,34,482,21,25,10,428,145,128,57,69,17,132,134,125,14,754,25,155,38,101,41,344,75,9,149,248,127,27,155,35,701,317,339,200,115,6,2,598,180,68,31,54,12,69,245,178,2342031,3686354,1873,672,9,42,1,5997347,2800261,135,4,1572,549,332,445,1,2,1,1,77,1,1,509,391,207,1,1,1,1,1,371,9,304,1,8,1,2,1,1,539,2,1,1,1,2,2,18,22311370',authuser:0,kscs:'c9c918f0_3dPvWu2iOMHM0gSI06GADQ',u:'c9c918f0',kGL:'ZZ'};google.kHL='en';})();goog
......
```
简单的说一下各参数的作用：
- `-4`：使用 ipv4 解析域名（非必须）
- `-s`：静默模式，抑制信息（非必须）
- `-S`：与 -s 结合，显示错误信息（非必须）
- `-k`：取消 https 站点的 ssl 证书校验（非必须）
- `-L`：始终跟随 `Location` 字段，即跟随重定向（非必须）
- `-x`：指定要使用的代理，后面接代理服务器的 url（见下）
- `socks5://127.0.0.1:1080`：使用 socks5 协议，地址是 127.0.0.1:1080
- `https://www.google.com`：要访问的站点，这里是 www.google.com 首页

不出意外的话，该命令会输出 Google 首页的 HTML 源码（如上所示），这意味这你已成功翻墙。
但是，对于那些不支持 socks5 代理的程序该怎么办呢？有很多种方法，这里列出几种常用的方式。

**proxychains-ng**，拦截动态库的同名库函数（libc），实现代理。<br>
利用 `LD_PRELOAD` 环境变量，程序会首先加载该环境变量指定的共享库（不管需不需要），通过此变量加载的库函数比后面加载的同名库函数的优先级更高。proxychains 正是利用了这点，它重写了 libc 库中与 socket 相关的函数，如 connect、close、sendto，然后将它们编译为 `libproxychains4.so` 共享库（该共享库会根据 /etc/proxychains.conf 配置文件使用指定的代理），这样，我们在执行 `proxychains [command]` 时，proxychains 直接调用 `exec [command]`，同时传递两个环境变量（`LD_PRELOAD`、`PROXYCHAINS_CONF_FILE`），前者指定 libproxychains4.so 文件，后者指定 proxychains.conf 配置文件。这样 [command] 就可以无障碍的使用预设的 socks5 代理了。

安装，以 ArchLinux 为例：`pacman -S proxychains-ng`<br>
配置 `/etc/proxychains.conf` 文件，将尾部的 socks4 替换为 `socks5 127.0.0.1 1080`<br>
使用很简单，我们只需要在正常命令前面加上 `proxychains`，如 `proxychains curl https://www.google.com -4sSkL`<br>
如果不想每次都输入 proxychains，可以直接执行：`exec proxychains [shell]`，这样就可以直接使用 socks5 代理了。<br>

*优点*：安装和使用都很简单，兼容性好。<br>
*缺点*：只支持 TCP，不支持 UDP，无法在网关上使用（无法代理内网的数据）。<br>

**privoxy**，作为 socks5 代理的前端，提供 http/https 代理。<br>
配置 privoxy，启用 http/https -> socks5 转发功能，然后运行 privoxy，默认监听 8118/tcp 端口，最后，我们只需要设置两个环境变量就可以了，`http_proxy`、`https_proxy`，它们的值均为 `http://127.0.0.1:8118`。一般的应用程序都会使用这两个环境变量，然后走 privoxy 的 http/https(connect) 代理，privoxy 在内部将它们转换为 socks5 协议，然后与 ss-local 通信。

安装，以 ArchLinux 为例：`pacman -S privoxy`<br>
配置 `/etc/privoxy/config`，添加 `forward-socks5 / 127.0.0.1:1080 .`<br>
运行 privoxy，`systemctl start privoxy.service`<br>
然后设置 proxy 环境变量：`export http_proxy=http://127.0.0.1:8118`、`export https_proxy=http://127.0.0.1:8118`<br>
现在，随便运行一个程序，以 curl 为例，`curl -4sSkL https://www.google.com`，不出意外的话，是可以正常翻墙的。<br>

*优点*：安装和使用都很简单，可以在网关上使用（可以代理内网的 http/https，但需要配置内网主机）。<br>
*缺点*：只能代理 http 和 https，并且有的程序根本不吃 http_proxy、https_proxy 这套，不走它的代理。<br>

**NAT 透明代理**<br>
// TODO

**VPN 透明代理**<br>
// TODO
