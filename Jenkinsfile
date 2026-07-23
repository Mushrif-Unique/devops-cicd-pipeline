pipeline {

    agent any

    stages {

        stage('Checkout') {
            steps {
                echo 'Downloading source code from GitHub'
            }
        }


        stage('Build') {
            steps {
                echo 'Building application'
            }
        }


        stage('Test') {
            steps {
                echo 'Running tests'
            }
        }


        stage('Deploy') {
            steps {
                echo 'Deploying application'
            }
        }
    }
}