#!/bin/sh
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

array=(1 2 3 4 5 6 7 8 9 0 a b c d e f)
gen64() {
	ip64() {
		echo "${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}${array[$RANDOM % 16]}"
	}
	echo "$1:$(ip64):$(ip64):$(ip64):$(ip64)"
}
Eth=$(ip addr show | grep -E '^2:' | sed 's/^[0-9]*: \(.*\):.*/\1/')
IP4=$(ip addr show | grep 'inet ' | awk '{print $2}' | cut -d '/' -f 1 | sort -t '.' -k 4,4nr | head -n 1)
IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')

# Lặp cho đến khi IP6 không còn trống
while [ -z "$IP6" ]; do
    # Restart network nếu IP6 trống
    if [ "$EUID" -ne 0 ]; then
        echo "Please run this script as root or with sudo."
        exit 1
    fi
    
    service network restart
    sleep 10 # Đợi 10 giây
    
    # Lấy IP6 sau khi khởi động lại mạng
    IP6=$(curl -6 -s icanhazip.com | cut -f1-4 -d':')
done

gen_data() {
	ipv6_list=()

    while IFS=":" read -r col1 col2 col3 col4; do
        ipv6="$(gen64 $IP6)"

        while [[ " ${ipv6_list[@]} " =~ " $ipv6 " ]]; do
            ipv6="$(gen64 $IP6)"
        done
        ipv6_list+=("$ipv6")

        echo "${col3}/${col4}/${col1}/${col2}/$ipv6"
    done < /root/proxy.txt
}
gen_proxy() {
    cat <<EOF
daemon
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844

$(awk -F "/" -v PASS="$PASS" '
{
    auth = (PASS == 1) ? "strong" : "none";
    proxy_type = ($3 != $5) ? "-6" : "-4";
    print "auth " auth;
    print "allow " $1;
    print "users " $1 ":CL:" $2;
    print "proxy " proxy_type " -n -a -p" $4 " -i" $3 " -e" $5;
    print "";
}' ${WORKDATA})
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" -v Eth="${Eth}" '{print "ifconfig " Eth " inet6 add " $5 "/64"}' ${WORKDATA} | sed '$d')
EOF
}


WORKDIR="/home/Lowji194"
WORKDATA="${WORKDIR}/data.txt"
# Kiểm tra xem file tồn tại hay không
if [ -e "${WORKDIR}/pass.txt" ]; then
    # Nếu file tồn tại, đọc giá trị từ file
    PASS=$(cat "${WORKDIR}/pass.txt")
else
    # Nếu file không tồn tại, gán giá trị mặc định là 1
    PASS=1
fi

if [ "$IP6" != "$(cat ${WORKDIR}/ip6.txt)" ]; then
    # Nếu khác nhau, thực hiện các thao tác dưới đây
    
echo "Gen Proxy"
gen_data >$WORKDIR/data.txt

echo "Config Proxy cfg"
gen_proxy >/usr/local/etc/LowjiConfig/UserProxy.cfg
echo "Config Proxy"
gen_ifconfig >$WORKDIR/boot_ifconfig.sh

echo "$IP6" > "${WORKDIR}/ip6.txt"


echo "Rotate IP Succces"
fi
