pipeline {
    agent any
    environment {
        devRegistry = 'ashokk9559/dev'
        prodRegistry = 'ashokk9559/prod'
        registryCredential = 'dockerhub-credentials'
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
                    // Debug: Print environment variables
                    echo "BRANCH_NAME: ${env.BRANCH_NAME}"
                    echo "GIT_BRANCH: ${env.GIT_BRANCH}"
                    echo "GIT_REF: ${env.GIT_REF}"

                    // Determine the branch name
                    def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: env.GIT_REF?.split('/')[2] ?: error("Branch name not found")
                    branchName = branchName.replaceAll('origin/', '') // Remove 'origin/' prefix if present
                    echo "Detected Branch: ${branchName}"

                    // Build Docker image based on branch
                    def dockerImage
                    try {
                        if (branchName == 'dev') {
                            echo "Building Docker image for dev branch"
                            dockerImage = docker.build(devRegistry)
                        } else if (branchName == 'main' || branchName == 'master') {
                            echo "Building Docker image for prod branch"
                            dockerImage = docker.build(prodRegistry)
                        } else {
                            error("Unknown branch: ${branchName}")
                        }
                    } catch (Exception e) {
                        error("Failed to build Docker image: ${e.message}")
                    }

                    // Store the Docker image in an environment variable for use in later stages
                    env.DOCKER_IMAGE = dockerImage.id
                    echo "Docker Image ID: ${env.DOCKER_IMAGE}"
                }
            }
        }
        stage('Push Docker Image') {
            steps {
                script {
                    // Ensure the Docker image is built
                    if (!env.DOCKER_IMAGE) {
                        error("Docker image not found. Build stage might have failed.")
                    }

                    // Push Docker image
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
                expression { 
                    return (env.BRANCH_NAME == 'main' || env.BRANCH_NAME == 'master') 
                }
            }
            steps {
                script {
                    echo "Deploying Docker containers on the same server"

                    // Set environment variables for docker-compose
                    def dockerImage = (env.BRANCH_NAME == 'dev') ? 'ashokk9559/dev:latest' : 'ashokk9559/prod:latest'
                    def nodeEnv = (env.BRANCH_NAME == 'dev') ? 'development' : 'production'

                    // Stop and remove any existing containers
                    sh '''
                        docker-compose down
                    '''
                    
                    // Deploy the new image using Docker Compose
                    sh """
                        export DOCKER_IMAGE=${dockerImage}
                        export NODE_ENV=${nodeEnv}
                        docker-compose up -d
                    """

                    // Verify deployment
                    sh '''
                        if docker ps | grep ${DOCKER_IMAGE}; then
                            echo "Docker containers started successfully"
                        else
                            echo "Docker containers failed to start"
                            exit 1
                        fi
                    '''
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
