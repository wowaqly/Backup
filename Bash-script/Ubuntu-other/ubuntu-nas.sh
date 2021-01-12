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
#主菜单
function start_menu(){
    clear
    green " ==============================================="
    green " 只支持使用Ubuntu20.04的国内AMD64机器 "
    green " 尽量使用非root账号运行 " 
    green " 如果aira2下载的文件，或者fb管理文件时遇到权限问题。请分别尝试root和非root账户安装 "
    green " 请分别尝试root和非root账户安装 "
    green " ==============================================="
    echo
    green " 1. 更换国内源"
    green " 2. 安装Samba"
    green " 3. 安装xrdp(远程桌面)"
    green " 4. 安装/更新Docker以及部分容器"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    update_apt
    ;;
    2)
    install_samba
    ;;
    3)
    install_xrdp
    ;;
    4)
    install_update_docker_and_dockerrun
    ;;
    0)
    exit
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    esac
}
#更换国内源
function update_apt(){
    sudo cp -f /etc/apt/sources.list /etc/apt/sources.list.beifeng
    sudo rm -f /etc/apt/sources.list
sudo bash -c 'cat << EOF > /etc/apt/sources.list
deb http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-security main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-updates main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-proposed main restricted universe multiverse

deb http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
#deb-src http://mirrors.aliyun.com/ubuntu/ focal-backports main restricted universe multiverse
EOF'
    sudo apt update
	sudo apt upgrade 
	green " 源已更新"
}

#安装Samba
function install_samba(){
    sudo apt install samba -y
######################################
    green "======================="
    blue "请输入用于samba连接账号"
    blue "如果是修改密码，先输入之前的samba连接账号"
	blue " 一般只可单一用户，需要多用户自行百度"
    green "======================="
    read samba_adduser 
######################################
	blue "请输入用于samba连接账号密码"
    sudo smbpasswd -a $samba_adduser
	green " Samba已安装"
    green " 如果提示	Mismatch - password unchanged.
                 Unable to get new password. "
	green " 说明两次密码不一样，请再次运行"
	green " 没有提示或提示成功则安装成功"
	green " 一般只可单一用户，需要多用户自行百度"
}

#安装xrdp(远程桌面)
function install_xrdp(){
    sudo apt install xrdp -y
######################################
    green "======================="
    blue "请输入用于远程桌面连接的非root账号"
    green "======================="
    read xrdp_user 
######################################
    sudo useradd $rdp_user ssl-cert
	green " xrdp已安装"
	green "安装完成后直接使用微软远程桌面协议连接"
	green "需要注销账号的本地登录才可以用此账号登录远程桌面"
	green "如果有防火墙则需要开放3389端口"

}

#安装/更新Docker以及部分容器
function install_update_docker_and_dockerrun(){
  sudo apt-get install -y vim unzip git curl
  clear
    echo
    green " 1. 安装Docker"
    green " 2. 更新Docker"
    green " 3. 安装filebrowser"
    green " 4. 安装aria2-pro"
    green " 5. 安装ariang"
    green " 6. 安装shadowsocks-libev"
    green " 7. docker停止/重启/删除容器说明"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    sudo mkdir -p /etc/docker
    sudo tee /etc/docker/daemon.json <<-'EOF'
{
"registry-mirrors": ["https://7zbtvkwx.mirror.aliyuncs.com","https://dockerhub.azk8s.cn","https://reg-mirror.qiniu.com"]
}
EOF
    sudo systemctl daemon-reload
    sudo systemctl restart docker
    green " Docker已安装"
    ;;
    2)
    sudo curl -fsSL https://get.docker.com | sudo bash -s docker --mirror Aliyun
    green " Docker已更新"
    ;;
    3)
    install_filebrowser
    ;;
    4)
    install_aria2-pro
    ;;
    5)
	install_ariang
    ;;
    6)
    install_shadowsocks
    ;;
    7)
    ps_docker
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    esac
}
#安装filebrowser
function install_filebrowser(){
sudo mkdir /docker
sudo mkdir /docker/filebrowser/
sudo mkdir /docker/filebrowser/config
######################################
    green "======================="
    blue "请输入用于web管理界面的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read fbWEB_PORT
######################################
######################################
    green "======================="
    blue "请输入要用作filebrowser文件保存管理的目录"
    blue "输入绝对路径 例如 /mnt/ssd-1/box"
    green "======================="
    read fbWEB_folder
######################################
######################################
    green "======================="
    blue "请输入显示的UID"
    green "======================="
    id
    read fbUID
######################################
######################################
    green "======================="
    blue "请输入显示的GID "
    green "======================="
    id
    read fbGID
######################################
  clear
    echo
    green " 1. 以https安装(需要手动导入ssl证书)"
    green " 2. 以http安装(可以后期用nginx或frp等反代成https)"
    green " 0. 关闭"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
sudo docker run -d --name filebrowser \
  --restart=unless-stopped \
  -e PUID=$fbUID \
  -e PGID=$fbGID \
  -e WEB_PORT=$fbWEB_PORT \
  -e FB_AUTH_SERVER_ADDR=0.0.0.0 \
  -p $fbWEB_PORT:$fbWEB_PORT \
  -e FB_SSL=on \
  -v /docker/filebrowser/config:/config \
  -v $fbWEB_folder:/myfiles \
  --mount type=tmpfs,destination=/tmp \
  80x86/filebrowser:2.9.4-amd64
green "Filebrowser安装完毕"
green "请手动替换ssl证书（/config/ssl/ssl.crt）（/config/ssl/ssl.key）"
green "把自己的ssl证书改名成ssl.crt/ssl.key后覆盖"
green "如果是pem格式的证书直接改后缀为crt后倒入"
    ;;
    2)
