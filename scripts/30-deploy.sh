#!/usr/bin/env bash
#
# Apply the Kubernetes manifests and wait for the three rollouts.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

kubectl apply -k k8s/

for deployment in cpu-workload memory-workload io-workload; do
  kubectl -n workloads rollout status "deployment/${deployment}" --timeout=180s
done

echo
kubectl -n workloads get deployments,pods,services -o wide

echo
kubectl -n workloads get endpoints

echo
echo "next step: run scripts/40-verify.sh"
