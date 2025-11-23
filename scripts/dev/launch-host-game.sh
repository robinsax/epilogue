#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

pushd game

godot

popd
