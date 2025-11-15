#!/bin/bash
set -o errexit
set -o pipefail
set -o nounset

log() {
    message=$1

    echo "$message"
}

fatal() {
    message=$1

    echo "[err] $message"
    exit 1
}

input() {
    read -p "$1: " value

    echo "$value"
}
