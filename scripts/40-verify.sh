#!/usr/bin/env bash
#
# Check the services from inside the VM and, when reachable, through the
# OpenStack load balancer. Pass --failover to delete one pod and watch the
# Deployment replace it.
#
set -euo pipefail

LB_VIP="${LB_VIP:-150.165.85.77}"
LB_PORTS="${LB_PORTS:-8600 8601 8602}"
A4_PORTS="${A4_PORTS:-8100 8101 8102}"
LOCAL_PORTS="8000 8001 8002"

show_health() {
  local url="$1"
  local body
  body="$(curl -fsS --max-time 5 "$url")" || {
    printf '%-45s %s\n' "$url" "unreachable"
    return
  }
  printf '%-45s %s\n' "$url" "$body"
}

echo "local endpoints"
for port in $LOCAL_PORTS; do
  show_health "http://127.0.0.1:${port}/health"
done

echo
echo "A5 load balancer endpoints"
for port in $LB_PORTS; do
  show_health "http://${LB_VIP}:${port}/health"
done

echo
echo "A4 endpoints (previous activity, informational)"
for port in $A4_PORTS; do
  show_health "http://${LB_VIP}:${port}/health"
done

echo
kubectl -n workloads get pods -o wide

if [ "${1:-}" = "--failover" ]; then
  pod="$(kubectl -n workloads get pods \
    -l app.kubernetes.io/name=cpu-workload \
    -o jsonpath='{.items[0].metadata.name}')"
  echo
  echo "deleting pod ${pod}"
  kubectl -n workloads delete pod "$pod"
  kubectl -n workloads rollout status deployment/cpu-workload --timeout=120s
  show_health "http://127.0.0.1:8000/health"
fi
