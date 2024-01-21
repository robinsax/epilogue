#!/bin/bash
set -e
. ./etc/common.sh

env=$1
op=$2

if [[ $env = "local" ]]; then
    if [[ $op == "up" ]]; then
        log "local up"

        builds=(
            "common"
            "api"
            "hub"
            "server"
        )

        for build in "${builds[@]}"; do
            log "build $build"

            build_dir="infra/build/$build"
            src_dir="backend/$build"
            build_src_dir="$build_dir/src"

            if [ -d $build_src_dir ]; then
                rm -r $build_src_dir
            fi
            if [ -d "$src_dir" ]; then
                cp -r $src_dir $build_src_dir
            fi
            if [ -f "$build_dir/prebuild.sh" ]; then
                . $build_dir/prebuild.sh
            fi

            pushd $build_dir

            docker build -t "$build:latest" .

            popd
        done

        set +e
        docker-compose -f infra/local/docker-compose.yml up
        set -e

        docker-compose -f infra/local/docker-compose.yml down
        
        ./dev.sh clean
    else
        err_exit "invalid op"
    fi
else
    err_exit "invalid env"
fi
