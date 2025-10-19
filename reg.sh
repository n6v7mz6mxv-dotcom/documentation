VLAN=${1:-0}                 # VLAN, mặc định là 0
Proxy_Count=2000     # Số lượng proxy, mặc định là 4000
USER_PORT=${3:-"VUADOP"}       # Tiền tố cổng người dùng, mặc định là "VUADOP"
FIRST_PORT=${4:-10001}       # Cổng bắt đầu, mặc định là 10001
PASS=${5:-0}                 # Mật khẩu, mặc định là 0
PassChar=${6:-0}  
#
rm /root/log.txt
#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

if [ -f /home/Lowji194/boot_ip.sh ]; then
echo -e "\u0044\u0065\u006c\u0065\u0074\u0069\u006e\u0067\u0020\u004f\u006c\u0064\u0020\u0050\u0072\u006f\u0078\u0079\u0020\u0049\u0050\u00a\u00a\u00a\u00a\u00a\u00a\u00a\u00a" > /root/log.txt
    sed -i 's/\badd\b/del/g' /home/Lowji194/boot_ip.sh
    bash /home/Lowji194/boot_ip.sh
fi
kill $(pgrep StartProxy)
sudo systemctl stop firewalld
sudo systemctl disable firewalld

# Kiểm tra quyền truy cập root
if [ "$(id -u)" -ne "0" ]; then
  echo "Vui lòng chạy script này với quyền root." >&2
else
# Đặt kích thước swap
SWAP_SIZE="10G"
SWAP_FILE="/swapfile"

# Kiểm tra nếu tệp swap đã tồn tại
if [ -f "$SWAP_FILE" ]; then
  echo "Tệp swap đã tồn tại. Vui lòng xóa tệp /swapfile hoặc thay đổi tên tệp trong script."
  else
  # Tạo tệp swap
echo "Tạo tệp swap $SWAP_FILE với kích thước $SWAP_SIZE..."
fallocate -l $SWAP_SIZE $SWAP_FILE

# Nếu fallocate không thành công, sử dụng dd
if [ $? -ne 0 ]; then
  echo "Lệnh fallocate không thành công. Sử dụng dd để tạo tệp swap..."
  dd if=/dev/zero of=$SWAP_FILE bs=1M count=$(echo $SWAP_SIZE | sed 's/G//')000
fi

# Đặt quyền truy cập cho tệp swap
chmod 600 $SWAP_FILE

# Tạo hệ thống tập tin swap
echo "Tạo hệ thống tập tin swap trên $SWAP_FILE..."
mkswap $SWAP_FILE

# Kích hoạt swap
echo "Kích hoạt swap..."
swapon $SWAP_FILE
# Thêm tệp swap vào /etc/fstab để tự động kích hoạt khi khởi động
if ! grep -q "$SWAP_FILE" /etc/fstab; then
  echo "$SWAP_FILE none swap sw 0 0" >> /etc/fstab
  echo "Tệp swap đã được thêm vào /etc/fstab."
else
  echo "Tệp swap đã được thêm vào /etc/fstab rồi."
fi

echo "Hoàn tất cấu hình swap."
swapon --show

fi
fi




echo -e "Cài đặt Repository" > /root/log.txt
if [ -f /etc/almalinux-release ]; then
    rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
