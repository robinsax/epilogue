#!/bin/bash
set -e
. ./etc/common.sh

op=$1

if [[ $op == "engine" ]]; then
    ./godot/Godot_v4.2.1-stable_win64.exe ./game/project.godot
elif [[ $op == "dummy-queue" ]]; then
    curl -X POST http://localhost/queue?user=dummy
else
    err_exit "invalid op"
fi
