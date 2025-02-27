#!/bin/bash

cd /home/ubuntu/project/React-Devops

echo "Building Docker images"
docker-compose build

if [ $? -eq 0 ]; then
    echo "Docker images built successfully"
else
    echo "Docker images build failed"
    exit 1
fi
