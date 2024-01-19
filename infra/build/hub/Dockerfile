from common:latest

run apt-get install -y docker.io

copy src/requirements.txt requirements.txt

run pip3 install -r requirements.txt --break-system-packages

copy src service

cmd python3 -u service
