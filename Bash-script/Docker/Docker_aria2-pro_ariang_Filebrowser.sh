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
#安装Docker
function install_docker(){
  apt-get install -y vim unzip git curl
  clear
    echo
    green " 1. 国内服务器"
    green " 2. 国外服务器"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    mkdir -p /etc/docker
tee /etc/docker/daemon.json <<-'EOF'
{
"registry-mirrors": ["https://7zbtvkwx.mirror.aliyuncs.com","https://dockerhub.azk8s.cn","https://reg-mirror.qiniu.com"]
}
EOF
    systemctl daemon-reload
    systemctl restart docker
    green " Docker已安装"
    ;;
    2)
    curl -fsSL https://get.docker.com | bash -s docker
    green " Docker已安装"
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
#更新Docker
}
function update_docker(){
  clear
    green " 1. 国内服务器"
    green " 2. 国外服务器"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    curl -fsSL https://get.docker.com | bash -s docker --mirror Aliyun
    green " Docker已更新"
    ;;
    2)
    rcurl -fsSL https://get.docker.com | bash -s docker
    green " Docker已更新"
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
mkdir /docker
mkdir /docker/filebrowser/
mkdir /docker/filebrowser/config
######################################
    green "======================="
    blue "请输入用于web管理界面的端口号 范围1-65533"
    blue "请注意不要重复使用端口"
    green "======================="
    read fbWEB_PORT
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
docker run -d --name filebrowser \
  --restart=unless-stopped \
  -e PUID=$fbUID \
  -e PGID=$fbGID \
  -e WEB_PORT=$fbWEB_PORT \
  -e FB_AUTH_SERVER_ADDR=127.0.0.1 \
  -p $fbWEB_PORT:$fbWEB_PORT \
  -v /docker/filebrowser/config:/config \
  -v /:/myfiles \
  --mount type=tmpfs,destination=/tmp \
  80x86/filebrowser:2.9.4-amd64
green "Filebrowser安装完毕"
}
#安装aria2-pro
function install_aria2-pro(){
mkdir /docker
mkdir /docker/aria2/
mkdir /docker/aria2/config
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
    blue "请输入用保存下载文件的目录.例如/downloads"
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
docker run -d \
    --name aria2-pro \
    --restart unless-stopped \
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
install_ariang
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
docker run -d \
  --name ariang \
  --log-opt max-size=1m \
  --restart unless-stopped \
  -p $ariang_web_port:6880 \
  p3terx/ariang
green "ariang安装完毕"
green "如果需要https建议使用web服务反代，或者frp反代"
}
# 说明
function ps_docker(){
 clear
    green " ==============================================="
    green " docker ps -a 命令查看进容器id"
    green " docker stop/restart 容器id ---停止重启容器"
    green " docker rm 容器id ---删除容器---需要先停止容器 "
    green " docker images 命令查看进镜像id"
    green " docker rmi 镜像id ---删除镜像---需要先删除容器 "   
    green " ==============================================="
}
#菜单
function start_menu(){
    clear
    green " ==============================================="
    green " Info       : onekey script install  filebrowser       "
    green " OS support : debian9+/ubuntu16.04+                       "
    green " 只支持amd64机器 "
    green " ==============================================="
    echo
    green " 1. 安装Docker"
    green " 2. 更新Docker"
    green " 3. 安装filebrowser"
    green " 4. 安装aria2-pro"
    green " 5. docker停止/重启/删除容器说明"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    install_docker
    ;;
    2)
    update_docker
    ;;
    3)
    install_filebrowser
    ;;
    4)
    install_aria2-pro
    ;;
    5)
    ps_docker
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

start_menu
