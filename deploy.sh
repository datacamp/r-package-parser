#!/bin/bash
docker build -t dockerhub.datacamp.com:443/rdoc-ecs-worker .
docker push dockerhub.datacamp.com:443/rdoc-ecs-worker
