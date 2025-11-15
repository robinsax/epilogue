#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

. ./scripts/common.sh

message=$(input "Message")

pushd backend

python -m alembic revision --autogenerate -m "$message"

popd
