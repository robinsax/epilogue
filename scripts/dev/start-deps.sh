#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

source ./scripts/common.sh

pushd infra/local

docker compose \
    -f docker-compose.deps.yml \
    up

popd
