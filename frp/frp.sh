#!/bin/bash
function blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
function green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
function red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
function yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}
#安装frp
function install_frp(){
    apt-get install -y git curl vim unzip
    cd /root
    #下载frp
	curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep "browser_download_url.*linux_amd64.tar.gz" | cut -d '"' -f 4 | wget -i -
	#解压压缩包
	frp_tar_name=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep "name.*linux_amd64.tar.gz" | cut -d '"' -f 4)
	tar -xzvf $frp_tar_name
	#文件夹改名
	frp_tag_name=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep "tag_name.*" | cut -d "v" -f 2 |cut -d '"' -f 1)
	mv frp_"$frp_tag_name"_linux_amd64 frp
	#剩余步骤
	cp -r frp /
	cd /frp
	chmod +x frps
	chmod +x frpc
	rm -rf /root/$frp_tar_name
	rm -rf /root/frp
}

#配置frps
function install_frp_frps(){
    rm -f /frp/frps.ini
    green "======================="
    blue "请输入用于连接的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_bind_port
######################################
    green "======================="
    blue "请输入用于连接的密码"
    green "======================="
    read frps_token
######################################
    green "======================="
    blue "请输入用于web管理界面的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_dashboard_port
######################################
    green "======================="
    blue "请输入用于web管理界面的用户名"
    green "======================="
    read frps_dashboard_user
######################################
    green "======================="
    blue "请输入用于web管理界面的密码"
    green "======================="
    read frps_dashboard_pwd
###################################### 
    green "======================="
    blue "请输入用于反代http服务的端口号 范围1-65533 "
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_vhost_http_port
###################################### 
    green "======================="
    blue "请输入用于反代https服务的端口号 范围1-65533 "
    blue "请注意不要重复使用端口"
    green "======================="
    read frps_vhost_https_port
######################################
    green "======================="
    blue "请输入fprs服务器绑定的域名,例如frp.xxx.com"
    blue "这里一定要加入前缀，不可直接输入xxx.com!!!"
    green "======================="
    read frps_subdomain_host
    
cat > /frp/frps.ini <<-EOF
[common]
bind_port = $frps_bind_port
kcp_bind_port = $frps_bind_port
token = $frps_token
authentication_timeout = 900
dashboard_port = $frps_dashboard_port
dashboard_user = $frps_dashboard_user
dashboard_pwd = $frps_dashboard_pwd
vhost_http_port = $frps_vhost_http_port
vhost_https_port = $frps_vhost_https_port
subdomain_host = $frps_subdomain_host
tls_only = true
EOF

cat > /etc/systemd/system/frps.service<<-EOF
[Unit]
Description=frps service
After=network.target network-online.target syslog.target
Wants=network.target network-online.target

[Service]
Type=simple

ExecStart=/frp/frps -c /frp/frps.ini

[Install]
WantedBy=multi-user.target
EOF
systemctl enable frps.service
systemctl restart frps.service
}
#重启frps
function frp_frps_restart(){
systemctl restart frps.service
green "frps已重启"
}
#更新frp
function update_frp(){
    systemctl stop frps.service
    systemctl stop frpc.service
    mkdir /root/frpinilswjj
    cp /frp/frps.ini /root/frpinilswjj
    cp /frp/frpc.ini /root/frpinilswjj
    rm -rf /frp
    cd /root
    #下载frp
	curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep "browser_download_url.*linux_amd64.tar.gz" | cut -d '"' -f 4 | wget -i -
	#解压压缩包
	frp_tar_name=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep "name.*linux_amd64.tar.gz" | cut -d '"' -f 4)
	tar -xzvf $frp_tar_name
	#文件夹改名
	frp_tag_name=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep "tag_name.*" | cut -d "v" -f 2 |cut -d '"' -f 1)
	mv frp_"$frp_tag_name"_linux_amd64 frp
	#剩余步骤
	cp -r frp /
	cd /frp
	chmod +x frps
	chmod +x frpc
	rm -f /frp/frps.ini
	rm -f /frp/frpc.ini
	cp /root/frpinilswjj/frps.ini /frp
	cp /root/frpinilswjj/frpc.ini /frp
	rm -rf /root/$frp_tar_name
	rm -rf /root/frp
	rm -rf cp /root/frpinilswjj
    systemctl restart frps.service
    systemctl restart frpc.service
    green "frp已更新"
}
#安装frpc服务
function install_frp_frpc(){
    green "======================="
    blue "安装后请先自行去/frp修改frpc.ini再去手动启动frpc"
    green "======================="
    wget -O /frp/frpc.ini-explain.readme https://raw.githubusercontent.com/wowaqly/Backup/patch/frp/frpc.ini-explain.readme

cat > /etc/systemd/system/frpc.service<<-EOF
[Unit]
Description=frpc service
After=network.target network-online.target syslog.target
Wants=network.target network-online.target

[Service]
Type=simple

ExecStart=/frp/frpc -c /frp/frpc.ini

[Install]
WantedBy=multi-user.target
EOF
}
#启动/重启frpc
function frp_frpc_restart(){
    systemctl restart frpc.service
    systemctl enable frpc.service
    green "frps已启动/重启"
}
#删除 frp
function remove_frp(){
    systemctl stop frpc.service
    systemctl stop frps.service
    systemctl disable frps.service
    systemctl disable frpc.service
    mkdir /root/frpconfig-backups
    cp /frp/frpc.ini /root/frpconfig-backups
    cp /frp/frps.ini /root/frpconfig-backups
    rm -rf /frp
    rm -f /etc/systemd/system/frpc.service
    rm -f /etc/systemd/system/frps.service
    green "frp已删除"
    green "frps/frpc配置文件已备份到/root/frpconfig-backups"
    green "备份的配置文件需要手动删除"
}
#编辑frpc.ini
function vim_frp_frpcini(){
    clear
    echo
    green " ==============================================="
    green " 默认使用vim编辑器,编辑完成后需要手动启动/重启frpc"
    green " 1.编辑frpc.ini"
    green " 2.查看frpc.ini说明"
    yellow " 0. 退出"    
    green " ==============================================="
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    cp -f /frp/frpc.ini /frp/frpc.ini.backups
    vim /frp/frpc.ini
    green " 编辑完成后需要手动启动/重启frpc"
    ;;
    2)
    vim /frp/frpc.ini-explain.readme
    ;;
    0)
    exit 1
    esac
}
    

#菜单
function start_menu(){
    clear
    green " ==============================================="
    green " OS support : debian9+/ubuntu16.04+   only amd64                    "
    green " 先安装frp在编辑fprs和frpc                  "
    green " frpc需要 配置frpc--编辑frpc.ini     "
    green " ==============================================="
    echo
    green " 1. 安装 frp"
    green " 2. 配置并启动frps"
    green " 3. 仅配置不启动frpc"
    green " 4. 手动编辑frpc.ini配置文件"
    green " 5. 重启frps"
    green " 6. 启动/重启frpc"
    green " 7. 更新frp"
    red " 9. 删除 frp"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    install_frp
    ;;
    2)
    install_frp_frps
    ;;
    3)
    install_frp_frpc
    ;;
    4)
    vim_frp_frpcini
    ;;
    5)
    frp_frps_restart
    ;;
    6)
    frp_frpc_restart
    ;;
    7)
    update_frp
    ;;
    9)
    remove_frp
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    0)
    exit 1
    esac
}

start_menu
