# Service behavior and design context

The platform runs three small HTTP services that differ only in the resource
they consume. Keeping one contract across all three makes the deployment
uniform: the same probes, the same service shape, and the same client.

## Shared contract

| Endpoint | Response | Purpose |
| --- | --- | --- |
| `GET /health` | `{"status":"ok","profile":"<name>"}` | Readiness, liveness, and load balancer health check |
| `GET /work?size=N` | JSON with the computed result and duration | Generates one bounded unit of work |
| `GET /metrics` | Process counters | Wait time, work time, inflight requests, and rejections |

All services listen on port 8000 inside the container and accept only `GET`.
A request that finds every work slot busy is rejected with `503` instead of
queueing without limit. The default concurrency caps are 32 for CPU, 4 for
memory, and 16 for I/O.

## Profiles

### CPU

`size` is a number of iterations, from 1 to 300, default 10. Each iteration runs
SHA-256 over a 1 MiB block and writes the digest back into the first 32 bytes of
the block, so the next iteration depends on the previous one. The block is large
on purpose: CPython releases the GIL for hashing inputs above 2 KiB, which lets
concurrent requests use more than one core.

### Memory

`size` is a number of MiB, from 1 to 256, default 32. The service allocates a
`bytearray`, writes one byte per 4 KiB page to force physical commitment, and
sums the sampled pages. The result reports the allocated size and the checksum.

### I/O

`size` is a number of KiB, from 1 to 32768, default 1024. The service creates a
temporary file, writes the payload, calls `fsync`, and reads the file back. The
scratch directory is chosen by `A3_WORK_DIR`; in Kubernetes it points to an
`emptyDir` mounted at `/tmp`, which keeps the container root filesystem
read-only.

## Why Kubernetes

The previous packaging model started one container per host port through Docker
Compose. That model is sufficient for a single machine, but it leaves
restart policy, health checking, and rolling replacement to external tooling.
Kubernetes brings those concerns into the workload definition:

- A `Deployment` owns the desired replica count and replaces failed pods.
- Readiness and liveness probes are part of the manifest, not of an external
  monitor.
- Resource requests and limits are enforced by the scheduler and the runtime.
- A rolling update can replace pods without dropping every replica at once.

The trade-off is operational weight. A single-node Minikube cluster adds a
control plane and a container runtime layer to a VM that already runs Docker.
The design keeps that overhead bounded by sizing the cluster below the VM and
by using the Docker driver, which avoids nested virtualization.

## Images

The three images are built from `apps/Dockerfile` with `PROFILE` as the build
argument and published to Docker Hub:

```bash
docker build -f apps/Dockerfile --build-arg PROFILE=cpu \
  -t danielandersonss/poi-cpu:1.0.0 .
```

The runtime image runs as UID/GID 10001, exposes port 8000, and declares a
health check on `/health`. The Kubernetes manifests repeat the non-root and
read-only constraints explicitly, so the pod security posture does not depend
on the image metadata alone.
