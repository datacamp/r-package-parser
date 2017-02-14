#!/bin/bash
TAG=dockerhub.datacamp.com:443/rdoc-ecs-worker:$BUILD_NUMBER
docker build -t $TAG .
docker login --username="$1" --password="$2" dockerhub.datacamp.com:443
docker push $TAG
