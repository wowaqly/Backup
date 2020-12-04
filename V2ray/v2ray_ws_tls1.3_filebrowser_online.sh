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

function check_os(){
green "系统支持检测"
sleep 3s
if   cat /etc/issue | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
elif cat /etc/issue | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "debian"; then
    release="debian"
    systemPackage="apt-get"
elif cat /proc/version | grep -Eqi "ubuntu"; then
    release="ubuntu"
    systemPackage="apt-get"
fi
if [ "$release" == "ubuntu" ]; then
    if  [ -n "$(grep ' 14\.' /etc/os-release)" ] ;then
    red "==============="
    red "当前系统不受支持"
    red "==============="
    exit
    fi
    if  [ -n "$(grep ' 12\.' /etc/os-release)" ] ;then
    red "==============="
    red "当前系统不受支持"
    red "==============="
    exit
    fi
    ufw_status=`systemctl status ufw | grep "Active: active"`
    if [ -n "$ufw_status" ]; then
        ufw allow 80/tcp
        ufw allow 443/tcp
    fi
    apt-get update >/dev/null 2>&1
    green "开始安装nginx编译依赖"
    apt-get install -y git curl build-essential libpcre3 libpcre3-dev zlib1g-dev liblua5.1-dev libluajit-5.1-dev libgeoip-dev google-perftools libgoogle-perftools-dev >/dev/null 2>&1
elif [ "$release" == "debian" ]; then
    apt-get update >/dev/null 2>&1
    green "开始安装nginx编译依赖"
    apt-get install -y  git curl build-essential libpcre3 libpcre3-dev zlib1g-dev liblua5.1-dev libluajit-5.1-dev libgeoip-dev google-perftools libgoogle-perftools-dev >/dev/null 2>&1
fi
}

