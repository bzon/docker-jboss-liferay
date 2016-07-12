#!/bin/bash

if [[ $2 == 'build' ]]; then
  docker build -t test-image .
  if [[ $? -gt 0 ]]; then
   exit 1
  fi
fi

docker rm -f test-container

docker network create liferay-network

if [[ $1 == 'bash' ]]; then
  docker run --net=liferay-network -e JVM_XMX_SIZE=6144m -e JVM_XMS_SIZE=2048m --name test-container -p 8080:8080 -p 9990:9990 -p 9999:9999 -it test-image bash
else
  docker run --net=liferay-network --name test-container -p 8080:8080 -p 9990:9990 -p 9999:9999 -d test-image
fi
