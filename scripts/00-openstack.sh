#!/usr/bin/env bash
#
# Create the A5 key pair, security group and Ubuntu VM.
#
# Run this from the access VDI, with the OpenStack CLI configured. The script
# is idempotent for the key pair and the security group, and refuses to create
# a second VM with the same name.
#
set -euo pipefail

VM_NAME="${VM_NAME:-vm-atividade5-k8s}"
FLAVOR="${FLAVOR:-general.large}"
IMAGE="${IMAGE:-ubuntu-24.04}"
KEYPAIR="${KEYPAIR:-atividade5}"
KEY_PATH="${KEY_PATH:-$HOME/.ssh/atividade5}"
SECGROUP="${SECGROUP:-sg-atividade5}"
NETWORK="${NETWORK:-provider}"
SG_REMOTE_CIDR="${SG_REMOTE_CIDR:-10.5.8.0/22}"

for command in openstack ssh-keygen; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "missing command: $command" >&2
    exit 1
  }
done

if openstack keypair show "$KEYPAIR" >/dev/null 2>&1; then
  echo "keypair already exists: $KEYPAIR"
  if [ ! -f "$KEY_PATH" ]; then
    echo "private key not found at ${KEY_PATH}; set KEY_PATH to the matching key" >&2
    exit 1
  fi
else
  if [ ! -f "$KEY_PATH" ]; then
    umask 077
    ssh-keygen -t rsa -b 2048 -N '' -f "$KEY_PATH"
  fi
  if [ ! -f "${KEY_PATH}.pub" ]; then
    ssh-keygen -y -f "$KEY_PATH" > "${KEY_PATH}.pub"
  fi
  openstack keypair create --public-key "${KEY_PATH}.pub" "$KEYPAIR"
fi

if ! openstack security group show "$SECGROUP" >/dev/null 2>&1; then
  openstack security group create "$SECGROUP" \
    --description "A5 Kubernetes access from the load balancer"
  openstack security group rule create \
    --protocol tcp --dst-port 22:22 --remote-ip "$SG_REMOTE_CIDR" "$SECGROUP"
  openstack security group rule create \
    --protocol tcp --dst-port 8000:8002 --remote-ip "$SG_REMOTE_CIDR" "$SECGROUP"
  openstack security group rule create \
    --protocol icmp --remote-ip "$SG_REMOTE_CIDR" "$SECGROUP"
else
  echo "security group already exists: $SECGROUP"
fi

openstack flavor show "$FLAVOR" >/dev/null
openstack image show "$IMAGE" >/dev/null
openstack network show "$NETWORK" >/dev/null

if openstack server show "$VM_NAME" >/dev/null 2>&1; then
  echo "server already exists: $VM_NAME" >&2
  echo "delete it first or choose another VM_NAME" >&2
  exit 1
fi

openstack server create \
  --flavor "$FLAVOR" \
  --image "$IMAGE" \
  --key-name "$KEYPAIR" \
  --network "$NETWORK" \
  --security-group "$SECGROUP" \
  --wait \
  "$VM_NAME"

echo
echo "server id and addresses:"
openstack server show "$VM_NAME" -f value -c id -c addresses

echo
echo "next steps:"
echo "  1. connect over SSH with ${KEY_PATH}"
echo "  2. clone the repository on the VM"
echo "  3. run scripts/10-bootstrap.sh with sudo"