function check_env(){
green "安装环境监测"
sleep 3s
firewall_status=`firewall-cmd --state`
if [ "$firewall_status" == "running" ]; then
    green "检测到firewalld开启状态，添加放行80/443端口规则"
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --reload
fi
$systemPackage -y install net-tools socat >/dev/null 2>&1
Port80=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 80`
Port443=`netstat -tlpn | awk -F '[: ]+' '$1=="tcp"{print $5}' | grep -w 443`
if [ -n "$Port80" ]; then
    process80=`netstat -tlpn | awk -F '[: ]+' '$5=="80"{print $9}'`
    red "==========================================================="
    red "检测到80端口被占用，占用进程为：${process80}，本次安装结束"
    red "==========================================================="
    exit 1
fi
if [ -n "$Port443" ]; then
    process443=`netstat -tlpn | awk -F '[: ]+' '$5=="443"{print $9}'`
    red "============================================================="
    red "检测到443端口被占用，占用进程为：${process443}，本次安装结束"
    red "============================================================="
    exit 1
fi
}
function install_nginx(){
    cd /root
    wget https://raw.githubusercontent.com/wowaqly/Backup/patch/V2ray/openssl-1.1.1a.tar.gz >/dev/null 2>&1
    tar xzvf openssl-1.1.1a.tar.gz >/dev/null 2>&1
    mkdir /etc/nginx
    mkdir /etc/nginx/ssl
    mkdir /etc/nginx/conf.d
    wget https://raw.githubusercontent.com/wowaqly/Backup/patch/V2ray/nginx-1.15.8.tar.gz >/dev/null 2>&1
    tar xf nginx-1.15.8.tar.gz  >/dev/null 2>&1
    cd nginx-1.15.8
    ./configure --prefix=/etc/nginx --with-openssl=../openssl-1.1.1a --with-openssl-opt='enable-tls1_3' --with-http_v2_module --with-http_ssl_module --with-http_gzip_static_module --with-http_stub_status_module --with-http_sub_module --with-stream --with-stream_ssl_module  >/dev/null 2>&1
    green "开始编译安装nginx，编译等待时间可能较长，请耐心等待，通常需要几到十几分钟"
    sleep 3s
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
    
cat > /etc/nginx/conf/nginx.conf <<-EOF
user  root;
worker_processes  1;
error_log  /etc/nginx/logs/error.log warn;
pid        /etc/nginx/logs/nginx.pid;
events {
    worker_connections  1024;
}
http {
    include       /etc/nginx/conf/mime.types;
    default_type  application/octet-stream;
    log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                      '\$status \$body_bytes_sent "\$http_referer" '
                      '"\$http_user_agent" "\$http_x_forwarded_for"';
    access_log  /etc/nginx/logs/access.log  main;
    sendfile        on;
    #tcp_nopush     on;
    keepalive_timeout  120;
    client_max_body_size 20m;
    #gzip  on;
    include /etc/nginx/conf.d/*.conf;
}
EOF
    cd /root
    git clone https://github.com/acmesh-official/acme.sh.git
	cd /root/acme.sh
	chmod +x acme.sh
	./acme.sh --install
    ~/.acme.sh/acme.sh  --issue  -d $your_domain  --standalone
    ~/.acme.sh/acme.sh  --installcert  -d  $your_domain   \
        --key-file   /etc/nginx/ssl/$your_domain.key \
        --fullchain-file /etc/nginx/ssl/fullchain.cer
    newpath=$(cat /dev/urandom | head -1 | md5sum | head -c 9)
	
    green "======================="
    blue "请输入用来反代伪装的网站，不要有敏感内容的网站"
    blue "必须要支持https的网站，例如—— https://www.videvo.net"
    green "======================="
    read pretend_url
cat > /etc/nginx/conf.d/default.conf<<-EOF
server { 
    listen       80;
    server_name  $your_domain;
    rewrite ^(.*)$  https://\$host\$1 permanent; 
}
server {
    listen 443 ssl http2;
    server_name $your_domain;
    location / {
        proxy_pass $pretend_url;
    }
    ssl_certificate /etc/nginx/ssl/fullchain.cer; 
    ssl_certificate_key /etc/nginx/ssl/$your_domain.key;
    #TLS 版本控制
    ssl_protocols   TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_ciphers     'TLS13-AES-256-GCM-SHA384:TLS13-CHACHA20-POLY1305-SHA256:TLS13-AES-128-GCM-SHA256:TLS13-AES-128-CCM-8-SHA256:TLS13-AES-128-CCM-SHA256:EECDH+CHACHA20:EECDH+CHACHA20-draft:EECDH+ECDSA+AES128:EECDH+aRSA+AES128:RSA+AES128:EECDH+ECDSA+AES256:EECDH+aRSA+AES256:RSA+AES256:EECDH+ECDSA+3DES:EECDH+aRSA+3DES:RSA+3DES:!MD5';
    ssl_prefer_server_ciphers   on;
    # 开启 1.3 0-RTT
    ssl_early_data  on;
    ssl_stapling on;
    ssl_stapling_verify on;
    #add_header Strict-Transport-Security "max-age=31536000";
    #access_log /var/log/nginx/access.log combined;
    #v2ray
    location /$newpath {
        proxy_redirect off;
        proxy_pass http://127.0.0.1:12345; 
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$http_host;
    }
    #反代filebrowser
    location /fb {
        client_max_body_size 0;
        proxy_read_timeout 10s;
        proxy_send_timeout 10s;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_http_version 1.1;
        proxy_redirect off;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_pass http://127.0.0.1:8888;
        } 
}
EOF

cat > /etc/systemd/system/nginx.service<<-EOF
[Unit]
Description=nginx service
After=network.target 
   
[Service] 
Type=forking 
ExecStart=/etc/nginx/sbin/nginx
ExecReload=/etc/nginx/sbin/nginx -s reload
ExecStop=/etc/nginx/sbin/nginx -s quit
PrivateTmp=true 
   
[Install] 
WantedBy=multi-user.target
EOF
chmod 777 /etc/systemd/system/nginx.service
systemctl enable nginx.service
install_filebrowser
}

#安装nginx
function install(){
    $systemPackage install -y wget curl unzip >/dev/null 2>&1
    green "======================="
    blue "请输入绑定到本VPS的域名"
    green "======================="
    read your_domain
    real_addr=`ping ${your_domain} -c 1 | sed '1{s/[^(]*(//;s/).*//;q}'`
    local_addr=`curl ipv4.icanhazip.com`
    if [ $real_addr == $local_addr ] ; then
        green "=========================================="
	green "         域名解析正常，开始安装"
	green "=========================================="
        install_nginx
    else
        red "===================================="
	red "域名解析地址与本VPS IP地址不一致"
	red "若你确认解析成功你可强制脚本继续运行"
	red "===================================="
	read -p "是否强制运行 ?请输入 [Y/n] :" yn
	[ -z "${yn}" ] && yn="y"
	if [[ $yn == [Yy] ]]; then
            green "强制继续运行脚本"
	    sleep 1s
	    install_nginx
	else
	    exit 1
	fi
    fi
}
#安装filebrowser
function install_filebrowser(){
    cd /root
	curl -s https://api.github.com/repos/filebrowser/filebrowser/releases/latest | grep "browser_download_url.*linux-amd64-filebrowser.tar.gz" | cut -d '"' -f 4 | wget -i -
	tar -xvf linux-amd64-filebrowser.tar.gz
	mkdir -p /filebrowser
    mv filebrowser /filebrowser
    cd /filebrowser
    ./filebrowser -d /filebrowser/filebrowser.db config init
    ./filebrowser -d /filebrowser/filebrowser.db config set --address 0.0.0.0
    ./filebrowser -d /filebrowser/filebrowser.db config set --port 8888
    ./filebrowser -d /filebrowser/filebrowser.db config set --locale zh-cn
    ./filebrowser -d /filebrowser/filebrowser.db config set --log /filebrowser/filebrowser.log
    ./filebrowser -d /filebrowser/filebrowser.db users add admin 123456 --perm.admin
cat > /etc/systemd/system/filebrowser.service<<-EOF
[Unit]
Description=File Browser
After=network.target

[Service]
ExecStart=/filebrowser/filebrowser -d /filebrowser/filebrowser.db

[Install]
WantedBy=multi-user.target
EOF
     systemctl enable filebrowser.service 
     install_v2ray
}

#安装v2ray
function install_v2ray(){
    cd /root
	curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep "browser_download_url.*v2ray-linux-64.zip" | cut -d '"' -f 4 | wget -i -
	rm -f /root/v2ray-linux-64.zip.dgst
	wget -P /v2ray https://raw.githubusercontent.com/wowaqly/Backup/patch/V2ray/v2ray-config.json >/dev/null 2>&1
    mkdir /v2ray
    cp /root/v2ray-linux-64.zip /v2ray
	cd /v2ray
	unzip v2ray-linux-64.zip
	rm -f v2ray-linux-64.zip
    rm -f config.json
    cp /root/v2ray-config.json /v2ray >/dev/null 2>&1
    v2uuid=$(cat /proc/sys/kernel/random/uuid)
    sed -i "s/aaaa/$v2uuid/;" v2ray-config.json
    sed -i "s/mypath/$newpath/;" v2ray-config.json
cat > /etc/systemd/system/v2ray.service<<-EOF
[Unit]
Description=v2ray Server
After=network.target

[Service]
Type=simple
ExecStart=/v2ray/v2ray -config /v2ray/v2ray-config.json
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOF
    chmod 777 /etc/systemd/system/v2ray.service
    systemctl enable v2ray.service
    systemctl restart v2ray.service
    systemctl restart nginx.service
    systemctl restart filebrowser.service    
    
cat > /v2ray/myconfig.json<<-EOF
{
===========配置参数=============
地址：${your_domain}
端口：443
uuid：${v2uuid}
额外id：64
加密方式：aes-128-gcm
传输协议：ws
别名：myws
路径：${newpath}
底层传输：tls
}
EOF

green "=============================="
green "         安装已经完成"
green "===========配置参数============"
green "地址：${your_domain}"
green "端口：443"
green "uuid：${v2uuid}"
green "额外id：64"
green "加密方式：aes-128-gcm"
green "传输协议：ws"
green "别名：myws"
green "路径：${newpath}"
green "底层传输：tls"
green 
}
#更新v2ray
function update_v2ray(){
	cd /root
	rm -f v2ray-linux-64.zip
	curl -s https://api.github.com/repos/v2fly/v2ray-core/releases/latest | grep "browser_download_url.*v2ray-linux-64.zip" | cut -d '"' -f 4 | wget -i -
	rm -f /root/v2ray-linux-64.zip.dgst
    systemctl stop v2ray.service
	mkdir /root/lingshi389
	cp /v2ray/v2ray-config.json /root/lingshi389
	rm -rf /v2ray
    mkdir /v2ray
    cp /root/v2ray-linux-64.zip /v2ray
	cd /v2ray
	unzip v2ray-linux-64.zip
	rm -f v2ray-linux-64.zip
    rm -f v2ray-config.json
	cp /root/lingshi389/v2ray-config.json /v2ray
	rm -rf /root/lingshi389
    systemctl restart v2ray.service
}
#删除 v2ray-nginx-filebrowser
function remove_v2ray(){
    systemctl daemon-reload
    /etc/nginx/sbin/nginx -s stop
    systemctl stop v2ray.service
    systemctl disable v2ray.service
	systemctl stop nginx.service
    systemctl disable nginx.service
	systemctl stop filebrowser.service
    systemctl disable filebrowser.service
    rm -rf /filebrowser
    rm -rf /v2ray
    rm -rf /usr/local/share/v2ray/ /usr/local/etc/v2ray/
    rm -rf /etc/systemd/system/v2ray*
	rm -rf /etc/systemd/system/v2ray.*
	rm -rf /etc/systemd/system/nginx.*
	rm -rf /etc/systemd/system/filebrowser.*
    rm -rf /etc/nginx
    green "nginx、v2ray、filebrowser已删除"
}

function remove_package(){
    rm -rf /root/LICENSE
    rm -rf /root/CHANGELOG.md
    rm -rf /root/README.md
    rm -rf /root/.acme.sh
    rm -rf /root/acme.sh
    rm -rf /root/acme.sh.zip
    rm -rf /root/nginx-1.15.8.tar.gz
    rm -rf /root/openssl-1.1.1a.tar.gz
	rm -rf /root/v2ray-config.json
	rm -rf /root/v2ray-linux-64.zip  
	rm -rf nginx-1.15.8
	rm -rf openssl-1.1.1a
	rm -f /root/v2ray-linux-64.zip.dgst
	rm -f /root/linux-amd64-filebrowser.tar.gz
    green "安装包已删除"  
}

function update_ssl(){
    green "======================="
    blue "请输入绑定到本VPS的域名"
    green "======================="
   read your_domain_update_ssl
   ~/.acme.sh/acme.sh --upgrade
   ~/.acme.sh/acme.sh  --issue  -d $your_domain_update_ssl  --standalone
   ~/.acme.sh/acme.sh  --installcert  -d  $your_domain_update_ssl   \
       --key-file   /etc/nginx/ssl/$your_domain_update_ssl.key \
       --fullchain-file /etc/nginx/ssl/fullchain.cer
}
function start_menu(){
    clear
    green " ==============================================="
    green " Info       : onekey script install v2ray+ws+tls        "
    green " OS support : debian9+/ubuntu16.04+                       "
    green " 一般不需要手动更新ssl,出现证书过期问题再使用      "
    green " filebrowser  打开方式 xxx.xxxx.top/fb      "
    green " filebrowser  初始用户名 admin 密码 123456      "
    green " ==============================================="
    echo
    green " 1. 安装 v2ray+ws+tls1.3+filebrowser"
    green " 2. 手动更新 ssl"
    green " 3. 更新 v2ray"
    red " 4. 删除安装包"
    red " 8. 删除 v2ray-nginx-filebrowser"
    yellow " 0. 退出"
    echo
    read -p "Pls enter a number:" num
    case "$num" in
    1)
    check_os
    check_env
    install
    ;;
    2)
    update_ssl
    ;;
    3)
    update_v2ray
    ;;
    4)
    remove_package
    ;;
    8)
    remove_v2ray 
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

start_menu
