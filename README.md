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
// TODO
