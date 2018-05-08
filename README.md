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

## 脚本用法
**获取**
- `git clone https://github.com/zfl9/ss-tun2socks.git`

**安装**
- `cd ss-tun2socks/`
- `cp -af ss-tun2socks /usr/local/bin/`
- `cp -af tun2socks/tun2socks.ARCH /usr/local/bin/tun2socks`（注意 ARCH）
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
