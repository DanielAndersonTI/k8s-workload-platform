#!/usr/bin/env bash
#
# Start the single-node Minikube cluster and publish the three host ports.
#
# Run as a regular user that belongs to the docker group. The cluster is sized
# below the VM so the operating system and the Docker daemon keep headroom.
#
set -euo pipefail

if [ "$(id -u)" -eq 0 ]; then
  echo "run this script as the regular user, not with sudo" >&2
  exit 1
fi

if ! docker info >/dev/null 2>&1; then
  echo "docker is not reachable. open a new shell or run: newgrp docker" >&2
  exit 1
fi

MINIKUBE_CPUS="${MINIKUBE_CPUS:-3}"
MINIKUBE_MEMORY="${MINIKUBE_MEMORY:-6144}"
MINIKUBE_PORTS="${MINIKUBE_PORTS:-8000:30080,8001:30081,8002:30082}"
K8S_VERSION="${K8S_VERSION:-v1.37.0}"

minikube start \
  --driver=docker \
  --cpus="$MINIKUBE_CPUS" \
  --memory="$MINIKUBE_MEMORY" \
  --ports="$MINIKUBE_PORTS" \
  --kubernetes-version="$K8S_VERSION"

# minikube v1.39.0 with the Docker driver applies --memory as a cgroup limit
# but does not create a CPU quota from --cpus. Apply the intended CPU limit
# explicitly and fail if the quota is still absent.
docker update --cpus="$MINIKUBE_CPUS" minikube >/dev/null
if [ "$(docker inspect minikube --format '{{.HostConfig.CpuQuota}}')" = "0" ]; then
  echo "CPU limit was not applied to the minikube container" >&2
  exit 1
fi

minikube addons enable metrics-server

echo
kubectl get nodes -o wide

echo
echo "published ports:"
docker port minikube || true
ss -ltn | grep -E ':(8000|8001|8002)[[:space:]]' || true

echo
echo "next step: run scripts/30-deploy.sh"
