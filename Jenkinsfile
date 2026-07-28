pipeline {

    agent any

    environment {
        IMAGE_NAME = 'devops-app'
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
                sh 'docker build -t ${IMAGE_NAME} .'
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                docker stop ${CONTAINER_NAME} || true
                docker rm ${CONTAINER_NAME} || true

                docker run -d \
                --name ${CONTAINER_NAME} \
                -p ${HOST_PORT}:${CONTAINER_PORT} \
                ${IMAGE_NAME}
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'docker ps'
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