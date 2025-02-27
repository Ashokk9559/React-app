#!/bin/bash

# Navigate to the project directory
cd /home/ubuntu/project/React-Devops || { echo "Directory not found!"; exit 1; }

# Check if docker-compose.yml exists
if [ ! -f docker-compose.yml ]; then
    echo "docker-compose.yml not found!"
    exit 1
fi

# Stop and remove existing containers
echo "Stopping and removing existing containers"
docker-compose down

# Pull latest Docker images
echo "Pulling latest Docker images"
docker-compose pull

# Start Docker containers
echo "Starting Docker containers"
docker-compose up -d >> deploy.log 2>&1

# Check if the command succeeded
if [ $? -eq 0 ]; then
    echo "Docker containers started successfully"
else
    echo "Docker containers failed to start"
    exit 1
fi
