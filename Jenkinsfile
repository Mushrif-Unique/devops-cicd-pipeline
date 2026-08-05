pipeline {

    agent any

    environment {
    DOCKER_IMAGE = 'nawasmushrif/devops-cicd-pipeline'
    IMAGE_TAG = "${BUILD_NUMBER}"
    CONTAINER_NAME = 'devops-container'
    HOST_PORT = '80'
    CONTAINER_PORT = '80'
    }

    stages {

        stage('Checkout') {
            steps {
                echo 'Getting source code from GitHub'
            }
        }

        stage('Test') {
            steps {
                echo 'Running automated tests...'
                sh 'bash scripts/test.sh'
            }
        }

        stage('Docker Build') {
            steps {
            echo "Building Docker image version ${IMAGE_TAG}..."

            sh '''
            docker build \
            -t ${DOCKER_IMAGE}:${IMAGE_TAG} \
            -t ${DOCKER_IMAGE}:latest \
            .
            '''
            }
        }

        stage('Push to Docker Hub') {
            steps {

                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-credentials',
                        usernameVariable: 'DOCKER_USERNAME',
                        passwordVariable: 'DOCKER_PASSWORD'
                    )
                ]) {

                    sh '''
                    echo "$DOCKER_PASSWORD" | docker login \
                    -u "$DOCKER_USERNAME" \
                    --password-stdin

                    docker push ${DOCKER_IMAGE}:${IMAGE_TAG}
                    docker push ${DOCKER_IMAGE}:latest

                    docker logout
                    '''
                }
            }
        }

        stage('Run Container') {
            steps {
                echo 'Deploying Docker image from Docker Hub...'

                sh '''
                docker pull ${DOCKER_IMAGE}:${IMAGE_TAG}

                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true

                docker run -d \
                --name ${CONTAINER_NAME} \
                -p ${HOST_PORT}:${CONTAINER_PORT} \
                ${DOCKER_IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Health Check') {
            steps {
                echo 'Verifying application health...'
                sh '''
                sleep 5
                curl -f http://localhost
                echo "Application is running successfully."
                '''
            }
        }

        stage('Verify Docker') {
            steps {
                sh '''
                docker ps
                docker images
                '''
            }
        }
    }

    post {

        always {
            echo 'Pipeline execution has finished.'
        }

        success {
            echo 'Application deployed successfully.'
        }

        failure {
            echo 'Pipeline failed. Please check the console output.'
        }

        cleanup {
            cleanWs()
        }
    }
}