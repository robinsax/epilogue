#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

source ./scripts/common.sh

pushd backend

python -m alembic upgrade head

popd
