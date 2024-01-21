from common:latest

copy src/requirements.txt requirements.txt

run pip3 install -r requirements.txt --break-system-packages

copy src service

copy run.sh run.sh
run chmod +x run.sh

cmd ./run.sh
