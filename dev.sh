#!/bin/bash
set -e
. ./etc/common.sh

op=$1

if [[ $op == "engine" ]]; then
    run_godot -e
elif [[ $op == "run" ]]; then
    which=$2
    if [[ $which == "server" ]]; then
        MATCH_DATA_PATH="$(pwd)/etc/test_match_data.json" PORT=5000 run_godot --headless
    elif [[ $which == "client-direct" ]]; then
        name=$3
        if [[ $name == "" ]]; then
            name="from-dev.sh"
        fi
        CLIENT_NAME=$name DIRECT_CONNECT="127.0.0.1:5000" run_godot
    elif [[ $which == "client" ]]; then
        name=$3
        if [[ $name == "" ]]; then
            name="from-dev.sh"
        fi
        CLIENT_NAME=$name run_godot
    else
        err_exit "invalid thing to run"
    fi
elif [[ $op == "clean" ]]; then
    running=$(docker ps -q)
    if [[ $running != "" ]]; then
        docker kill $running
    fi

    stopped=$(docker ps -aq)
    if [[ $stopped != "" ]]; then
        docker rm $stopped
    fi
elif [[ $op == "dummy-queue" ]]; then
    user=$2
    if [[ $user = "" ]]; then
        user="dummy"
    fi

    curl -X POST -H "Content-Type: application/json" -d '{"items": []}' http://localhost/queue?user=$user
else
    err_exit "invalid op"
fi
