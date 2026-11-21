# k8s-workload-platform

Three HTTP services with distinct resource profiles, packaged as containers and
scheduled by Kubernetes on a single-node Minikube cluster. An OpenStack Octavia
load balancer publishes the services externally on fixed ports.

The services expose the same contract: `GET /health`, `GET /work?size=N`, and
`GET /metrics`. The first is used by Kubernetes probes and by the load balancer
health monitor, the second generates the workload, and the third returns process
counters.

## Architecture

```text
client
  |  HTTP 8100 / 8101 / 8102
  v
OpenStack Octavia (poi-atividades)
  |  TCP 8000 / 8001 / 8002
  v
Ubuntu VM, 4 vCPU and 8 GB RAM
  |
  +-- Docker
       |
       +-- minikube node
            |  NodePort 30080 / 30081 / 30082
            v
           Deployments, 2 replicas each
```

The load balancer and its listeners are inherited infrastructure. The cluster
only has to answer on the same host ports used by the previous deployment
model, so the external contract does not change.

## Workloads

| Service | Image | Behavior | NodePort | External port |
| --- | --- | --- | --- | --- |
| CPU | `danielandersonss/poi-cpu:1.0.0` | Iterated SHA-256 over a buffer | 30080 | 8100 |
| Memory | `danielandersonss/poi-memory:1.0.0` | Allocates and touches `size` MiB | 30081 | 8101 |
| I/O | `danielandersonss/poi-io:1.0.0` | Writes and reads a scratch file | 30082 | 8102 |

`size` is interpreted in iterations for CPU, MiB for memory, and KiB for I/O.
Each service validates its own range and returns `400` outside it.

## Kubernetes configuration

| Decision | Choice | Reason |
| --- | --- | --- |
| Workload object | `Deployment` | Stateless HTTP processes with no stable identity or per-pod storage requirement |
| Replicas | 2 | Removes the single point of failure inside the cluster and makes rolling updates possible |
| Update strategy | `RollingUpdate`, `maxUnavailable: 0` | A new pod must become ready before an old one is removed |
| Service type | `NodePort` | Minikube does not provide a cloud controller; fixed node ports map cleanly to host ports |
| Node ports | 30080 to 30082 | Inside the default range and stable across recreations |
| Probes | startup, readiness, liveness on `/health` | Readiness controls traffic; liveness restarts a stuck process; startup protects slow boots |
| Requests | 250m/128Mi to 250m/512Mi | Guarantees scheduling headroom on a 3 CPU node |
| Limits | 1 CPU/512Mi to 1 CPU/1536Mi | Caps the blast radius of a workload that allocates more than expected |
| Security context | UID/GID 10001, no privilege escalation, read-only root, all capabilities dropped, `RuntimeDefault` seccomp | The application needs no privilege and no writable layer |
| Writable path | `emptyDir` at `/tmp` | The I/O service writes scratch data; the root filesystem stays read-only |
| Service account token | Not mounted | The workloads do not call the Kubernetes API |

The manifests are managed as a Kustomize directory, so the whole set is applied
with one command and can be extended per environment later.

## Repository layout

```text
apps/                   Application sources and the shared Dockerfile
k8s/                    Namespace, Deployments, Services and Kustomization
scripts/                Provisioning, bootstrap, deploy and verification
docs/background.md      Service behavior and design context
docs/deployment-report.pt-BR.md   Deployment report
```

## Prerequisites

- OpenStack CLI configured for the target project, with permission to create
  instances and edit the existing load balancer.
- An SSH key pair already registered in OpenStack.
- Docker images published to Docker Hub, as listed above.
- On the VM: Ubuntu 24.04, Docker Engine, `kubectl`, and `minikube`.

## Deployment

Run the scripts in order. The first creates the VM; the remaining ones run on
the VM, inside a clone of this repository.

```bash
export VM_NAME=workload-platform
export FLAVOR=general.large
export IMAGE=ubuntu-24.04
export KEYPAIR=your-keypair
bash scripts/00-openstack.sh
```

```bash
git clone https://github.com/DanielAndersonTI/k8s-workload-platform.git
cd k8s-workload-platform
sudo bash scripts/10-bootstrap.sh
newgrp docker
bash scripts/20-cluster.sh
bash scripts/30-deploy.sh
bash scripts/40-verify.sh
```

`10-bootstrap.sh` installs Docker, `kubectl`, and `minikube`, and disables swap.
`20-cluster.sh` starts Minikube with the Docker driver and publishes host ports
8000 to 8002. After changing group membership, open a new shell or run
`newgrp docker` before starting the cluster.

## Operational checks

```bash
kubectl -n workloads get deployments,pods,services -o wide
kubectl -n workloads rollout status deployment/cpu-workload
curl -sS http://127.0.0.1:8000/health
curl -sS "http://127.0.0.1:8002/work?size=1024"
```

From outside the VM, the same checks use the load balancer address on ports
8100, 8101, and 8102.

## Documentation

- [Service behavior and design context](docs/background.md)
- [Deployment report](docs/deployment-report.pt-BR.md)
