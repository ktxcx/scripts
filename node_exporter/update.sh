#!/bin/bash

node_exporter_version=1.1.1

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

info "stopping node_exporter service"
systemctl stop node_exporter

info "Downloading Node Exporter Version "${node_exporter_version}
if [ ! -f "node_exporter.tar.gz" ]; then
    /usr/bin/curl -sLo node_exporter.tar.gz https://github.com/prometheus/node_exporter/releases/download/v${node_exporter_version}/node_exporter-${node_exporter_version}.${platform}-amd64.tar.gz
else
    warning "node_exporter Download File already exists. Try to delete it"
    rm node_exporter.tar.gz
    info "Success"
fi

info "Extracting Node Exporter Version "${node_exporter_version}
tar xfz node_exporter.tar.gz

info "Move Node Exporter to /usr/local/bin/"
mv node_exporter-${node_exporter_version}.${platform}-amd64/node_exporter /usr/local/bin/

info "Cleanup"
if [ -f "node_exporter.tar.gz" ]; then
    rm node_exporter.tar.gz
else
    warning "node_exporter.tar.gz doesn't exists. Can't delete file"
fi 

if [ -d "node_exporter-${node_exporter_version}.${platform}-amd64" ]; then
    rm -r node_exporter-${node_exporter_version}.${platform}-amd64
else
    warning "Directory node_exporter-${node_exporter_version}.${platform}-amd64 doens't exist. Can't delete folder"
fi 

info "starting node_exporter Service again"
systemctl start node_exporter
systemctl status node_exporter

info "Done..."
