#!/bin/bash

prometheus_version=2.10.0

os=$( uname )

if [ ${os} == 'Darwin' ]; then
    platform='darwin'
    esc='\x1B'
elif [ ${os} == 'Linux' ]; then
    platform='linux'
    esc='\e'
else
    echo "platform not supported"
    exit 1
fi

function info {
    echo -e "${esc}[32m[INFO] ${1}${esc}[39m"
}

function warning {
    echo -e "${esc}[33m[WARNING] ${1}${esc}[39m"
}

function fatal {
    echo -e "${esc}[91m[FATAL] ${1}${esc}[39m" >&2
    exit 2
}

function common {
info "Create prometheus folders"
mkdir -p /etc/prometheus
mkdir -p /var/lib/prometheus

info "Move Prometheus to /usr/local/bin/"
cp prometheus-${prometheus_version}.${platform}-amd64/prometheus /usr/local/bin/
cp prometheus-${prometheus_version}.${platform}-amd64/promtool /usr/local/bin/

info "Copy the consoles and console_libraries directories to /etc/prometheus"
cp -r prometheus-${prometheus_version}.${platform}-amd64/consoles /etc/prometheus/
cp -r prometheus-${prometheus_version}.${platform}-amd64/console_libraries /etc/prometheus/

permissions
}

function permissions {
info "Set the user and group ownership on the directories to the prometheus user"
chown prometheus:prometheus /usr/local/bin/prometheus
chown prometheus:prometheus /usr/local/bin/promtool
chown -R prometheus:prometheus /etc/prometheus/consoles
chown -R prometheus:prometheus /etc/prometheus/console_libraries
chown prometheus:prometheus /etc/prometheus/prometheus.yml
chown prometheus:prometheus /etc/prometheus
chown prometheus:prometheus /var/lib/prometheus
}

function download {
    info "Downloading Prometheus Version "${prometheus_version}
    if [ ! -f "prometheus.tar.gz" ]; then
        /usr/bin/curl -sLo prometheus.tar.gz https://github.com/prometheus/prometheus/releases/download/v${prometheus_version}/prometheus-${prometheus_version}.${platform}-amd64.tar.gz
    else 
        warning "prometheus Download File already exists. Try to delete it"
        rm prometheus.tar.gz
        info "Success"
    fi

    info "Extracting Prometheus Version "${prometheus_version}
    tar xfz prometheus.tar.gz
}

function setup {
info "Setting up prometheus User"
useradd --no-create-home --shell /bin/false prometheus

info "Create a sample config file"
if [ ! -f /etc/prometheus/prometheus.yml ];then
cat << EOF > /etc/prometheus/prometheus.yml
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    scrape_interval: 5s
    static_configs:
      - targets: ['localhost:9090']
EOF
else
warning "/etc/prometheus/prometheus.yml - won't touch it"
fi

info "Set up prometheus service"
if [ ! -f /etc/systemd/system/prometheus.service ];then
cat << EOF > /etc/systemd/system/prometheus.service
[Unit]
Description=Prometheus
Wants=network-online.target
After=network-online.target

[Service]
User=prometheus
Group=prometheus
Type=simple
ExecStart=/usr/local/bin/prometheus \
    --config.file /etc/prometheus/prometheus.yml \
    --storage.tsdb.path /var/lib/prometheus/ \
    --web.console.templates=/etc/prometheus/consoles \
    --web.console.libraries=/etc/prometheus/console_libraries

[Install]
WantedBy=multi-user.target
EOF
else
warning "/etc/systemd/system/prometheus.service exists - won't touch it"
fi
}

function cleanup {
    info "Cleanup"
    if [ -f "prometheus.tar.gz" ]; then
        rm prometheus.tar.gz
    else
        warning "prometheus.tar.gz doesn't exists. Can't delete file"
    fi 

    if [ -d "prometheus-${prometheus_version}.${platform}-amd64" ]; then
        rm -r prometheus-${prometheus_version}.${platform}-amd64
    else
        warning "Directory prometheus-${prometheus_version}.${platform}-amd64 doesn't exists. Can't delete folder"
    fi 
}


function update {
systemctl stop prometheus
download
common

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus
cleanup
}

function install {
download
common
setup

systemctl daemon-reload
systemctl enable prometheus
systemctl start prometheus
systemctl status prometheus
cleanup
}

if [ ! -f /etc/systemd/system/prometheus.service ]; then
	info "Install prometheus"
	 cd /tmp
	install
else
	info "Update prometheus"
	cd /tmp
	update
fi
