#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

source ./scripts/common.sh

message=$(input "Message")

pushd backend

python -m alembic revision --autogenerate -m "$message"

popd
