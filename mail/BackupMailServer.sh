#!/bin/bash

GREEN='\033[1;32m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
BLUE='\033[1;34m'
RESET='\033[0m'

# ===== ĐƯỜNG DẪN CƠ BẢN =====
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="$SCRIPT_DIR/backup_$DATE.tar.gz"
INCLUDES=(
    "/etc/postfix"
    "/etc/dovecot"
    "/home/py"
    "/etc/systemd/system/botmailserver.service"
)

function set_motd() {
cat << 'EOF' | sudo tee /etc/motd
####################################################################
#        _           _   _   _                                     #
#       | |         (_) | \ | |                                    #
#       | |     ___  _  |  \| | __ _ _   _ _   _  ___ _ __         #
#       | |    / _ \| | | . ` |/ _` | | | | | | |/ _ \ '_ \        #
#       | |___| (_) | | | |\  | (_| | |_| | |_| |  __/ | | |       #
#       |______\___/|_| |_| \_|\__, |\__,_|\__, |\___|_| |_|       #
#                               __/ |       __/ |                  #
#                              |___/       |___/                   #
####################################################################
#                                                                  #
# Website: https://lowji194.github.io/                             #
# Cảm ơn bạn đã sử dụng Dịch vụ MailServer                         #
# Nguyễn Thế Lợi                                                   #
# SĐT: 0963 159 294                                                #
# Facebook: https://www.facebook.com/Lowji194/                     #
#                                                                  #
####################################################################
EOF
}

# ===== PHÁT HIỆN OS =====
function detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# ===== CÀI ĐẶT POSTFIX & DOVECOT =====
function install_mail_services() {
    os_id=$(detect_os)
    echo -e "${BLUE}📦 Cài đặt postfix và dovecot cho: ${os_id}${RESET}"

    case "$os_id" in
        ubuntu|debian)
            apt update -y
            apt install -y postfix dovecot-core dovecot-imapd
            ;;
        centos|rhel|rocky|almalinux)
            if command -v dnf >/dev/null 2>&1; then
                dnf install -y postfix dovecot
            elif command -v yum >/dev/null 2>&1; then
                yum install -y postfix dovecot
            else
                echo -e "${RED}❌ Không tìm thấy dnf hoặc yum!${RESET}"
                exit 1
            fi
            ;;
        *)
            echo -e "${RED}❌ Không hỗ trợ OS này!${RESET}"
            exit 1
            ;;
    esac
}

# ===== BACKUP =====
function do_backup() {
    echo -e "${GREEN}🔄 Đang tạo backup...${RESET}"
    tar -czvf "$BACKUP_FILE" "${INCLUDES[@]}"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backup thành công: $BACKUP_FILE${RESET}"
    else
        echo -e "${RED}❌ Backup thất bại!${RESET}"
    fi
}

# ===== RESTORE =====
function do_restore() {
    echo -e "${YELLOW}🔍 Tìm file backup trong thư mục script...${RESET}"
    mapfile -t backup_files < <(find "$SCRIPT_DIR" -maxdepth 1 -type f -name "backup_*.tar.gz" | sort)

    if [ ${#backup_files[@]} -eq 0 ]; then
        echo -e "${RED}❌ Không tìm thấy file backup nào.${RESET}"
        exit 1
    fi

    echo -e "${BLUE}📦 Danh sách file backup tìm thấy:${RESET}"
    for i in "${!backup_files[@]}"; do
        printf "  [%s] %s\n" "$((i+1))" "$(basename "${backup_files[$i]}")"
    done

    read -p "👉 Nhập số (1-${#backup_files[@]}): " selected
    index=$((selected - 1))

    if [[ -z "${backup_files[$index]}" ]]; then
        echo -e "${RED}❌ Lựa chọn không hợp lệ.${RESET}"
        exit 1
    fi

    RESTORE_FILE="${backup_files[$index]}"
    echo -e "${YELLOW}⚠️ Bạn có muốn phục hồi từ: ${RESTORE_FILE}?${RESET}"
    read -p "Nhập Y để xác nhận: " confirm

    if [[ "$confirm" != "Y" && "$confirm" != "y" ]]; then
        echo -e "${RED}❌ Hủy phục hồi.${RESET}"
        exit 1
    fi

    install_mail_services

    echo -e "${GREEN}📂 Đang giải nén file backup...${RESET}"
    tar -xzvf "$RESTORE_FILE" -C /

    echo -e "${GREEN}✅ Phục hồi hoàn tất. Khởi động dịch vụ...${RESET}"
    systemctl daemon-reexec
    systemctl daemon-reload
    systemctl restart postfix dovecot botmailserver.service
    systemctl enable postfix dovecot botmailserver.service

    echo -e "${GREEN}✅ Dịch vụ đã sẵn sàng & tự khởi động khi reboot.${RESET}"
}

# ===== MENU =====
clear
set_motd

echo -e "${BLUE}"
echo "╔════════════════════════════════════════════╗"
echo "║          📬 MAILSERVER TOOL MENU           ║"
echo "╠════════════════════════════════════════════╣"
echo -e "║  ${GREEN}1.${RESET}${BLUE} 📦 Backup cấu hình & dữ liệu           ║"
echo -e "║  ${GREEN}2.${RESET}${BLUE} ♻️ Restore từ bản backup có sẵn        ║"
echo -e "║  ${GREEN}0.${RESET}${BLUE} 🔚 Thoát                               ║"
echo "╚════════════════════════════════════════════╝"
echo -e "${RESET}"

read -p "👉 Nhập lựa chọn (0/1/2): " choice

case $choice in
    1) do_backup ;;
    2) do_restore ;;
    0) echo -e "${YELLOW}👋 Thoát chương trình.${RESET}"; exit 0 ;;
    *) echo -e "${RED}❌ Lựa chọn không hợp lệ!${RESET}" ;;
esac
