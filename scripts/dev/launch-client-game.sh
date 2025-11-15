#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

pushd game

CONNECT_TO=127.0.0.1:6000 godot

popd
