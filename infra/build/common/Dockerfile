from debian:bookworm-slim

run apt-get update -y && \
    apt-get install -y python3 python3-pip

workdir /service
run cd /service

copy src/requirements.txt requirements.txt

run pip3 install -r requirements.txt --break-system-packages

copy src common