else
    sed -i 's/mirror.centos.org/vault.centos.org/g' /etc/yum.repos.d/*.repo
    sed -i 's/^#.*baseurl=http/baseurl=http/g' /etc/yum.repos.d/*.repo
    sed -i 's/^mirrorlist=http/#mirrorlist=http/g' /etc/yum.repos.d/*.repo
    echo "sslverify=false" >> /etc/yum.conf
fi

packages=(curl wget make gcc net-tools bsdtar zip tar)
#packages=(curl wget)

for package in "${packages[@]}"; do
    if ! rpm -q $package >/dev/null 2>&1; then
        echo -e "$package Đang cài đặt..."  > /root/log.txt
       sudo yum -y install $package
    fi
done



random() {
	tr </dev/urandom -dc a-z0-9 | head -c5
	echo
}
array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}

VUADOPPROXY() {
    # Kiểm tra nếu thư mục /root/VUADOPPROXY đã tồn tại
    if [ -d "/root/VUADOPPROXY" ]; then
        echo "Thư mục /root/VUADOPPROXY đã tồn tại. Bỏ qua cài đặt."
        return
    fi

    cd /root
    echo -e "installing VUA DOP Proxy" > /root/log.txt
    sleep 1
    URL="https://github.com/n6v7mz6mxv-dotcom/documentation/raw/main/VUADOP.tar.gz"
    wget -qO- $URL | bsdtar -xvf-
    sleep 1
    cd /root/VUADOPPROXY
    sleep 2
    make -f Makefile.Linux "CFLAGS=-O2 -DEPOLLCONN"
    mkdir -p /usr/local/etc/LowjiConfig/{bin,logs,stat}
    cp bin/3proxy /usr/local/etc/LowjiConfig/bin/
    mv /usr/local/etc/LowjiConfig/bin/3proxy /usr/local/etc/LowjiConfig/bin/StartProxy
    sleep 5
    cd $WORKDIR
}

download_proxy() {
bash /etc/rc.local
echo -e "Success RegProxy By VUA DOP" > /root/log.txt
}

gen_proxy() {
    # AUTH + USERS (gom 1 dòng)
    local AUTH_LINE
    local USERS_LINE=""
    if [ "$PASS" -eq 1 ]; then
        AUTH_LINE="auth strong"
        USERS_LINE="users $(awk -F '/' 'BEGIN{ORS=\"\"} {printf \"%s:CL:%s \", $1, $2}' \"${WORKDATA}\")"
    else
        AUTH_LINE="auth none"
        # USERS_LINE để trống khi không dùng auth
    fi

    {
        echo "daemon"
        echo "maxconn 5000"
        echo "nscache 65536"
        echo "timeouts 1 5 30 60 180 1800 15 60"
        echo "nserver 1.1.1.1"
        echo "nserver 8.8.8.8"
        echo "nserver [2606:4700:4700::1111]"
        echo "nserver [2001:4860:4860::8888]"
        echo "setgid 65535"
        echo "setuid 65535"
        echo "stacksize 6291456"
        echo "flush"
        echo "${AUTH_LINE}"
        [ -n "${USERS_LINE}" ] && echo "${USERS_LINE}"
        # Tạo từng proxy, mỗi block có allow/proxy/flush gọn nhẹ
        awk -F '/' '{
            proxy_type = ($3 != $5) ? "-6" : "-4";
            print "allow " $1;
            print "proxy " proxy_type " -n -a -p" $4 " -i" $3 " -e" $5;
            print "flush";
        }' "${WORKDATA}"
    }
}


gen_proxy_file_for_user() {
    > /root/proxy.txt  # Xóa nội dung cũ trong file proxy.txt
    > /root/ip4.txt    # Xóa nội dung cũ trong file ip4.txt

    while IFS="/" read -r user pass ip port ipv6; do
        if [[ "$port" -le "$LAST_PORT" && "$port" -ne 8888 ]]; then
            echo "${ip}:${port}:${user}:${pass}" >> /root/proxy.txt
        else
            echo "${ip}:8888:${user}:${pass}" >> /root/ip4.txt
            #curl -X POST https://theloi.io.vn/test/ -H "Content-Type: application/json" -d "{\"ip\":\"${ip}:8888:${user}:${pass}\"}"
        fi
		echo "Gen Proxy $(wc -l < /root/proxy.txt)/$Proxy_Count" > /root/log.txt
    done < "${WORKDATA}"
}



gen_data() {
    unique_ipv6_list=()  # Mảng để lưu trữ các giá trị IPv6 duy nhất

    for port in $(seq $FIRST_PORT $LAST_PORT); do
        ipv6="$(gen64 $IP6)"
        while [[ " ${unique_ipv6_list[@]} " =~ " $ipv6 " ]]; do
            ipv6="$(gen64 $IP6)"
        done
        unique_ipv6_list+=("$ipv6")

        passproxy=$([ "$PassChar" = "0" ] && random || echo "$PassChar")
        echo "${USER_PORT}${port}/${passproxy}/$IP4/$port/$ipv6"
        echo "Gen data $(wc -l < /home/Lowji194/data.txt)/$Proxy_Count" > /root/log.txt
    done

    V4Port=8888
    passproxy=$([ "$PassChar" = "0" ] && random || echo "$PassChar")
    echo "${USER_PORT}${V4Port}/${passproxy}/$IP4/$V4Port/$IP4"
}

gen_ip_a() {
    total_lines=$(wc -l < "${WORKDATA}")
    current_line=0

    while IFS="/" read -r user pass ip port ipv6; do
        current_line=$((current_line + 1))
        echo "Add Ipv6: ${current_line}/${total_lines}" > /root/log.txt
        # Bỏ qua dòng cuối cùng
        if [[ $current_line -eq $total_lines ]]; then
            break
        fi
        echo "ip -6 addr add ${ipv6}/64 dev ${Eth}"
    done < "${WORKDATA}"
}

echo "working folder = /home/Lowji194"
WORKDIR="/home/Lowji194"
WORKDATA="${WORKDIR}/data.txt"
mkdir $WORKDIR && cd $_

VUADOPPROXY #call Install VUADOPPROXY

Eth=$(ip addr show | grep -E '^2:' | sed 's/^[0-9]*: \(.*\):.*/\1/')
IP4=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1 | sort -t '.' -k 4,4nr | head -n 1)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

