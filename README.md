# k8s-workload-platform

Three HTTP services with distinct resource profiles, packaged as containers and
scheduled by Kubernetes on a single-node Minikube cluster. An OpenStack Octavia
load balancer publishes the services on ports 8600 to 8602. The existing
listeners on 8100 to 8102 remain assigned to the previous Docker Compose
environment, so both deployments coexist.

The services expose the same contract: `GET /health`, `GET /work?size=N`, and
`GET /metrics`. The first is used by Kubernetes probes and by the load balancer
health monitor, the second generates the workload, and the third returns process
counters.

## Architecture

```text
client
  |  HTTP 8600 / 8601 / 8602
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

The load balancer is shared infrastructure. This platform creates its own
listeners, pools and health monitors on ports 8600 to 8602, plus an SSH listener
on port 2223. The cluster answers on host ports 8000 to 8002, which the new
listeners target. The previous environment keeps its listeners on ports 8100 to
8102 and its SSH listener on port 2222. Ports 8600 to 8602 were chosen because
the shared balancer already uses 8201 for another group.

## Workloads

| Service | Image | Behavior | NodePort | External port |
| --- | --- | --- | --- | --- |
| CPU | `danielandersonss/poi-cpu:1.1.0` | Iterated SHA-256 over a buffer | 30080 | 8600 |
| Memory | `danielandersonss/poi-memory:1.1.0` | Allocates and touches `size` MiB | 30081 | 8601 |
| I/O | `danielandersonss/poi-io:1.1.0` | Writes and reads a scratch file | 30082 | 8602 |

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
| Requests | 250m/128Mi to 250m/512Mi | Guarantees scheduling headroom on the VM's 4 vCPUs |
| Limits | 1 CPU/512Mi to 1 CPU/1536Mi | Caps the blast radius of a workload that allocates more than expected |
| Security context | UID/GID 10001, no privilege escalation, read-only root, all capabilities dropped, `RuntimeDefault` seccomp | The application needs no privilege and no writable layer |
| Writable path | `emptyDir` at `/tmp` | The I/O service writes scratch data; the root filesystem stays read-only |
| Service account token | Not mounted | The workloads do not call the Kubernetes API |
| Namespace policy | Pod Security Admission `restricted` | Rejects pods that do not meet the restricted profile |
| Disruption budget | `minAvailable: 1` per Deployment | Keeps one replica serving during voluntary disruptions |
| Default resources | `LimitRange` in the namespace | Gives a safe default to any container that omits requests or limits |

The Docker driver applies `--memory` as a cgroup limit, but in minikube v1.39.0 it does not create a CPU quota from `--cpus`. `20-cluster.sh` applies the CPU limit with `docker update` and fails if the quota is absent. The kubelet still advertises the host capacity, so `kubectl top` percentages use 4 vCPUs and about 7.75 GiB, while the container is capped at 3 vCPUs and 6 GiB. The total requests, 1.2 vCPU and 1.5 GiB, fit both views. The total limits, 5 vCPU and 5 GiB, exceed the advertised CPU but stay below the 6 GiB memory cap.

The manifests are managed as a Kustomize directory, so the whole set is applied
with one command and can be extended per environment later.

## Repository layout

```text
apps/                   Application sources and the shared Dockerfile
k8s/                    Namespace, Deployments, Services, PDB, LimitRange and Kustomization
scripts/                Provisioning, bootstrap, deploy and verification
docs/background.md      Service behavior and design context
docs/evidencias/        Evidence policy and sanitized command output
docs/execucao-atividade5/         Execution log, one record per task
docs/relatorio-final.md           Final deployment report and its PDF
docs/tools/md2pdf.py              Markdown to PDF converter for the report
```

## Prerequisites

- OpenStack CLI configured for the target project, with permission to create
  instances, security groups and load balancer listeners.
- `ssh-keygen` available on the machine that runs `00-openstack.sh`; the script
  creates the `atividade5` key pair and registers the public key.
- Docker images published to Docker Hub, as listed above.
- On the VM: Ubuntu 24.04, Docker Engine, `kubectl`, and `minikube`.

## Deployment

Scripts `00` and `50` run on the machine with the OpenStack CLI, the access VDI.
Scripts `10` to `40` run on the new VM, inside a clone of this repository.
Script `05` runs on any host with Docker, after `00` and before `30`.

On the access VDI, create the key pair, the security group and the VM:

```bash
git clone https://github.com/DanielAndersonTI/k8s-workload-platform.git
cd k8s-workload-platform
export VM_NAME=vm-atividade5-k8s
export FLAVOR=general.large
export IMAGE=ubuntu-24.04
export KEYPAIR=atividade5
export SECGROUP=sg-atividade5
bash scripts/00-openstack.sh
```

On the VM, install the runtime and deploy:

```bash
git clone https://github.com/DanielAndersonTI/k8s-workload-platform.git
cd k8s-workload-platform
sudo bash scripts/10-bootstrap.sh
newgrp docker
bash scripts/20-cluster.sh
bash scripts/30-deploy.sh
bash scripts/40-verify.sh
```

The sequence above uses the published `1.1.0` images. Rebuilding and pushing
them is optional and needs a Docker Hub token:

```bash
cp docker.env.example docker.env
# edit docker.env and set DOCKERHUB_USER and DOCKERHUB_TOKEN
bash scripts/05-images.sh
```

Back on the access VDI, create the A5 listeners. `SUBNET_ID` is the subnet of
the VM, `17de9c72-e5dc-4da0-ae0a-013f7e42400e` in the current project:

```bash
export SUBNET_ID=17de9c72-e5dc-4da0-ae0a-013f7e42400e
bash scripts/50-loadbalancer.sh
```

`10-bootstrap.sh` installs pinned versions of Docker, `kubectl`, and `minikube`,
and disables swap. `05-images.sh` is optional: it builds each profile from
`apps/Dockerfile` and pushes the `1.1.0` tags, leaving the `1.0.0` images from
the previous activity untouched. The Docker Hub token is read from `docker.env`,
which is never committed.
`20-cluster.sh` starts Minikube with the Docker driver and publishes host ports
8000 to 8002. After changing group membership, open a new shell or run
`newgrp docker` before starting the cluster. `50-loadbalancer.sh` creates the
listeners on 8600 to 8602 and the SSH listener on 2223, without changing the A4
listeners.

## Operational checks

```bash
kubectl -n workloads get deployments,pods,services -o wide
kubectl -n workloads rollout status deployment/cpu-workload
curl -sS http://127.0.0.1:8000/health
curl -sS "http://127.0.0.1:8002/work?size=1024"
```

From outside the VM, the same checks use the load balancer address on ports
8600, 8601, and 8602. Ports 8100 to 8102 must keep answering for the previous
environment, which is a separate validation.

## Documentation

- [Service behavior and design context](docs/background.md)
- [Evidence policy](docs/evidencias/README.md)
- [Final deployment report](docs/relatorio-final.md)
- [Form answers](docs/formulario.md)
- [Presentation plan](docs/apresentacao.md)
- [Demonstration script](docs/roteiro-demonstracao.md)
