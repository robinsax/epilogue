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
