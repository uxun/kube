#!/bin/bash
# This script describes where to download the official released binaries needed 

# example releases
#===================version 1.13
#K8S_VER=v1.13.7
#ETCD_VER=v3.2.24
#DOCKER_VER=18.06.3-ce
#CNI_VER=v0.6.0
#DOCKER_COMPOSE=1.23.0
#HARBOR=v1.7.4

#==================version 1.14
K8S_VER=v1.14.3
ETCD_VER=v3.3.10
DOCKER_VER=18.09.6
CNI_VERS=v0.7.5
DOCKER_COMPOSE=1.23.2
HARBOR=v1.5.3

echo -e "\nNote1: Before this script, please finish downloading binaries manually from following urls."
echo -e "\nNote2：If binaries are not ready, use "Ctrl + C" to stop this script."

echo -e "\n----download k8s binary at:"
echo https://dl.k8s.io/${K8S_VER}/kubernetes-server-linux-amd64.tar.gz

echo -e "\n----download etcd binary at:"
echo https://github.com/coreos/etcd/releases/download/${ETCD_VER}/etcd-${ETCD_VER}-linux-amd64.tar.gz

echo -e "\n----download docker binary at:"
echo https://download.docker.com/linux/static/stable/x86_64/docker-${DOCKER_VER}.tgz

echo -e "\n----download ca tools at:"
echo https://pkg.cfssl.org/R1.2/cfssl_linux-amd64
echo https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64
echo https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64

echo -e "\n----download docker-compose at:"
echo https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-Linux-x86_64

echo -e "\n----download harbor-offline-installer at:"
echo https://storage.googleapis.com/harbor-releases/release-1.7.0/harbor-offline-installer-${HARBOR}.tgz

echo -e "\n----download cni plugins at:"
echo https://github.com/containernetworking/plugins/releases/download/${CNI_VER}/cni-${CNI_VER}.tgz

echo -e "\n----download cni plugins > version 0.6.0 at:"
echo https://github.com/containernetworking/plugins/releases/download/${CNI_VERS}/cni-plugins-amd64-${CNI_VERS}.tgz

sleep 20

### prepare 'move docker-compose'
echo -e "\nMoving 'docker-compose' to 'bin' dir..."
if [ -f "docker-compose-Linux-x86_64" ]; then
  mv -f docker-compose-Linux-x86_64 ../bin/docker-compose
else
  echo Please download 'docker-compose-Linux-x86_64' at 'https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE}/docker-compose-Linux-x86_64'
fi

### prepare 'cfssl' cert tool suit
echo -e "\nMoving 'cfssl' to 'bin' dir..."
if [ -f "cfssl_linux-amd64" ]; then
  mv -f cfssl_linux-amd64 ../bin/cfssl
else
  echo Please download 'cfssl' at 'https://pkg.cfssl.org/R1.2/cfssl_linux-amd64'
fi
if [ -f "cfssljson_linux-amd64" ]; then
  mv -f cfssljson_linux-amd64 ../bin/cfssljson
else
  echo Please download 'cfssljson' at 'https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64'
fi
if [ -f "cfssl-certinfo_linux-amd64" ]; then
  mv -f cfssl-certinfo_linux-amd64 ../bin/cfssl-certinfo
else
  echo Please download 'cfssl-certinfo' at 'https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64'
fi

### prepare 'etcd' binaries
if [ -f "etcd-${ETCD_VER}-linux-amd64.tar.gz" ]; then
  echo -e "\nextracting etcd binaries..."
  tar zxf etcd-${ETCD_VER}-linux-amd64.tar.gz
  mv -f etcd-${ETCD_VER}-linux-amd64/etcd* ../bin
else
  echo Please download 'etcd-${ETCD_VER}-linux-amd64.tar.gz' first
fi

### prepare kubernetes binaries
if [ -f "kubernetes-server-linux-amd64.tar.gz" ]; then
  echo -e "\nextracting kubernetes binaries..."
  tar zxf kubernetes-server-linux-amd64.tar.gz
  mv -f kubernetes/server/bin/kube-apiserver ../bin
  mv -f kubernetes/server/bin/kube-controller-manager ../bin
  mv -f kubernetes/server/bin/kubectl ../bin
  mv -f kubernetes/server/bin/kubelet ../bin
  mv -f kubernetes/server/bin/kube-proxy ../bin
  mv -f kubernetes/server/bin/kube-scheduler ../bin
else
  echo Please download 'kubernetes-server-linux-amd64.tar.gz' first
fi

### prepare docker binaries
if [ -f "docker-${DOCKER_VER}.tgz" ]; then
  echo -e "\nextracting docker binaries..."
  tar zxf docker-${DOCKER_VER}.tgz
  mv -f docker/* ../bin
  if [ -f "docker/completion/bash/docker" ]; then
    mv -f docker/completion/bash/docker ../roles/docker/files/docker
  fi
else
  echo Please download 'docker-${DOCKER_VER}.tgz' first 
fi

### prepare cni plugins, needed by flannel;
if [ -f "cni-${CNI_VER}.tgz" ]; then
  echo -e "\nextracting cni plugins binaries..."
  tar zxf cni-${CNI_VER}.tgz
  mv -f bridge ../bin
  mv -f flannel ../bin
  mv -f host-local ../bin
  mv -f loopback ../bin
  mv -f portmap ../bin
else
  echo Please download 'cni-${CNI_VER}.tgz' first 
fi
### prepare cni plugins > version 0.6.0, needed by flannel;
if [ -f "cni-plugins-amd64-${CNI_VERS}.tgz" ]; then
  echo -e "\nextracting cni plugins version > 0.6.0binaries..."
  tar zxf cni-plugins-amd64-${CNI_VERS}.tgz
  mv -f bridge ../bin
  mv -f flannel ../bin
  mv -f host-local ../bin
  mv -f loopback ../bin
  mv -f portmap ../bin
else
  echo Please download 'cni-plugins-amd64-${CNI_VERS}.tgz' first 
fi
