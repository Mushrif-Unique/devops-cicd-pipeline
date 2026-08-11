pipeline {

    agent any

    options {
        buildDiscarder(
            logRotator(
                numToKeepStr: '10',
                daysToKeepStr: '30'
            )
        )

        timestamps()

        timeout(time: 10, unit: 'MINUTES')

        disableConcurrentBuilds()
    }

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

        stage('Source Code') {
            steps {
                echo 'Source code has been checked out from GitHub.'
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
                    CURRENT_IMAGE=$(docker inspect ${CONTAINER_NAME} \
                    --format '{{.Config.Image}}' 2>/dev/null || true)

                    if [ -n "$CURRENT_IMAGE" ]; then

                        CURRENT_VERSION=$(echo "$CURRENT_IMAGE" | awk -F: '{print $NF}')

                        echo "$CURRENT_VERSION" | \
                        sudo tee /var/lib/jenkins/previous_version > /dev/null

                        echo "Previous version saved: $CURRENT_VERSION"
                    fi

                    docker pull ${DOCKER_IMAGE}:${IMAGE_TAG}

                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    --restart unless-stopped \
                    --memory=256m \
                    --cpus="0.50" \
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
                    docker pull ${DOCKER_IMAGE}:${ROLLBACK_VERSION}

                    docker stop ${CONTAINER_NAME} || true
                    docker rm ${CONTAINER_NAME} || true

                    docker run -d \
                    --name ${CONTAINER_NAME} \
                    --restart unless-stopped \
                    --memory=256m \
                    --cpus="0.50" \
                    -p ${HOST_PORT}:${CONTAINER_PORT} \
                    ${DOCKER_IMAGE}:${ROLLBACK_VERSION}
                '''
            }
        }

        stage('Deployment Info') {
            steps {
                sh '''
                    echo "===== Deployment Information ====="

                    echo "Container:"
                    docker inspect ${CONTAINER_NAME} \
                        --format '{{.Name}}'

                    echo "Image:"
                    docker inspect ${CONTAINER_NAME} \
                        --format '{{.Config.Image}}'

                    echo "Status:"
                    docker inspect ${CONTAINER_NAME} \
                        --format '{{.State.Status}}'

                    echo "Started At:"
                    docker inspect ${CONTAINER_NAME} \
                        --format '{{.State.StartedAt}}'
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

                                docker pull ${DOCKER_IMAGE}:$PREVIOUS_VERSION

                                docker stop ${CONTAINER_NAME} || true
                                docker rm ${CONTAINER_NAME} || true

                                docker run -d \
                                --name ${CONTAINER_NAME} \
                                --restart unless-stopped \
                                --memory=256m \
                                --cpus="0.50" \
                                -p ${HOST_PORT}:${CONTAINER_PORT} \
                                ${DOCKER_IMAGE}:${IMAGE_TAG}

                                sleep 5

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

        stage('Application Monitoring') {
            steps {

                sh '''
                    echo "===== Container Status ====="

                    docker ps \
                        --filter "name=${CONTAINER_NAME}"

                    echo ""
                    echo "===== Running Image ====="

                    docker inspect ${CONTAINER_NAME} \
                        --format '{{.Config.Image}}'

                    echo ""
                    echo "===== Application HTTP Status ====="

                    HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)

                    echo "HTTP Status: $HTTP_STATUS"

                    if [ "$HTTP_STATUS" != "200" ]; then
                        echo "Application monitoring check failed."
                        exit 1
                    fi

                    echo "Application monitoring check passed."
                '''
            }
        }

        stage('Container Logs') {
            steps {

                sh '''
                    echo "===== Recent Container Logs ====="

                    docker logs --tail 20 ${CONTAINER_NAME} || true
                '''
            }
        }

        stage('Docker Cleanup') {
            steps {

                sh '''
                    echo "Cleaning unused Docker resources..."

                    docker image prune -f

                    echo "Docker disk usage after cleanup:"

                    docker system df
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