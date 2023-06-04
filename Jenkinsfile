

pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "capsman/java-app:latest"
  }

  stages {

    stage('Build Artifact - Maven') {
      steps {
        sh "mvn clean package -DskipTests=true"
        archive 'target/*.jar'
      }
    }

    stage('Unit Tests - JUnit and JaCoCo') {
      steps {
        sh "mvn test"
      }
    }

    stage('Mutation Tests - PIT') {
      steps {
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
    }

    stage('Vulnerability Scan - Docker') {
      steps {
        parallel(
          "Dependency Scan": {
            sh "mvn dependency-check:check"
          },
          "Trivy Scan": {
            sh "bash trivy-docker-image-scan.sh"
          },
          "OPA Conftest": {
            sh '/usr/local/bin/conftest test --policy opa-docker-security.rego Dockerfile'
          }
        )
      }
    }

    stage('Docker Build and Push') {
      steps {
          sh 'sudo docker build -t capsman/java-app:latest .'
          sh 'docker push capsman/java-app:latest'
      }
    }

    stage('Vulnerability Scan - Kubernetes') {
      steps {
        sh '/usr/local/bin/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
      }
    }

    stage('K8S Deployment - DEV') {
      steps {
        parallel(
          "Deployment": {
              sh "bash k8s-deployment.sh"
          },
          "Rollout Status": {
              sh "bash k8s-deployment-rollout-status.sh"
          }
        )
      }
    }

  }

  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }

  }

}
