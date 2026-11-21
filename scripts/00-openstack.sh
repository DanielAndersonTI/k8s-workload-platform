#!/usr/bin/env bash
#
# Create the Ubuntu VM that hosts the Minikube cluster.
#
# Run this from a machine with the OpenStack CLI configured. Every value can be
# overridden through the environment.
#
set -euo pipefail

VM_NAME="${VM_NAME:-workload-platform}"
FLAVOR="${FLAVOR:-general.large}"
IMAGE="${IMAGE:-ubuntu-24.04}"
KEYPAIR="${KEYPAIR:?set KEYPAIR to the name of an existing key pair}"
NETWORK="${NETWORK:-provider}"
SECGROUP="${SECGROUP:-default}"

for command in openstack; do
  command -v "$command" >/dev/null 2>&1 || {
    echo "missing command: $command" >&2
    exit 1
  }
done

openstack flavor show "$FLAVOR" >/dev/null
openstack image show "$IMAGE" >/dev/null
openstack keypair show "$KEYPAIR" >/dev/null
openstack network show "$NETWORK" >/dev/null

if openstack server show "$VM_NAME" >/dev/null 2>&1; then
  echo "server already exists: $VM_NAME" >&2
  echo "delete it first or choose another VM_NAME" >&2
  exit 1
fi

if ! openstack security group show "$SECGROUP" >/dev/null 2>&1; then
  echo "security group not found: $SECGROUP" >&2
  echo "create it with inbound rules for TCP 22 and TCP 8000-8002" >&2
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
echo "  1. confirm that the security group allows TCP 22 and TCP 8000-8002"
echo "  2. connect over SSH and clone the repository"
echo "  3. run scripts/10-bootstrap.sh with sudo"
