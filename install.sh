# Update the package list and upgrade all packages
echo "Updating package list and upgrading packages..."
# apt update && apt upgrade -y
apt install -y ufw redis-server ffmpeg wget python3-pip

echo "fs.file-max = 1048576" >> /etc/sysctl.conf
echo "net.core.somaxconn=65535" >> /etc/sysctl.conf
echo "net.ipv4.tcp_max_syn_backlog=4096" >> /etc/sysctl.conf
echo "o11 soft nofile 1048576" >> /etc/security/limits.conf
echo "o11 hard nofile 1048576" >> /etc/security/limits.conf
echo "DefaultLimitNOFILE=204890:524288" >> /etc/systemd/system.conf
sysctl -p

# Create a new user for running the application
echo "Creating user 'o11'..."
adduser --disabled-password --shell /bin/bash --gecos "Over-the-Top" o11
su - o11 -c "pip3 install --user --break-system-packages curl_cffi redis pywidevine pytz"

wget https://github.com/leduong/o11/raw/refs/heads/main/lic.cr -O /home/o11/lic.cr
wget https://github.com/leduong/o11/raw/refs/heads/main/server -O /home/o11/server
wget https://github.com/leduong/o11/raw/refs/heads/main/o11 -O /home/o11/o11
wget https://github.com/leduong/o11/raw/refs/heads/main/o11.cfg -O /home/o11/o11.cfg
wget https://github.com/leduong/o11/raw/refs/heads/main/run.sh -O /home/o11/run.sh
chmod +x /home/o11/server /home/o11/o11 /home/o11/run.sh

# Append new tmpfs entries to /etc/fstab
mkdir -p /mnt/hls
mkdir -p /mnt/dl
ln -sf /mnt/dl /home/o11/dl
ln -sf /mnt/hls /home/o11/hls

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
User=o11
StandardOutput=append:/home/o11/o11.log
StandardError=append:/home/o11/o11.log

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
systemctl enable --now server.service
systemctl enable --now o11.service

ufw allow 22/tcp
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow 8283/tcp


# Get the server's public IPv4 address
PUBLIC_IP=$(curl -4 -s ifconfig.me)

echo "Setup finished! Please reboot the system to apply all changes."
echo "After reboot, you can check the status of the services using:"
echo "  sudo systemctl status o11.service"
echo "  sudo systemctl status server.service"
echo "You can view the logs using:"
echo "  tail -f /home/o11/o11.log"
echo "  tail -f /var/log/server.log"
echo "Access the web interface at http://$PUBLIC_IP:8283 with username 'admin' and password '1'."

# Fix permission issues
chown -R o11:o11 /home/o11
chown -R o11:o11 /mnt/hls
chown -R o11:o11 /mnt/dl
