from common:latest

copy src/requirements.txt requirements.txt

run pip3 install -r requirements.txt --break-system-packages

copy src service

expose 80
cmd python3 -u service
