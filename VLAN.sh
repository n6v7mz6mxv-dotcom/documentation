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
IP4=$(ip addr show "$Eth" | awk '/inet / {print $2}' | cut -d '/' -f 1)
IP6=$(ip addr show "$Eth" | grep 'inet6' | grep 'global' | awk '{print $2}' | awk -F ":" '{print $1":"$2":"$3":"$4}' | head -n 1)

gen_data() {
while IFS=":" read -r col1 col2 col3 col4; do
    unique_ipv6_list=()  # Mảng để lưu trữ các giá trị IPv6 duy nhất

    seq $FIRST_PORT $LAST_PORT | while read port; do
        ipv6="$(gen64 $IP6)"
        while [[ " ${unique_ipv6_list[@]} " =~ " $ipv6 " ]]; do
            ipv6="$(gen64 $IP6)"
        done
        unique_ipv6_list+=("$ipv6")

        echo "${col3}/${col4}/${col1}/${col2}/${ipv6}"
    done
done < /root/proxy.txt
}
gen_proxy() {
    cat <<EOF
daemon
maxconn 2000
nserver 1.1.1.1
nserver 8.8.4.4
nserver 2001:4860:4860::8888
nserver 2001:4860:4860::8844
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
setgid 65535
setuid 65535
stacksize 6291456 
flush
auth strong

users $(awk -F "/" 'BEGIN{ORS="";} {print $1 ":CL:" $2 " "}' ${WORKDATA})


$(awk -F "/" -v PASS="$PASS" '{
    auth = (PASS == 1 || $3 == $5) ? "strong" : "none";
    proxy_type = ($3 != $5) ? "-6" : "-4" ;
    print "auth " auth;
    print "allow  " $1;
    print "proxy " proxy_type " -n -a -p" $4 " -i" $3 " -e" $5;
    print "flush";
}' ${WORKDATA})
EOF
}

gen_ifconfig() {
    cat <<EOF
$(awk -F "/" -v Eth="${Eth}" '{print "ifconfig " Eth " inet6 add " $5 "/64"}' ${WORKDATA} | sed '$d')
EOF
}
gen_iptables() {
    cat <<EOF
    $(awk -F "/" '{print "iptables -I INPUT -p tcp --dport " $4 "  -m state --state NEW -j ACCEPT"}' ${WORKDATA}) 
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
gen_data > "${WORKDIR}/data.txt"
gen_ifconfig > "${WORKDIR}/boot_ifconfig.sh"
gen_iptables > "${WORKDIR}/boot_iptables.sh"
gen_proxy > "/usr/local/etc/LowjiConfig/UserProxy.cfg"
echo "$IP6" > "${WORKDIR}/ip6.txt"

if pgrep StartProxy >/dev/null; then
    echo "LowjiProxy đang chạy, khởi động lại..."
    /usr/bin/kill $(pgrep StartProxy)
fi

bash /home/Lowji194/boot_ifconfig.sh 2>/dev/null && ulimit -n 1000048 && /usr/local/etc/LowjiConfig/bin/StartProxy /usr/local/etc/LowjiConfig/UserProxy.cfg

fi
