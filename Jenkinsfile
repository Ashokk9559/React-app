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
                    echo "BRANCH_NAME: ${env.BRANCH_NAME}"
                    echo "GIT_BRANCH: ${env.GIT_BRANCH}"
                    echo "GIT_REF: ${env.GIT_REF}"

                    // Determine the branch name
                    def branchName = env.BRANCH_NAME ?: env.GIT_BRANCH ?: env.GIT_REF?.split('/')[2] ?: error("Branch name not found")
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

                    // Store the Docker image ID for later use
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
                    echo "Deploying Docker containers on EC2"

                    def dockerImage = 'ashokk9559/prod:latest'
                    def nodeEnv = 'production'

                    // Stop and remove existing containers
                    sh 'docker-compose down'

                    // Deploy the new image
                    sh """
                        echo "DOCKER_IMAGE=${dockerImage}" > .env
                        echo "NODE_ENV=${nodeEnv}" >> .env
                        docker-compose up -d
                    """

                    // Verify deployment
                    sh '''
                        sleep 5
                        if docker ps | grep -q "${DOCKER_IMAGE}"; then
                            echo "Deployment successful"
                        else
                            echo "Deployment failed"
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
