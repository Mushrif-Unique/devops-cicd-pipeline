pipeline {

    agent any

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
                sh 'docker build -t devops-app .'
            }
        }

        stage('Run Container') {
            steps {
                sh '''
                docker stop devops-container || true
                docker rm devops-container || true

                docker run -d \
                --name devops-container \
                -p 80:80 \
                devops-app
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh 'docker ps'
            }
        }
    }
}