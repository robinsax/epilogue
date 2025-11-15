#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

. ./scripts/common.sh

pushd backend

python -m alembic upgrade head

popd
