#!/bin/bash
apt update && \
apt upgrade -y && \
apt install -y apt-transport-https curl && \
apt autoremove -y && \
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
cat <<EOF >/etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF
apt-get update
apt-get install -y kubelet kubeadm kubectl ipvsadm jq
kubeadm config images pull
