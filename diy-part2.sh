#!/bin/bash
#
# Copyright (c) 2019-2020 P3TERX <https://p3terx.com>
#
# This is free software, licensed under the MIT License.
# See /LICENSE for more information.
#
# https://github.com/P3TERX/Actions-OpenWrt
# File name: diy-part2.sh
# Description: OpenWrt DIY script part 2 (After Update feeds)
#

# Modify default IP
sed -i 's/192.168.1.1/192.168.30.1/g' package/base-files/files/bin/config_generate

# 删除旧的包
rm -rf package/lean/luci-theme-argon

# 调整frp源码
sed -i 's/Vistor/Visitor/g' package/lean/luci-app-frpc/luasrc/model/cbi/frp/config.lua

# 修改默认密码：
echo 'admin:$1$ywT0TFYP$j5PKkLtPx2xtlmsO9wufZ0:0:0:root:/root:/bin/ash' >>package/base-files/files/etc/passwd

# 添加服务证书
cd package/base-files/files/etc
openssl genrsa -out ca.key 2048
openssl req -new -x509 -days 365 -key ca.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=Acme Root CA" -out ca.crt
openssl req -newkey rsa:2048 -nodes -keyout server.key -subj "/C=CN/ST=GD/L=SZ/O=Acme, Inc./CN=localhost" -out server.csr
openssl x509 -sha256 -req -extfile <(printf "subjectAltName=DNS:localhost") -days 365 -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt
cd -

# 修改控制台和SSH界面 
banner new route> package/base-files/files/etc/banner
echo '-----------------------------------------------' >>package/base-files/files/etc/banner
echo '%D %V, %C' >>package/base-files/files/etc/banner
echo '-----------------------------------------------' >>package/base-files/files/etc/banner
echo 'More Help Please Access: https://class.testsanjin.xyz' >>package/base-files/files/etc/banner
cat package/base-files/files/etc/banner

# 配置内核关闭IPV6支持和数据包最大转发能力
# 参考：https://fanqiang.software-download.name/
rm -rf package/base-files/files/etc/sysctl.d/13-ipv6.conf
echo "# made for disabled IPv6 in $(date +%F)">package/base-files/files/etc/sysctl.d/13-ipv6.conf
echo 'net.ipv6.conf.all.disable_ipv6 = 1'>>package/base-files/files/etc/sysctl.d/13-ipv6.conf
echo 'net.ipv6.conf.default.disable_ipv6 = 1'>>package/base-files/files/etc/sysctl.d/13-ipv6.conf
echo 'net.ipv6.conf.lo.disable_ipv6 = 1'>>package/base-files/files/etc/sysctl.d/13-ipv6.conf

rm -rf package/base-files/files/etc/sysctl.d/14-my.conf
echo "# Adjust kernel forwarding in $(date +%F)"> package/base-files/files/etc/sysctl.d/14-my.conf
echo 'net.netfilter.nf_conntrack_max=65536' >> package/base-files/files/etc/sysctl.d/14-my.conf
echo "net.core.netdev_max_backlog=2000" >> package/base-files/files/etc/sysctl.d/14-my.conf
echo "net.core.netdev_budget=3000" >> package/base-files/files/etc/sysctl.d/14-my.conf
echo "net.core.netdev_budget_usecs=20000" >> package/base-files/files/etc/sysctl.d/14-my.conf
echo "vm.swappiness=10" >> package/base-files/files/etc/sysctl.d/14-my.conf
echo "net.ipv4.tcp_fastopen=3" >> package/base-files/files/etc/sysctl.d/14-my.conf

# 下载speedtest和udpping
wget -N https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py -O package/base-files/files/etc/speedtest.py
wget -N https://github.com/wangyu-/UDPping/raw/master/udpping.py -O package/base-files/files/etc/udpping.py

sed -i s'/env python/env python3/g' package/base-files/files/etc/udpping.py
sed -i s'/env python/env python3/g' package/base-files/files/etc/speedtest.py

# add remote help
wget https://raw.githubusercontent.com/lihaixin/openwrt-docker-builder/master/sbin/help -O package/base-files/files/sbin/help

# change docker default configure
sed -i 's/http/https/g' package/lean/luci-app-docker/luasrc/model/cbi/docker.lua
sed -i 's/9999/9000/g' package/lean/luci-app-docker/luasrc/model/cbi/docker.lua
sed -i '$ d' package/lean/luci-app-docker/root/etc/docker-web
cat << EOF >> package/lean/luci-app-docker/root/etc/docker-web
/etc/init.d/dockerd enable
/etc/init.d/dockerd start
sleep 2
docker run -d --net=host \
--name portainer \
--restart=always  \
--label owner=portainer \
-v portainer_data:/data -v /var/run/docker.sock:/var/run/docker.sock \
lihaixin/portainer:ce

EOF
# 修改默认主题
sed -i 's/luci-theme-bootstrap/luci-theme-argon/g' feeds/luci/collections/luci/Makefile

# 修改固件初始化
cd package/lean/default-settings/files/
rm -rf zzz-default-settings
wget https://raw.githubusercontent.com/coolsnowwolf/lede/master/package/lean/default-settings/files/zzz-default-settings -O zzz-default-settings
sed -i '$ d' zzz-default-settings
wget https://raw.githubusercontent.com/lihaixin/openwrt-docker-builder/master/zzz-default-settings.add.xiaomi.ac2100 -O zzz-default-settings.add

cat zzz-default-settings.add >> zzz-default-settings


echo exit 0 >> zzz-default-settings
cd -
