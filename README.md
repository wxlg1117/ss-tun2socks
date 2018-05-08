# tun2socks 透明代理
## 脚本依赖
- iproute2 工具
- iptables + ipset 工具
- curl 用于获取大陆地址段列表
- haveged 解决系统熵过低的问题（可选，但建议）
- 本地 socks5 代理（SS、SSR），需支持 UDP Relay
- [chinadns](https://github.com/shadowsocks/ChinaDNS)，自带 `x64` 可执行文件
- [dnsforwarder](https://github.com/holmium/dnsforwarder)，自带 `x64` 可执行文件
- [gotun2socks](https://github.com/yinghuocho/gotun2socks)，自带 `x86`、`x64`、`arm`、`arm64`、`mips`、`mips64` 可执行文件

## 相关说明
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
分别是：`0.0.0.0:1080/tcp`、`0.0.0.0:1080/udp`。很明显，这是我们要连接的代理地址，看得出，它支持 TCP 和 UDP 代理。那么它们是什么代理协议呢？答案是 socks5。也就是说，我们需要使用 socks5 协议与 ss-local 进行通信，从而完成 FQ。比较可惜的是，大部分程序都没有直接支持 socks5 代理协议。这里使用 curl 工具演示如何使用 socks5 代理：
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
到目前为止，我们仍未找到一种能够真正全局代理的方法，难道真的没办法了吗？办法是有的，还记得开头说的 `ss-redir`、`ss-tunnel` 吗？它们就是专为 Linux 编写的全局代理工具，这两个工具目前只存在于 libev 版本，我们先来介绍 ss-redir。

ss-redir 需要配合 iptables 的 REDIRECT 功能使用，熟悉 iptables 的读者对 REDIRECT 可能不陌生，很多全局代理的工具都需要使用 REDIRECT（重定向）。REDIRECT 实际上就是 DNAT（目的地址转换），只不过 REDIRECT 中的目的 IP 是本机，于是起了个形象的名字 - 重定向。DNAT 做的工作很简单，它就是修改数据包的目的 IP 和目的 Port，但是，DNAT 在修改之前，会先在内存中保存数据包的原目的 IP 和原目的 Port（称为连接记录项），以供程序查询。

我们先运行 ss-redir（和 ss-local 的运行方式类似），默认监听在 1080/tcp、1080/udp 端口。然后配置 iptables 规则，REDIRECT 需要被代理的数据到 1080 端口（先考虑 TCP），ss-redir 收到 TCP 数据包后，先调用 netfilter 提供的 API 获取该数据包的原目的 IP 和原目的 Port。拿到了原目的 IP 和原目的 Port 后，接下来 ss-redir 和 ss-local 的工作方式就差不多了，与 ss-redir 进行通信，完成代理。

现在 TCP 透明代理是 OK 了，那么 UDP 呢？为啥不直接像 TCP 那样直接 REDIRECT 过去呢？最开始我也是这么想当然的，直接 REDIRECT 到 1080 端口。因为我 DNS 是使用 ss-tunnel 进行解析的，所以也没发现啥不对劲的地方，毕竟我很少使用需要 UDP 翻墙。后来，经读者提醒我才知道，这么做是不对的，这根本无法透明代理 UDP 数据。为什么呢？因为 UDP 在做了 DNAT 后，程序是无法根据 netfilter API 获取原本的目的 IP 和目的 Port 的（有人说是因为 UDP 是无状态的协议，我也不是很懂，现在只需要知道无法像 TCP 那样获取就够了）。

那要怎么搞？利用 Linux 2.6.28 加入的 TPROXY 内核模块。TPROXY 是一种全新的透明代理模式，它与 REDIRECT 有本质的不同，TPROXY 不会修改数据包的目的地址（有人说会修改目的端口，我暂时也无法考究），因为不修改数据包，所以这个问题就不存在了。TPROXY 实现的透明代理有以下特点：
- 不对 IP 报文做改动（不做 DNAT）；
- 应用层可用非本机 IP 与其它主机建立 TCP/UDP 连接；
- Kernel 通过 iptables-tproxy 和策略路由将非本机流量送到 socket 层；
- 仍需要通过其它技术拦截做代理的流量到代理服务器（WCCP 或 PBR 策略路由）。

不过，目前 TPROXY 只能用在 iptables 的 PREROUTING 链中（mangle 表），因此只能透明代理来自内网中的 TCP、UDP 数据包，对本机的 TCP、UDP 数据包不起作用。注意，TPROXY 能够代理 TCP、UDP 流量，但是在 ss-redir 中，代理 TCP 要用 REDIRECT，代理 UDP 要用 TPROXY。理由很简单，如果全都使用 TPROXY，那么本机的数据包就无法代理了。这种混合的透明代理方式很常见，比如 redsocks 中就是采用的这种组合。

那么本机的 UDP 该怎么办呢？没办法了，目前的方法是使用 ss-tunnel，ss-tunnel 是 libev 版自带的端口转发工具，只需将 ss-tunnel 运行在 53/udp 端口，目的地址设为 8.8.8.8:53/udp，然后修改 /etc/resolv.conf 文件，将 dns 指向 127.0.0.1:53/udp（即 ss-tunnel），就可以使用墙外的 8.8.8.8 DNS 进行无污染解析了。

*优点*：能够透明代理本机的 TCP 流量、来自内网的 TCP/UDP 流量（工作在网关）。<br>
*缺点*：不能代理本机的 UDP 流量、ss-redir 在 libev 版本中才有、某些 Linux 不支持 TPROXY，如部分无线路由。<br>
> 也不是必须要 ss-redir/ss-tunnel 的存在，可以使用 Python 版 SS/SSR（或其它版本），然后利用 redsocks 进行全局透明代理，但是它们都有共同的限制，那就是需要 TPROXY 内核模块，并且不能代理本机的 UDP。

**VPN 透明代理**<br>
这可以说是最完美的方式了，也是我最近才探索出的一种全局透明代理方式。主要的灵感来自 Android 版 SS/SSR，在 SS/SSR 的其它选项中，有这么一个不起眼的选项：`NAT 模式 (仅限调试)`，下面的提示信息是：`从 VPN 模式切换为 NAT 模式，需要 ROOT 权限`。

我一直对 Android 中 SS/SSR 如何实现全局透明代理而感到好奇，毕竟我觉得，Android 不是基于 Linux 内核吗（说错了别打我），既然在 Android 上都可以实现透明代理 TCP/UDP 数据包，那么我应该可以将它的实现机制移植到 Linux 系统中，这个想法我在编写 ss-redir 这篇博客时就有了，然而一直没有付出实际行动，没有稍微深入的理解 Android 版 SS/SSR 的工作原理。

在探索 VPN 透明代理之前，我一直都是使用 [ss-tproxy](https://www.zfl9.com/ss-redir.html) 这种代理方式，虽然它比 proxychains、privoxy 代理的多，但是它有一个限制，就是必须使用 libev 版本（也可以不使用 libev 版，使用其它版本，然后加个 redsocks 也是可以的，这里容许我这么说下去），因为需要 ss-redir、ss-tunnel 程序。而 ss 早就被 Qos 影响，常常出现限速、间歇性断流、延迟高等问题。于是我只好转战 ssr，可惜的是，ssr-libev 维护的人太少了，基本就是停止更新了，很多新的协议插件都不支持，比如 `auth_chain_a`、`auth_chain_b`、`auth_chain_c`、`auth_chain_d`、`auth_chain_e`、`auth_chain_f`，最新的特性基本都是先在 Python 版实现的。

这使我不得不寻找一种能够使用 Python 版的 SSR 来进行透明代理的新方法，于是，我又想到了 Android 版的 SS/SSR，我拾起 Google，找了很多 Android 版 SS/SSR 源码分析的文章，渐渐的发现了两个关键字，它们频频出现在这些文章中，那就是 tun 网卡和 tun2socks 工具。

然后我进入 `/data/data/$shadowsocks-for-android/` 目录，也发现了 tun2socks 这个工具，于是开始 Google tun2socks 是个什么东西，有什么用途。接着发现这是 badvpn 项目的一部分，于是阅读 badvpn 的 wiki，按照它提供的编译脚本，我成功在 ArchLinux 上编译了 tun2socks 程序。然后创建 tun0 网卡，分配 ip 地址，启动 ssr-local 本地 socks5 代理，最后，启动 tun2socks，可是等我以为要成功的时候，却发现无法使用，使用 `curl --interface tun0 https://www.google.com` 测试，而 curl 总是提示连接超时。

我不甘心呐，隐约觉得这是 ArchLinux 的不兼容导致的，于是我又在 CentOS 7.4 中编译了 tun2socks，按照相同的步骤，成功了，curl 立即就返回了数据。于是我又开始使用 aarch64-linux-gnu 交叉编译工具链，编译了一个 Android 上的 tun2socks，发现也可以使用，这更让我坚信是 ArchLinux 不兼容导致的。

受到 Arch 的毒害，我路由上的系统也是 Arch，这 tun2socks 不能工作该怎么办，于是我开始发 Issues，寻求 badvpn 大佬的帮助，终于，经过几天的漫长等待，我得到了 badvpn 大佬的回复，它叫我抓个包看看，于是我就将 tcpdump 的抓包数据给大佬分析，从这份数据中，看得出，本机进程与 tun2socks 进程之间总是处于握手状态，而且奇怪的是，本机进程（curl）收到了 SYN+ACK 报文后却不回复 ACK 报文，而是重新开始新的握手，又发送 SYN 报文，这样无限循环下去，直到连接超时。

果然，没多久就得到了大佬的回复，大佬就是大佬，一眼就看出了什么问题，立马就指出了，我应该将 tun0 网卡的 rp_filter 值设为 2。这个内核参数的意思是关闭数据包的源地址检验。设置完成后，果然 curl 就有返回了。心情顿时又激动了起来，又有新的代理模式了。

然而，没高兴多久，我发现，tun2socks 不支持原生的 socks5 udp 代理，它只能通过一种别扭的方式来实现 udp 转发。首先，要在服务器上运行 tun2socks-udpgw 守护进程，然后在本地运行 tun2socks 时指定 udpgw 的监听地址，tun2socks 收到 udp 包后，会将它打包在 tcp 包中，然后通过 socks5 的 tcp 转发给服务器上的 udpgw，最后 udpgw 解包，使用 udp 协议与目的服务器进行通信。这实际上就是 udp over tcp。

因为必须在服务器上运行 udpgw，而绝大多数用户的 SS/SSR 都是购买的帐号，商家是根本不可能给你运行啥 udpgw 的。就算是使用自己的 vps 搭建的，那也太麻烦了，而且延迟肯定更高。于是我开始寻找支持原生 tcp/udp -> socks5 代理的 tun2socks 实现。

没过多久，我在 github 上找到了两个 tun2socks 实现，它们都是使用 go 语言编写的，其中一个项目的 readme 简要的描述了如何安装和使用它，于是我还得自己去安装 golang，谁知道，就这一步，我折腾了一天。是这样的，我开始 Google Go 语言教程，然后很容易的安装了 Go，安装方式和 JDK 是差不多的，下载后解压，然后设置环境变量（当时只设置了 PATH 变量，教程上是这么干的），运行 `go help`，也有帮助输出。一切都没问题。

于是我开始按照 readme，不幸的是，第一步就弹出一堆的错误，提示这个找不到，那个没发现。好吧，我开始谷歌 Go 语言入门书籍，没多久，我就掉入了 Go 语言的坑，发现 Go 语言简直就是 21 世纪的 C 语言啊，比 C/C++ 好多了，编译快，运行快，开发快，而且天生支持并发，天生的跨平台支持。于是放下了一天的时间，开始学习 Go 语言，各种环境变量的作用，go 命令的用法，导包，交叉编译，等等，虽然没学到什么东西，但是总算是搞清楚了 Go 语言的基本结构了。

于是我重新开始安装那个 tun2socks，嗯，一切都 OK，没有错误提示，但是，等我运行的时候，发现这货还有啥配置文件，打开 example 文件一看，吓我一跳，几百行，我瞬间对它兴趣全无，就做个干净的 tun2socks 多好啊。于是，我开始安装第二个 tun2socks（gotun2socks），这个项目就比较干净了，就是个纯粹的 tun2socks 实现，没有任何多余的功能（不知道为啥，我就喜欢这种短小精悍的程序）。

废话有点多啊，见谅见谅。好了回归正题，为了不让读者因编译 gotun2socks 而感到困扰，我提前编译好了几种 CPU 架构下的 tun2socks 可执行程序。你只需要 clone 本项目就可以获取了，如果需要其它架构下的 tun2socks，可以联系我，毕竟使用 go 交叉编译也很方便，不需要像 gcc 那样，各种工具链。当然，你也可以直接 clone [gotun2socks](https://github.com/yinghuocho/gotun2socks)，然后编译（感谢 [@yinghuocho](https://github.com/yinghuocho)，提供了一个好用的 tun2socks）。

*优点*：完美支持 tcp/udp 透明代理，无论来自本机还是来自内网，无需 libev 版、无需 TPROXY 模块。<br>
*缺点*：暂时没发现哈，`ss-tun2socks` 完美的克服了 [ss-tproxy](https://github.com/zfl9/ss-tproxy.git) 的所有缺点，所以强烈推荐使用此模式。

## 脚本用法
**获取**
- `git clone https://github.com/zfl9/ss-tun2socks.git`

**安装**
- `cd ss-tun2socks/`
- `cp -af ss-tun2socks /usr/local/bin/`
- `cp -af tun2socks/tun2socks.ARCH /usr/local/bin/`（注意 ARCH）
- `cp -af chinadns/chinadns /usr/local/bin/`（仅适用于 x64）
- `cp -af dnsforwarder/dnsforwarder /usr/local/bin/`（仅适用于 x64）
- `chmod 0755 /usr/local/bin/ss-tun2socks`
- `chmod 0755 /usr/local/bin/tun2socks`
- `chmod 0755 /usr/local/bin/chinadns`
- `chmod 0755 /usr/local/bin/dnsforwarder`
- `mkdir -p /etc/tun2socks/`
- `cp -af ss-tun2socks.conf /etc/tun2socks/`
- `cp -af ipset/chnroute.ipset /etc/tun2socks/`
- `cp -af chinadns/chnroute.txt /etc/tun2socks/`
- `cp -af dnsforwarder/dnsforwarder.conf /etc/tun2socks/`

> 或者使用 `./install.sh` 安装这些文件，目前只支持 x64 平台（后续会添加其它平台的支持）。

**配置**
- `vim /etc/tun2socks/ss-tun2socks.conf`，修改开头的 `socks5 配置`。
- `socks5_listen="127.0.0.1:1080"`：socks5 监听地址，一般为 1080 端口。
- `socks5_remote="node.proxy.net"`：SS/SSR 服务器的 Hostname/IP，注意修改。
- `socks5_runcmd="nohup ss-local -c /etc/ss-local.json -v < /dev/null &>> /var/log/ss-local.log &"`<br>
启动 SS/SSR 的命令，此命令必须能够后台运行（即：不能占用前台）。<br>
如 `service [service-name] start`、`systemctl start [service-name]` 等。

**自启**（Systemd）
- `cp -af ss-tun2socks.service /etc/systemd/system/`
- `systemctl daemon-reload`
- `systemctl enable ss-tun2socks.service`

**自启**（SysVinit）
- `touch /etc/rc.d/rc.local`
- `chmod +x /etc/rc.d/rc.local`
- `echo "/usr/local/bin/ss-tun2socks start" >> /etc/rc.d/rc.local`

> 配置 ss-tun2socks 开机自启后容易出现一个问题，那就是必须再次运行 `ss-tun2socks restart` 后才能正常代理（这之前查看运行状态，可能看不出任何问题，都是 running 状态），这是因为 ss-tun2socks 启动过早了，且 socks5_remote 为 Hostname，且没有将 socks5_remote 中的 Hostname 加入 /etc/hosts 文件而导致的。因为 ss-tun2socks 启动时，网络还没准备好，此时根本无法解析这个 Hostname。要避免这个问题，可以采取一个非常简单的方法，那就是将 Hostname 加入到 /etc/hosts 中，如 Hostname 为 node.proxy.net，对应的 IP 为 11.22.33.44，则只需执行 `echo "11.22.33.44 node.proxy.net" >> /etc/hosts`。不过得注意个问题，那就是假如这个 IP 变了，别忘了修改 /etc/hosts 文件哦。

**用法**
- `ss-tun2socks help`：查看帮助
- `ss-tun2socks start`：启动代理
- `ss-tun2socks stop`：关闭代理
- `ss-tun2socks restart`：重启代理
- `ss-tun2socks status`：运行状态
- `ss-tun2socks current_ip`：查看当前 IP（一般为本地 IP）
- `ss-tun2socks flush_dnsche`：清空 dns 缓存（dnsforwarder）
- `ss-tun2socks update_chnip`：更新大陆地址段列表（ipset、chinadns）

## 相关参考
- [ambrop72/badvpn](https://github.com/ambrop72/badvpn)
- [yinghuocho/gotun2socks](https://github.com/yinghuocho/gotun2socks)
- [shadowsocks/ChinaDNS](https://github.com/shadowsocks/ChinaDNS)
- [holmium/dnsforwarder](https://github.com/holmium/dnsforwarder)
- 感谢以上开发者的无私贡献，让我们能够畅游互联网！
