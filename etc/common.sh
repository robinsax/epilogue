#!/bin/bash

log() {
    message=$1

    echo "$message"
}

err_exit() {
    message=$1

    echo "[err] $message"
    exit 1
}

export PATH=$PATH:$(pwd)/godot

run_godot() {
    pushd game
    set +e
    godot $@
    set -e
    popd
}
