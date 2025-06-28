# 📬 MailServer Backup & Restore Tool

Một script shell đơn giản, mạnh mẽ để **backup và phục hồi** toàn bộ cấu hình mail server (Postfix, Dovecot, botmailserver.service) trên Linux.

## ⚙️ Chức năng chính

- 📦 Backup toàn bộ: `/etc/postfix`, `/etc/dovecot`, `/home/py`, và dịch vụ systemd botmailserver
- ♻️ Restore: chọn file backup, xác nhận trước khi phục hồi
- Giao diện dòng lệnh đẹp mắt, có màu và biểu tượng
- Tự động khởi động và enable các dịch vụ
- Ghi banner vào /etc/motd

## 📥 Cài đặt nhanh

```bash
cd /root
curl -L -o mailserver_backup_restore.sh https://raw.githubusercontent.com/lowji194/mailserver-tools/main/mailserver_backup_restore.sh
chmod +x mailserver_backup_restore.sh
sudo ./mailserver_backup_restore.sh
```

## 👨‍💻 Tác giả

- Nguyễn Thế Lợi
- 📞 0963 159 294
- 🌐 [Website](https://lowji194.github.io/)
- 📘 [Facebook](https://www.facebook.com/Lowji194/)
