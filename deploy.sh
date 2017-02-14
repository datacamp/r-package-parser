#!/bin/bash
BUILD_NUMBER=$(git rev-parse --short HEAD)
docker build -t dockerhub.datacamp.com:443/rdoc-ecs-worker:$BUILD_NUMBER .
docker push dockerhub.datacamp.com:443/rdoc-ecs-worker:$BUILD_NUMBER
