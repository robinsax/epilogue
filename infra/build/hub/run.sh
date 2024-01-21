#!/bin/bash

set -m

python3 -u service &

SERVICE=api python3 -u service

fg %1
