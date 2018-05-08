#!/bin/bash

echo -n "this script is only for x86_64. continue? [y/n] "
read input
if [ "$input" = 'n' -o "$input" = 'N' ]; then
    exit 0
fi

cp -af tun2socks/tun2socks.x64 /usr/local/bin/tun2socks
cp -af chinadns/chinadns /usr/local/bin/
cp -af dnsforwarder/dnsforwarder /usr/local/bin/
cp -af ss-tun2socks /usr/local/bin/
chmod 0755 /usr/local/bin/tun2socks
chmod 0755 /usr/local/bin/chinadns
chmod 0755 /usr/local/bin/dnsforwarder
chmod 0755 /usr/local/bin/ss-tun2socks

mkdir -p /etc/tun2socks/
cp -af ss-tun2socks.conf /etc/tun2socks/
cp -af ipset/chnroute.ipset /etc/tun2socks/
cp -af chinadns/chnroute.txt /etc/tun2socks/
cp -af dnsforwarder/dnsforwarder.conf /etc/tun2socks/

cp -af ss-tun2socks.service /etc/systemd/system/
systemctl daemon-reload

echo -n "start ss-tun2socks on boot with systemd? [y/n] "
read input
if [ "$input" = "y" -o "$input" = "Y" ]; then
    systemctl enable ss-tun2socks.service
fi

echo -n "edit /etc/tun2socks/ss-tun2socks.conf? [y/n] "
read input
if [ "$input" = "y" -o "$input" = "Y" ]; then
    vim /etc/tun2socks/ss-tun2socks.conf
    echo -n "start ss-tun2socks service? [y/n] "
    read input
    if [ "$input" = "y" -o "$input" = "Y" ]; then
        /usr/local/bin/ss-tun2socks start
    fi
fi
