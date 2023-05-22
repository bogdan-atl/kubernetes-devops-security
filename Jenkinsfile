pipeline {
  agent any

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }

    stage('Unit Tests - JUnit and Jacoco') {
      steps {
        sh "mvn test"
      }
      post {
        always {
          junit 'target/surefire-reports/*.xml'
          jacoco execPattern: 'target/jacoco.exec'
        }
      }
    }

    stage('Docker image build and push') {
      steps {
        sh 'printenv'
        sh 'docker build -t capsman/java-app:""$GIT_COMMMIT"" .'
        sh 'docker push capsman/java-app:""$GIT_COMMMIT""'
       }
    }
  }
}
