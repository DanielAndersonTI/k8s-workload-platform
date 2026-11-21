#!/usr/bin/env bash
#
# Point the existing Octavia pools at the new VM, preserving listeners, pools,
# health monitors and external ports.
#
# Run from a machine with the OpenStack CLI configured. The script discovers
# each pool through the listener port instead of relying on resource names.
#
set -euo pipefail

VM_NAME="${VM_NAME:-workload-platform}"
VM_IP="${VM_IP:-}"
SUBNET_ID="${SUBNET_ID:-}"

if [ -z "$VM_IP" ]; then
  VM_IP="$(openstack server show "$VM_NAME" -f value -c addresses \
    | tr ',' '\n' | sed -n 's/.*=//p' | head -n1)"
fi

if [ -z "$VM_IP" ]; then
  echo "could not determine the address of ${VM_NAME}" >&2
  exit 1
fi

listener_for_port() {
  openstack loadbalancer listener list -f value -c id -c protocol_port \
    | awk -v port="$1" '$2 == port { print $1; exit }'
}

update_pool() {
  local listener_port="$1"
  local target_port="$2"
  local label="$3"
  local listener_id pool_id member_id

  listener_id="$(listener_for_port "$listener_port")"
  if [ -z "$listener_id" ]; then
    echo "no listener on port ${listener_port}; skipped ${label}" >&2
    return
  fi

  pool_id="$(openstack loadbalancer listener show "$listener_id" \
    -f value -c default_pool_id)"
  if [ -z "$pool_id" ]; then
    echo "listener ${listener_id} has no default pool; skipped ${label}" >&2
    return
  fi

  member_id="$(openstack loadbalancer member list "$pool_id" \
    -f value -c id | head -n1)"

  if [ -n "$member_id" ]; then
    openstack loadbalancer member set "$pool_id" "$member_id" \
      --name "$VM_NAME" \
      --address "$VM_IP" \
      --protocol-port "$target_port"
  else
    if [ -z "$SUBNET_ID" ]; then
      echo "pool ${pool_id} is empty; export SUBNET_ID to create a member" >&2
      return 1
    fi
    openstack loadbalancer member create "$pool_id" \
      --name "$VM_NAME" \
      --address "$VM_IP" \
      --protocol-port "$target_port" \
      --subnet-id "$SUBNET_ID"
  fi

  echo "pool ${pool_id}: ${VM_IP}:${target_port} (${label})"
}

update_pool 8100 8000 cpu
update_pool 8101 8001 memory
update_pool 8102 8002 io

if [ -n "$(listener_for_port 2222)" ]; then
  update_pool 2222 22 ssh
else
  echo "no SSH listener on port 2222; skipped ssh" >&2
fi

echo
echo "waiting for the load balancer to converge"
sleep 20

for listener_port in 8100 8101 8102; do
  listener_id="$(listener_for_port "$listener_port")"
  [ -n "$listener_id" ] || continue
  pool_id="$(openstack loadbalancer listener show "$listener_id" \
    -f value -c default_pool_id)"
  openstack loadbalancer member list "$pool_id" \
    -f value -c name -c address -c protocol_port -c operating_status
done
