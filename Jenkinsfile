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
                    echo "Detected Branch: ${branchName}"

                    // Normalize branch name (remove 'origin/' prefix if present)
                    branchName = branchName.replaceAll('origin/', '')

                    // Build Docker image based on branch
                    def dockerImage
                    try {
                        if (branchName == 'dev') {
                            dockerImage = docker.build(devRegistry)
                        } else if (branchName == 'main' || branchName == 'master') {
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
                        docker.withRegistry('https://index.docker.io/v1/', registryCredential) {
                            docker.image(env.DOCKER_IMAGE).push('latest')
                        }
                    } catch (Exception e) {
                        error("Failed to push Docker image: ${e.message}")
                    }
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
