#!/usr/bin/env ash
#=================================================
# File name: ipv6-helper
# Description: Install IPV6 Modules On OpenWrt
# System Required: OpenWrt
# Version: 1.0
# Lisence: MIT
# Author: SuLingGG
# Blog: https://mlapp.cn
#=================================================

Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
INFO="[${Green_font_prefix}INFO${Font_color_suffix}]"
ERROR="[${Red_font_prefix}ERROR${Font_color_suffix}]"

Welcome(){
    echo -e "${Green_font_prefix}\nAlat ini dapat membantu Anda menginstal modul IPV6 di OpenWrt.\n${Font_color_suffix}"
    echo -e "Penggunaan:"
    echo -e "ipv6-helper sub-command"
    echo -e "Contoh:"
    echo -e "\tipv6-helper install: Install ipv6-helper & IPV6 modules"
    echo -e "\tipv6-helper remove: Remove ipv6-helper & IPV6 modules\n"
    echo -e "Opsi Penggunaan:"
    echo -e "\tipv6-helper server: Set IPV6 configuration to server mode"
    echo -e "\tipv6-helper relay: Set IPV6 configuration to relay mode"
    echo -e "\tipv6-helper hybrid: Set IPV6 configuration to hybrid mode"
    echo -e "\tipv6-helper clean: Remove mwan3 modules\n"
}

RebootConfirm(){
    echo -n -e "${Green_font_prefix}Reboot diperlukan, reboot sekarang [y/N] (default N)? ${Font_color_suffix}" 
    read answer
        case $answer in
            Y | y)
            echo -e "Memulai Ulang...\n" && reboot;;
            *)
            echo -e "Memulai Ulang manual nanti.\n";;
        esac
}

CheckInstall(){
    if [ ! -f "/etc/opkg/ipv6-installed" ];then
        echo -e "${Red_background_prefix}\npertama kamu harus eksekusi 'ipv6-helper install'.\n${Font_color_suffix}"
    else
        echo -e "${Green_font_prefix}\nMengkonfigurasi...\n${Font_color_suffix}"
    fi
}

