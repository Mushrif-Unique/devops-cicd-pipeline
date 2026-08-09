pipeline {

    agent any

    parameters {
        string(
            name: 'ROLLBACK_VERSION',
            defaultValue: '',
            description: 'Enter Docker image version to rollback to. Leave empty for normal deployment.'
        )
    }

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
                echo 'Source code checked out from GitHub.'
            }
        }

        stage('Test') {
            when {
                expression {
                    !params.ROLLBACK_VERSION?.trim()
                }
            }

            steps {
                echo 'Running automated tests...'
                sh 'bash scripts/test.sh'
            }
        }

        stage('Docker Build') {
            when {
                expression {
                    !params.ROLLBACK_VERSION?.trim()
                }
            }

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
            when {
                expression {
                    !params.ROLLBACK_VERSION?.trim()
                }
            }

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

        stage('Normal Deployment') {
            when {
                expression {
                    !params.ROLLBACK_VERSION?.trim()
                }
            }

            steps {

                echo "Deploying version ${IMAGE_TAG}..."

                sh '''
                    # Get the currently running Docker image
                    CURRENT_IMAGE=$(docker inspect ${CONTAINER_NAME} \
                    --format '{{.Config.Image}}' 2>/dev/null || true)

                    # Save currently running version
                    if [ -n "$CURRENT_IMAGE" ]; then

                        CURRENT_VERSION=$(echo "$CURRENT_IMAGE" | awk -F: '{print $NF}')

                        echo "$CURRENT_VERSION" | \
                        sudo tee /var/lib/jenkins/previous_version > /dev/null

                        echo "Previous version saved: $CURRENT_VERSION"
                    fi

                    # Pull new image
                    docker pull ${DOCKER_IMAGE}:${IMAGE_TAG}

                    # Stop and remove old container
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    # Start new container
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${HOST_PORT}:${CONTAINER_PORT} \
                    ${DOCKER_IMAGE}:${IMAGE_TAG}
                '''
            }
        }

        stage('Rollback') {
            when {
                expression {
                    params.ROLLBACK_VERSION?.trim()
                }
            }

            steps {

                echo "Rolling back to version ${params.ROLLBACK_VERSION}..."

                sh '''
                    # Pull requested version
                    docker pull ${DOCKER_IMAGE}:${ROLLBACK_VERSION}

                    # Stop and remove current container
                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    # Start requested version
                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    -p ${HOST_PORT}:${CONTAINER_PORT} \
                    ${DOCKER_IMAGE}:${ROLLBACK_VERSION}
                '''
            }
        }

        stage('Health Check') {
            steps {

                script {

                    def healthStatus = sh(
                        script: '''
                            sleep 5
                            curl -f http://localhost
                        ''',
                        returnStatus: true
                    )

                    if (healthStatus != 0) {

                        echo 'Health check failed. Starting automatic rollback...'

                        sh '''
                            if [ -f /var/lib/jenkins/previous_version ]; then

                                PREVIOUS_VERSION=$(cat /var/lib/jenkins/previous_version)

                                echo "Rolling back to version: $PREVIOUS_VERSION"

                                # Pull previous working image
                                docker pull ${DOCKER_IMAGE}:$PREVIOUS_VERSION

                                # Stop and remove failed container
                                docker stop ${CONTAINER_NAME} || true
                                docker rm ${CONTAINER_NAME} || true

                                # Start previous working version
                                docker run -d \
                                --name ${CONTAINER_NAME} \
                                -p ${HOST_PORT}:${CONTAINER_PORT} \
                                ${DOCKER_IMAGE}:$PREVIOUS_VERSION

                                # Give application time to start
                                sleep 5

                                # Verify rollback
                                curl -f http://localhost

                                echo "Automatic rollback completed successfully."

                            else

                                echo "No previous version found. Cannot rollback."
                                exit 1

                            fi
                        '''

                        error(
                            'New deployment failed health check. Previous version restored.'
                        )
                    }

                    echo 'Application is running successfully.'
                }
            }
        }

        stage('Verify Docker') {
            steps {

                sh '''
                    echo "Running containers:"
                    docker ps

                    echo "Available Docker images:"
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
            echo 'Pipeline completed successfully.'
        }

        failure {
            echo 'Pipeline failed. Please check the console output.'
        }

        cleanup {
            cleanWs()
        }
    }
}