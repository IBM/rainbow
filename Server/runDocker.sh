#!/bin/bash
docker build -t rainbow-server-run .
docker build -t rainbow-server-build -f Dockerfile-tools .
docker run -v $PWD:/root/project -w /root/project rainbow-server-build /swift-utils/tools-utils.sh build release
docker run -it -p 8080:8080 -v $PWD:/root/project -w /root/project rainbow-server-run sh -c .build-ubuntu/release/rainbow-server