sudo docker run -d --name filebrowser \
  --restart=unless-stopped \
  -e PUID=$fbUID \
  -e PGID=$fbGID \
  -e WEB_PORT=$fbWEB_PORT \
  -e FB_AUTH_SERVER_ADDR=0.0.0.0 \
  -p $fbWEB_PORT:$fbWEB_PORT \
  -v /docker/filebrowser/config:/config \
  -v $fbWEB_folder:/myfiles \
  --mount type=tmpfs,destination=/tmp \
  80x86/filebrowser:2.9.4-amd64
green "Filebrowser安装完毕"
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    start_menu
    ;;
    esac
}
#安装aria2-pro
function install_aria2-pro(){
sudo mkdir /docker
sudo mkdir /docker/aria2/
sudo mkdir /docker/aria2/config
######################################
    green "======================="
    blue "请输入用于RCP连接的端口号 范围1-65533"
    blue "没有特别需求建议6800，请注意不要重复使用端口"
    green "======================="
    read aira2_RPC_PORT 
######################################
    green "======================="
    blue "请输入用于RCP连接认证的密码"
    green "======================="
    read aria2_RPC_SECRET
######################################
######################################
    green "======================="
    blue "请输入用保存下载文件的目录.例如/mnt/ssd-1/downloads"
    green "======================="
    read aria2_downloads
    mkdir -p $aria2_downloads
######################################
######################################
    green "======================="
    blue "请输入用于BT的端口号 范围1-65533"
    blue "随便输入，请注意不要重复使用端口"
    blue "如果在有防火墙注意配置端口开放/转发"
    green "======================="
    read aria2_LISTEN_PORT
######################################
######################################
    green "======================="
    blue "请输入显示的UID"
    green "======================="
    id
    read aria2UID
######################################
######################################
    green "======================="
    blue "请输入显示的GID "
    green "======================="
    id
    read aria2GID
######################################
sudo docker run -d \
    --name aria2-pro \
    --restart=always \
    --log-opt max-size=1m \
    --network host \
    -e PUID=$aria2UID \
    -e PGID=$aria2GID \
    -e RPC_SECRET=$aria2_RPC_SECRET \
    -e RPC_PORT=$aira2_RPC_PORT \
    -e LISTEN_PORT=$aria2_LISTEN_PORT \
    -v /docker/aria2/config:/config \
    -v $aria2_downloads:/downloads \
    p3terx/aria2-pro
green "aria2-pro安装完毕"
green "如果需要https-RCP连接，建议使用web服务反代，或者frp反代"
sleep 2s
install_ariang_menu
}
#分菜单Araign
function install_ariang_menu(){
    clear
    green " ==============================================="
    green " 是否需要安装Ariang(可以在菜单中单独选择安装)"
    green " ==============================================="
    echo
    green " 1. 安装"
    green " 2. 不安装"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    install_ariang
    ;;
    2)
    exit
    ;;
    *)
    clear
    red "Enter the correct number"
    sleep 2s
    install_ariang_menu
    ;;
    esac
}
#安装ariang
function install_ariang(){
######################################
    green "======================="
    blue "请输入用于AriaNg-WEB的端口号 范围1-65533"
    blue "没有特别需求建议6880，然后使用web服务反代，或者frp反代"
    blue "请注意不要重复使用端口"
    green "======================="
    read ariang_web_port 
######################################
sudo docker run -d \
  --name ariang \
  --log-opt max-size=1m \
  --restart=always \
  -p $ariang_web_port:6880 \
  p3terx/ariang
green "ariang安装完毕"
green "如果需要https建议使用web服务反代，或者frp反代"
}
# Docker说明
function ps_docker(){
 clear
    green " ==============================================="
    green " sudo docker ps -a 命令查看进容器id"
    green " sudo docker stop/restart 容器id ---停止重启容器"
    green " sudo docker rm 容器id ---删除容器---需要先停止容器 "
    green " sudo docker images 命令查看进镜像id"
    green " sudo docker rmi 镜像id ---删除镜像---需要先删除容器 "   
    green " ==============================================="
}
#安装shadowsocks以连回局域网
function install_shadowsocks(){
######################################
    green "======================="
    blue "请输入用于连接的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read shadowsocks_port 
######################################
######################################
    green "======================="
    blue "请输入用于连接的密码"
    green "======================="
    read shadowsocks_password
######################################
######################################
    green "======================="
    blue "请输入用于连接的加密方式"
    blue "一般情况用以下4个加密方式"
	blue "'aes-128-gcm' 'aes-256-gcm'"
	blue "'chacha20-ietf-poly1305' 'xchacha20-ietf-poly1305'"
    green "======================="
    read shadowsocks_method
######################################
sudo docker run -e PASSWORD=$shadowsocks_password \
            -e METHOD=$shadowsocks_method \
            -p $shadowsocks_port:8388 \
            -p $shadowsocks_port:8388/udp \
            --name ss-server \
             --restart=always \
            -d shadowsocks/shadowsocks-libev
}
###############以下内容别删别改，且必须放在最后#################
start_menu