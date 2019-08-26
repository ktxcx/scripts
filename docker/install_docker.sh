#!/bin/bash

linux_os=$(cat /etc/issue|cut -d" " -f1|head -1|awk '{print tolower($0)}')

docker_compose_ver=1.24.1

apt remove docker docker-engine docker.io -y
apt install gnupg apt-transport-https ca-certificates curl software-properties-common -y
curl -fsSL https://download.docker.com/linux/${linux_os}/gpg | apt-key add -
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/${linux_os} \
   $(lsb_release -cs) \
   stable"

apt update 
apt install docker-ce -y

#groupadd docker

cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

mkdir -p /etc/systemd/system/docker.service.d

# Restart docker.
systemctl daemon-reload
systemctl restart docker

curl -sL https://github.com/docker/compose/releases/download/${docker_compose_ver}/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
