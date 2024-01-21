from debian:bookworm-slim

run apt-get update

# todo net debug tools, rm
run apt-get install curl dnsutils -y

# todo stupid workaround
run apt-get install nginx -y

copy internal_proxy.conf /etc/nginx/nginx.conf

copy src service

copy run.sh run.sh
run chmod +x run.sh

cmd ./run.sh
