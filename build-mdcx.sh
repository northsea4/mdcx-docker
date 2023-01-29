#!/bin/bash

mv app/config.ini config.ini.bak

docker build . -f Dockerfile-mdcx -t stainless403/mdcx:dev -t stainless403/mdcx:latest

mv config.ini.bak app/config.ini