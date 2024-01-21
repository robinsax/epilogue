from debian:bookworm-slim

run apt-get update -y && \
    # todo no docker here in release, just here for caching
    apt-get install -y python3 python3-pip docker.io

workdir /service
run cd /service

copy src/requirements.txt requirements.txt

run pip3 install -r requirements.txt --break-system-packages

copy src common
