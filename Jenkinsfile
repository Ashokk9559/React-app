pipeline {
    agent any
    environment {
        devRegistry = 'ashokk9559/dev'
        prodRegistry = 'ashokk9559/prod'
        registryCredential = 'dockerhub-credentials'
        appServiceName = 'web'  // Updated to match your Docker Compose file
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build Docker Image') {
            steps {
                script {
                    echo "BRANCH_NAME: ${env.BRANCH_NAME}"

                    // Detect branch
                    def branchName = env.BRANCH_NAME ?: error("Branch name not found")
                    branchName = branchName.replaceAll('origin/', '')
                    echo "Detected Branch: ${branchName}"

                    // Build and tag Docker image
                    def dockerImage
                    try {
                        if (branchName == 'dev') {
                            echo "Building Docker image for dev branch"
                            dockerImage = docker.build("${devRegistry}:latest")
                        } else if (branchName == 'main') {
                            echo "Building Docker image for prod branch"
                            dockerImage = docker.build("${prodRegistry}:latest")
                        } else {
                            error("Unknown branch: ${branchName}")
                        }
                    } catch (Exception e) {
                        error("Failed to build Docker image: ${e.message}")
                    }

                    // Store the image ID
                    env.DOCKER_IMAGE = dockerImage.id
                    echo "Built Docker Image ID: ${env.DOCKER_IMAGE}"
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    if (!env.DOCKER_IMAGE) {
                        error("Docker image not found. Build stage might have failed.")
                    }

                    try {
                        echo "Pushing Docker image: ${env.DOCKER_IMAGE}"
                        docker.withRegistry('https://index.docker.io/v1/', registryCredential) {
                            docker.image(env.DOCKER_IMAGE).push('latest')
                        }
                    } catch (Exception e) {
                        error("Failed to push Docker image: ${e.message}")
                    }
                }
            }
        }
        stage('Deploy to EC2') {
            when {
                expression { return (env.BRANCH_NAME == 'main') }
            }
            steps {
                script {
                    echo "Deploying Docker containers on EC2 (without affecting Jenkins)"

                    def dockerImage = 'ashokk9559/prod:latest'
                    def nodeEnv = 'production'

                    // Stop only the web application service (not all containers)
                    sh """
                        docker-compose stop web
                        docker-compose rm -f web
                    """

                    // Deploy new application containers
                    sh """
                        echo "DOCKER_IMAGE=${dockerImage}" > .env
                        echo "NODE_ENV=${nodeEnv}" >> .env
                        docker-compose up -d web
                    """

                    // Verify deployment
                    sh """
                        sleep 5
                        if docker ps | grep -q "${dockerImage}"; then
                            echo "Deployment successful"
                        else
                            echo "Deployment failed"
                            exit 1
                        fi
                    """
                }
            }
        }
    }
    post {
        always {
            cleanWs()
        }
    }
}
