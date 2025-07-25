# Update the package list and upgrade all packages
echo "Updating package list and upgrading packages..."
apt update && apt upgrade -y
apt install -y ufw redis-server ffmpeg wget

echo "fs.file-max = 1048576" >> /etc/sysctl.conf
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=4096" >> /etc/sysctl.conf
echo "* soft nofile 1048576" >> /etc/security/limits.conf
echo "* hard nofile 1048576" >> /etc/security/limits.conf
echo "DefaultLimitNOFILE=102456:524288" >> /etc/systemd/system.conf
sysctl -p


# Append new tmpfs entries to /etc/fstab
mkdir -p /home/o11
cd /home/o11
mkdir -p /mnt/hls
mkdir -p /mnt/dl
ln -sf /mnt/dl
ln -sf /mnt/hls

wget https://github.com/leduong/o11/raw/refs/heads/main/lic.cr
wget https://github.com/leduong/o11/raw/refs/heads/main/server
wget https://github.com/leduong/o11/raw/refs/heads/main/o11
wget https://github.com/leduong/o11/raw/refs/heads/main/o11.sh
chmod +x server o11 o11.sh


cat <<EOL >> /etc/fstab

tmpfs /mnt/hls tmpfs defaults,noatime,nosuid,nodev,noexec,mode=1777,size=70% 0 0
tmpfs /mnt/dl tmpfs defaults,noatime,nosuid,nodev,noexec,mode=1777,size=70% 0 0
EOL

cat <<EOL >> /etc/systemd/system/o11.service
[Unit]
Description=Auto-start O11 Streammer
After=network.target

[Service]
ExecStart=/home/o11/run.sh
WorkingDirectory=/home/o11/
Restart=always
User=root
StandardOutput=append:/var/log/o11.log
StandardError=append:/var/log/o11.log

[Install]
WantedBy=multi-user.target
EOL

cat <<EOL >> /etc/systemd/system/server.service
[Unit]
Description=Auto-start O11 Server
After=network.target

[Service]
ExecStart=/home/o11/server
WorkingDirectory=/home/o11/
Restart=always
User=root
StandardOutput=append:/var/log/server.log
StandardError=append:/var/log/server.log

[Install]
WantedBy=multi-user.target
EOL

systemctl daemon-reload
systemctl enable server.service
systemctl start server.service
systemctl enable o11.service
systemctl start o11.service

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8283/tcp
ufw enable
