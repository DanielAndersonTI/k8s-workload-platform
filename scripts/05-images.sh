#!/usr/bin/env bash
#
# Build and publish the three A5 images as 1.1.0.
#
# Run on a host with Docker and a Docker Hub token. The token is read from the
# environment or from docker.env, never printed. The tag is fixed at 1.1.0 so
# the A4 images tagged 1.0.0 are not overwritten.
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

if [ -f docker.env ]; then
  set -a
  # shellcheck disable=SC1091
  . ./docker.env
  set +a
fi

: "${DOCKERHUB_USER:?set DOCKERHUB_USER in the environment or in docker.env}"
: "${DOCKERHUB_TOKEN:?set DOCKERHUB_TOKEN in the environment or in docker.env}"

TAG="${IMAGE_TAG:-1.1.0}"
PLATFORM="${PLATFORM:-linux/amd64}"

command -v docker >/dev/null 2>&1 || {
  echo "docker not found" >&2
  exit 1
}
docker info >/dev/null

printf '%s' "$DOCKERHUB_TOKEN" \
  | docker login --username "$DOCKERHUB_USER" --password-stdin

for profile in cpu memory io; do
  image="${DOCKERHUB_USER}/poi-${profile}:${TAG}"
  echo
  echo "building ${image}"
  docker build \
    --platform "$PLATFORM" \
    -f apps/Dockerfile \
    --build-arg PROFILE="$profile" \
    -t "$image" .
  docker push "$image"
done

docker logout