if [ $# == 0 ];then
    Welcome

elif [[ $1 = "install" ]]; then
    echo -e "${Green_font_prefix}\nMenginstall module IPV6...\n${Font_color_suffix}"
    cd /www/ipv6-modules
    opkg install *.ipk
    echo -e "${Green_font_prefix}\nInstall modules IPV6 sukses.\n${Font_color_suffix}"
    echo -e "${Green_font_prefix}Mengkonfigurasi IPV6...\n${Font_color_suffix}"
    
    # Set server to lan
    uci set dhcp.lan.dhcpv6=server
    uci set dhcp.lan.ra=server
    uci set dhcp.lan.ndp=hybrid
    uci set dhcp.lan.ra_management=1
    uci set dhcp.lan.ra_default=1
    
    # Set server to wan6
    uci set dhcp.wan6=dhcp
    uci set dhcp.wan6.interface=wan
    uci set dhcp.wan6.ra=server
    uci set dhcp.wan6.dhcpv6=server
    uci set dhcp.wan6.ndp=hybrid
    uci set dhcp.wan6.master=1
    
    # Disable IPV6 ula prefix
    sed -i 's/^[^#].*option ula/#&/' /etc/config/network
    
    # Enable IPV6 dns resolution
    uci delete dhcp.@dnsmasq[0].filter_aaaa
    
    # Set mwan3 balance strategy to default
    uci set mwan3.balanced.last_resort=default
    
    # Commit changes
    uci commit
    
    # Remove mwan3 ip6tables rules
    cp /lib/mwan3/mwan3.sh /lib/mwan3/mwan3.sh.orig
    sed -i 's/ip6tables -t manle -w/\/bin\/true/g' /lib/mwan3/mwan3.sh
    
    touch /etc/opkg/ipv6-installed
    
    echo -e "${Green_font_prefix}Konfigurasi IPV6 sukses.\n${Font_color_suffix}"
    
    RebootConfirm
    
elif [[ $1 = "server" ]]; then
    CheckInstall
    
    # Set server to lan
    uci set dhcp.lan.dhcpv6=server
    uci set dhcp.lan.ra=server
    uci set dhcp.wan6.ndp=hybrid
    uci set dhcp.lan.ra_management=1
    uci set dhcp.lan.ra_default=1
    
    # Set server to wan6
    uci set dhcp.wan6=dhcp
    uci set dhcp.wan6.interface=wan
    uci set dhcp.wan6.ra=server
    uci set dhcp.wan6.dhcpv6=server
    uci set dhcp.wan6.ndp=hybrid
    uci set dhcp.wan6.master=1
    
    # Commit changes
    uci commit
    
    echo -e "${Green_font_prefix}Mode server sukses dikonfigurasi.\n${Font_color_suffix}"
    
    RebootConfirm
    
elif [[ $1 = "relay" ]]; then
    CheckInstall
    
    # Set relay to lan
    uci set dhcp.lan.dhcpv6=relay
    uci set dhcp.lan.ndp=relay
    uci set dhcp.lan.ra=relay
    uci delete dhcp.lan.ra_management
    
    # Set relay to wan6
    uci set dhcp.wan6=dhcp
    uci set dhcp.wan6.interface=wan
    uci set dhcp.wan6.ra=relay
    uci set dhcp.wan6.dhcpv6=relay
    uci set dhcp.wan6.ndp=relay
    uci set dhcp.wan6.master=1
    
    # Commit changes
    uci commit
    
    echo -e "${Green_font_prefix}Mode relay sukses dikonfigurasi.\n${Font_color_suffix}"
    
    RebootConfirm
    
elif [[ $1 = "hybrid" ]]; then
    CheckInstall
    
    # Set hybrid to lan
    uci set dhcp.lan.dhcpv6=hybrid
    uci set dhcp.lan.ndp=hybrid
    uci set dhcp.lan.ra=hybrid
    uci set dhcp.lan.ra_management=1
    uci set dhcp.lan.ra_default=1
    
    # Set hybrid to wan6
    uci set dhcp.wan6=dhcp
    uci set dhcp.wan6.interface=wan
    uci set dhcp.wan6.ra=hybrid
    uci set dhcp.wan6.dhcpv6=hybrid
    uci set dhcp.wan6.ndp=hybrid
    uci set dhcp.wan6.master=1
    
    # Commit changes
    uci commit
    
    echo -e "${Green_font_prefix}Mode hybrid sukses dikonfigurasi.\n${Font_color_suffix}"
    
    RebootConfirm
    
elif [[ $1 = "remove" ]]; then
    echo -e "${Green_font_prefix}\nMenghapus modules IPV6...\n${Font_color_suffix}"
    opkg remove --force-removal-of-dependent-packages ipv6helper kmod-sit odhcp6c luci-proto-ipv6 ip6tables kmod-ipt-nat6 odhcpd-ipv6only kmod-ip6tables-extra
    echo -e "${Green_font_prefix}\nMenghapus modules IPV6 sukses.\n${Font_color_suffix}"
    echo -e "${Green_font_prefix}Menghapus konfigurasi IPV6...\n${Font_color_suffix}"
    
    # Remove wan6 dhcp configurations
    uci delete dhcp.wan6.ra
    uci delete dhcp.wan6.dhcpv6
    uci delete dhcp.wan6.ndp
    
    # Remove lan dhcp configurations
    uci delete dhcp.lan.dhcpv6
    uci delete dhcp.lan.ndp
    uci delete dhcp.lan.ra
    uci delete dhcp.lan.ra_management
    uci delete dhcp.lan.ra_default
    
    # Enable IPV6 ula prefix
    sed -i 's/#.*\toption ula/\toption ula/g' /etc/config/network
    
    # Disable IPV6 dns resolution
    uci set dhcp.@dnsmasq[0].filter_aaaa=1
    
    # Restore mwan3 balance strategy
    uci set mwan3.balanced.last_resort=unreachable
    
    # Commit changes
    uci commit
    
    # Restore mwan3 ip6tables rules
    rm /lib/mwan3/mwan3.sh
    cp /lib/mwan3/mwan3.sh.orig /lib/mwan3/mwan3.sh
    
    rm -f /etc/opkg/ipv6-installed
    
    echo -e "${Green_font_prefix}Menghapus konfigurasi IPV6 sukses.\n${Font_color_suffix}"
    
    RebootConfirm
    
elif [[ $1 = "clean" ]]; then
    echo -e "${Green_font_prefix}\nMenghapus modules mwan3...\n${Font_color_suffix}"
    opkg remove mwan3 luci-app-mwan3 luci-app-mwan3helper luci-app-syncdial
    echo -e "${Green_font_prefix}Menghapus modules mwan3 sukses.\n${Font_color_suffix}"
    
    RebootConfirm
    
fi

exit 0
