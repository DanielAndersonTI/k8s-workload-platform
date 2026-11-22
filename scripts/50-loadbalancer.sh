#!/usr/bin/env bash
#
# Create the A5 listeners on the shared poi-atividades load balancer.
#
# The A4 listeners on ports 8100 to 8102 and 2222 are not touched. This script
# creates new listeners, pools, health monitors and members on ports 8600 to
# 8602 and 2223 for the Kubernetes VM.
#
# The load balancer is shared by the whole class and its name is not unique, so
# the script resolves the active instance and targets it by ID. Port 8201, used
# in an earlier draft, belongs to another group.
set -euo pipefail

VM_NAME="${VM_NAME:-vm-atividade5-k8s}"
LB_NAME="${LB_NAME:-poi-atividades}"
LB_ID="${LB_ID:-}"
SUBNET_ID="${SUBNET_ID:-}"
VM_IP="${VM_IP:-}"

if [ -z "$LB_ID" ]; then
  LB_ID="$(openstack loadbalancer list -f value \
    -c id -c name -c provisioning_status \
    | awk -v n="$LB_NAME" '$2 == n && $3 == "ACTIVE" { print $1; exit }')"
fi

if [ -z "$LB_ID" ]; then
  echo "could not find an ACTIVE load balancer named ${LB_NAME}" >&2
  exit 1
fi

if [ -z "$VM_IP" ]; then
  VM_IP="$(openstack server show "$VM_NAME" -f value -c addresses \
    | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -n1)"
fi

if [ -z "$VM_IP" ]; then
  echo "could not determine the address of ${VM_NAME}" >&2
  exit 1
fi

if [ -z "$SUBNET_ID" ]; then
  echo "set SUBNET_ID to the subnet of ${VM_NAME}" >&2
  exit 1
fi

listener_exists() {
  openstack loadbalancer listener show "$1" >/dev/null 2>&1
}

port_in_use() {
  openstack loadbalancer listener list -f value -c protocol_port \
    | grep -qx "$1"
}

create_app_listener() {
  local profile="$1"
  local external_port="$2"
  local target_port="$3"
  local listener="app-${profile}-atividade5"
  local pool="pool-app-${profile}-atividade5"
  local monitor="hm-app-${profile}-atividade5"

  if listener_exists "$listener"; then
    echo "listener already exists: ${listener}"
    return 0
  fi
  if port_in_use "$external_port"; then
    echo "port ${external_port} is already used by another listener" >&2
    return 1
  fi

  openstack loadbalancer listener create \
    --name "$listener" \
    --protocol HTTP \
    --protocol-port "$external_port" \
    "$LB_ID" --wait

  openstack loadbalancer pool create \
    --name "$pool" \
    --lb-algorithm ROUND_ROBIN \
    --listener "$listener" \
    --protocol HTTP --wait

  openstack loadbalancer healthmonitor create \
    --name "$monitor" \
    --delay 5 \
    --timeout 4 \
    --max-retries 3 \
    --type HTTP \
    --url-path /health \
    --expected-codes 200 \
    "$pool" --wait

  openstack loadbalancer member create \
    --name "$VM_NAME" \
    --subnet-id "$SUBNET_ID" \
    --address "$VM_IP" \
    --protocol-port "$target_port" \
    "$pool" --wait

  echo "created ${listener}: ${external_port} -> ${VM_IP}:${target_port}"
}

if [ "${SSH_ONLY:-0}" = "1" ]; then
  echo "SSH_ONLY=1: skipping the application listeners"
else
  create_app_listener cpu 8600 8000
  create_app_listener memory 8601 8001
  create_app_listener io 8602 8002
fi

if listener_exists "ssh-atividade5"; then
  echo "ssh listener already exists: ssh-atividade5"
else
  if port_in_use 2223; then
    echo "port 2223 is already used by another listener" >&2
    exit 1
  fi

  openstack loadbalancer listener create \
    --name ssh-atividade5 \
    --protocol TCP \
    --protocol-port 2223 \
    "$LB_ID" --wait

  openstack loadbalancer pool create \
    --name pool-ssh-atividade5 \
    --lb-algorithm ROUND_ROBIN \
    --listener ssh-atividade5 \
    --protocol TCP --wait

  openstack loadbalancer healthmonitor create \
    --name hm-ssh-atividade5 \
    --delay 5 \
    --timeout 4 \
    --max-retries 3 \
    --type TCP \
    pool-ssh-atividade5 --wait

  openstack loadbalancer member create \
    --name "$VM_NAME" \
    --subnet-id "$SUBNET_ID" \
    --address "$VM_IP" \
    --protocol-port 22 \
    pool-ssh-atividade5 --wait

  echo "created ssh-atividade5: 2223 -> ${VM_IP}:22"
fi

echo
echo "waiting for the load balancer to converge"
sleep 20

for port in 8600 8601 8602 2223; do
  listener_id="$(openstack loadbalancer listener list -f value \
    -c id -c protocol_port | awk -v p="$port" '$2 == p { print $1; exit }')"
  [ -n "$listener_id" ] || continue
  pool_id="$(openstack loadbalancer listener show "$listener_id" \
    -f value -c default_pool_id)"
  echo
  echo "== listener port ${port} / pool ${pool_id}"
  openstack loadbalancer member list "$pool_id" -f value \
    -c name -c address -c protocol_port -c operating_status
done

echo
echo "A4 listeners preserved:"
openstack loadbalancer listener list -f value -c name -c protocol_port \
  | awk '$2 == 8100 || $2 == 8101 || $2 == 8102 || $2 == 2222'
