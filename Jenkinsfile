pipeline {
  agent any

  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "capsman/java-app:""$GIT_COMMIT"""
  }

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
        sh "mvn org.pitest:pitest-maven:mutationCoverage"
      }
    }

    //stage('SonarQube - SAST') {
      //steps {
       // sh "mvn sonar:sonar -Dsonar.projectKey=devsecops-numeric-application -Dsonar.projectName='devsecops-numeric-application' -Dsonar.host.url=http://45.156.23.33:9000 -Dsonar.login=sqp_94c4e149e9e1b4d930060f95848cd8d7d5192778"
      //}
    //}

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
            sh "/usr/local/bin/conftest test --policy opa-docker-security.rego Dockerfile"
          }
        )
      }
    }


    stage('Docker image build and push') {
      steps {
        withDockerRegistry([credentialsId: "docker-hub", url: ""]) {
          sh 'printenv'
          sh 'docker build -t capsman/java-app:""$GIT_COMMIT"" .'
          sh 'docker push capsman/java-app:""$GIT_COMMIT""'
        }
      }
    }

    stage('Vulnerability Scan - Kubernetes') {
      steps {
        parallel(
          "OPA Scan": {
            sh '/usr/local/bin/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
          },
          "Kubesec Scan": {
            sh "bash kubesec-scan.sh"
          }
        )
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



  post {
    always {
      junit 'target/surefire-reports/*.xml'
      jacoco execPattern: 'target/jacoco.exec'
      pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
      dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
    }
  }
}
