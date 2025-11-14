FROM ubuntu:plucky

RUN apt-get update && apt-get install -y python3 python3-pip libpq-dev

WORKDIR /server

RUN pip3 install hypercorn

COPY requirements.txt /server/

RUN pip3 install -r requirements.txt

COPY . /server

CMD ["./start.sh"]
