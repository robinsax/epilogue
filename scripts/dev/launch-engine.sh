#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

. ./scripts/common.sh

godot -e
