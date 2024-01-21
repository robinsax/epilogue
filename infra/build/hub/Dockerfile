from common:latest

copy src/requirements.txt requirements.txt

run pip3 install -r requirements.txt --break-system-packages

copy src service

cmd python3 -u service