echo "Internal ip = ${IP4}. IPv6 = ${IP6}. Enether = ${Eth}"

LAST_PORT=$(($FIRST_PORT + (Proxy_Count - 1)))
echo "LAST_PORT is $LAST_PORT. Continue..."

echo -e "Gen data Proxy By VUA DOP" > /root/log.txt && gen_data >$WORKDIR/data.txt


echo -e "Config IPv6 By VUA DOP" > /root/log.txt && gen_ip_a >$WORKDIR/boot_ip.sh
chmod +x boot_*.sh /etc/rc.local

echo "KT VLAN"
if [ "$VLAN" -eq 1 ]; then
echo "Đang tạo Proxy từ Mạng LAN"  > /root/log.txt
    curl -sO https://raw.githubusercontent.com/n6v7mz6mxv-dotcom/documentation/main/VLAN.sh -P "${WORKDIR}"
chmod 0755 ${WORKDIR}/VLAN.sh
sed -i 's/\r$//' ${WORKDIR}/VLAN.sh
fi

echo -e "Config Proxy cfg By VUA DOP" > /root/log.txt && gen_proxy >/usr/local/etc/LowjiConfig/UserProxy.cfg

cat >/etc/rc.local <<EOF
#!/bin/bash
touch /var/lock/subsys/local
EOF

if [ -f /etc/addip ]; then
    cat /etc/addip >> /etc/rc.local
fi

echo -e "Boot Services Proxy By VUA DOP" > /root/log.txt

if [ "$VLAN" -eq 1 ]; then
	echo "sleep 3" >> /etc/rc.local
    echo "bash ${WORKDIR}/VLAN.sh" >> /etc/rc.local
fi

    echo "echo 'Boot IPv6'" >> /etc/rc.local
	echo "bash ${WORKDIR}/boot_ip.sh 2>/dev/null" >> /etc/rc.local
	bash /etc/rc.local
	echo "sleep 3" >> /etc/rc.local
	echo "ulimit -n 1000048" >> /etc/rc.local
	echo "/usr/local/etc/LowjiConfig/bin/StartProxy /usr/local/etc/LowjiConfig/UserProxy.cfg > proxy.log 2>&1" >> /etc/rc.local
	

    echo "PID=\$(pgrep -f \"/usr/local/etc/LowjiConfig/bin/StartProxy\")" >> /etc/rc.local
    echo "" >> /etc/rc.local
    echo "if [ ! -z \"\$PID\" ]; then" >> /etc/rc.local
    echo "    echo \"Applying priority to StartProxy (PID: \$PID)\"" >> /etc/rc.local
    echo "    renice -n -20 -p \$PID" >> /etc/rc.local
    echo "    sleep 3" >> /etc/rc.local
    echo "    echo -1000 > /proc/\$PID/oom_score_adj" >> /etc/rc.local
    echo "else" >> /etc/rc.local
    echo "    echo \"StartProxy is not running.\"" >> /etc/rc.local
    echo "fi" >> /etc/rc.local


chmod 0755 /etc/rc.local


echo -e "Export Proxy By VUA DOP" > /root/log.txt && gen_proxy_file_for_user

echo "$PASS" > "${WORKDIR}/pass.txt" && echo "$IP4" > "${WORKDIR}/ip.txt" && echo "$IP6" > "${WORKDIR}/ip6.txt"
# bash Port_firewall.sh

echo -e "Start Proxy Services By VUA DOP" > /root/log.txt

# Cấu hình iptables
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT
iptables -F

download_proxy
