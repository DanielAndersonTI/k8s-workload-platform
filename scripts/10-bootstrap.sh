#!/usr/bin/env bash
#
# Prepare an Ubuntu VM to run Minikube with the Docker driver.
#
# Run with sudo from the repository root. The script installs Docker, kubectl
# and minikube, adds the invoking user to the docker group and disables swap.
#
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
  echo "run this script with sudo" >&2
  exit 1
fi

TARGET_USER="${SUDO_USER:-root}"
ARCH="$(uname -m)"
case "$ARCH" in
  x86_64) K8S_ARCH=amd64 ;;
  aarch64 | arm64) K8S_ARCH=arm64 ;;
  *)
    echo "unsupported architecture: $ARCH" >&2
    exit 1
    ;;
esac

apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y \
  ca-certificates \
  conntrack \
  curl \
  docker.io

systemctl enable --now docker

if [ "$TARGET_USER" != "root" ]; then
  usermod -aG docker "$TARGET_USER"
fi

KUBECTL_VERSION="${KUBECTL_VERSION:-v1.37.2}"
MINIKUBE_VERSION="${MINIKUBE_VERSION:-v1.39.0}"
curl -fsSLo /tmp/kubectl \
  "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${K8S_ARCH}/kubectl"
install -m 0755 /tmp/kubectl /usr/local/bin/kubectl
rm -f /tmp/kubectl

curl -fsSLo /tmp/minikube \
  "https://storage.googleapis.com/minikube/releases/download/${MINIKUBE_VERSION}/minikube-linux-${K8S_ARCH}"
install -m 0755 /tmp/minikube /usr/local/bin/minikube
rm -f /tmp/minikube

swapoff -a || true
if grep -Eq '^[^#].*[[:space:]]swap[[:space:]]' /etc/fstab; then
  sed -ri '/[[:space:]]swap[[:space:]]/ s/^([^#])/#\1/' /etc/fstab
fi

echo
docker --version
kubectl version --client
minikube version

echo
echo "group membership changed. open a new shell or run: newgrp docker"
echo "then run scripts/20-cluster.sh as ${TARGET_USER}"
