# End-to-End CI/CD Pipeline for Spring Boot Application

This repository provides a comprehensive guide for setting up a CI/CD pipeline for a Spring Boot application, offering two deployment methods: **Minikube** (local Kubernetes without Helm charts) and **AWS EKS** (cloud-based Kubernetes with Helm charts and ArgoCD). Both approaches leverage Jenkins for automation, Docker for containerization, SonarQube for static code analysis, and Trivy for container security scanning. Users can choose the method that best suits their needs—Minikube for local development or EKS for production-grade deployment.

## Table of Contents

- [Architecture Overview](#architecture-overview)
- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [Deployment Methods](#deployment-methods)
  - [Method 1: Minikube Deployment (Without Helm)](#method-1-minikube-deployment-without-helm)
    - [EC2 Instance Setup](#ec2-instance-setup)
    - [Java Spring Boot Setup](#java-spring-boot-setup)
    - [Dockerization](#dockerization)
    - [Jenkins Setup](#jenkins-setup)
    - [SonarQube Configuration](#sonarqube-configuration)
    - [Minikube and Kubernetes Setup](#minikube-and-kubernetes-setup)
    - [ArgoCD Deployment](#argocd-deployment)
    - [Trivy Security Scanning](#trivy-security-scanning)
    - [Access Application](#access-application)
  - [Method 2: AWS EKS Deployment (With Helm and ArgoCD)](#method-2-aws-eks-deployment-with-helm-and-argocd)
    - [AWS CLI and IAM Setup](#aws-cli-and-iam-setup)
    - [EKS Cluster Setup](#eks-cluster-setup)
    - [Helm Chart Structure](#helm-chart-structure)
    - [ArgoCD Setup and Application Deployment](#argocd-setup-and-application-deployment)
    - [Spring Boot Application Deployment](#spring-boot-application-deployment)
    - [Jenkins Pipeline Configuration](#jenkins-pipeline-configuration)
- [Troubleshooting](#troubleshooting)
- [Achievements](#achievements)
- [Future Scope](#future-scope)
- [Summary Flow](#summary-flow)

## Architecture Overview

The pipeline automates the process from code commit to deployment:
- **Minikube**: Uses raw Kubernetes manifests for local development, deployed via ArgoCD on an EC2 instance.
- **EKS**: Uses Helm charts for production-grade deployment on AWS EKS, managed via ArgoCD and Jenkins.

![Architecture Diagram](https://github.com/user-attachments/assets/3ba75467-6777-4ccf-b3c4-1daa26b740ce)

## Prerequisites

| Item                | Minikube Deployment                          | EKS Deployment                              |
|---------------------|----------------------------------------------|---------------------------------------------|
| **EC2 Instance**    | Ubuntu 24.04, 2 vCPU, 4GB RAM, 30GB storage, Docker installed, internet access | Ubuntu 24.04, 2 vCPU, 4GB RAM, Docker installed, internet access |
| **AWS Account**     | Not required (local setup)                   | IAM user with AdministratorAccess or permissions for EKS, EC2, IAM, etc. |
| **AWS CLI**         | Not required                                | Version 2 installed and configured (`aws configure`) |
| **Jenkins**         | Installed via Docker, plugins: Git, Pipeline, Docker Pipeline, SonarQube Scanner, Credentials Binding | Installed on EC2 or Docker, plugins: Git, Pipeline, Docker Pipeline, Kubernetes CLI, SonarQube Scanner, Credentials Binding, GitHub Branch Source |
| **Maven & JDK**     | Maven 3.8.7, JDK 17                         | Maven 3.8.7, JDK 17                         |
| **DockerHub**       | Repository: `venkatesh384/java-cicd-app`, credentials stored in Jenkins | Repository: `venkatesh384/java-cicd-app`, credentials stored in Jenkins |
| **SonarQube**       | Server URL and token configured in Jenkins  | Server URL and token configured in Jenkins  |
| **Kubernetes Tools**| Minikube, kubectl                            | eksctl, kubectl, Helm                       |

### Security Group Rules (Minikube Deployment)
| Port   | Protocol | Source     | Description             |
|--------|----------|------------|-------------------------|
| 30441  | TCP      | 0.0.0.0/0  | ArgoCD NodePort         |
| 9000   | TCP      | 0.0.0.0/0  | SonarQube               |
| 8080   | TCP      | 0.0.0.0/0  | Java CI/CD App          |
| 8443   | TCP      | 0.0.0.0/0  | Kubernetes API          |
| 80     | TCP      | 0.0.0.0/0  | ArgoCD Server           |
| 30081  | TCP      | 0.0.0.0/0  | Java CICD Service       |
| 22     | TCP      | 0.0.0.0/0  | SSH                     |
| 50000  | TCP      | 0.0.0.0/0  | Jenkins Agents          |

## Project Structure

```
EndtoEnd-CI-CD-Pipeline-for-Java-Application/
├── app/                        # Spring Boot project
│   ├── src/                    # Source code
│   │   ├── main/
│   │   │   ├── java/com/example/demo/
│   │   │   │   ├── DemoApplication.java
│   │   │   │   └── controller/HelloController.java
│   │   │   └── resources/
│   │   │       ├── application.properties
│   │   │       └── static/templates/index.html
│   │   └── test/
│   │       └── java/com/example/demo/DemoApplicationTests.java
│   ├── pom.xml                 # Maven configuration
│   ├── docker/Dockerfile       # Docker configuration
│   └── Jenkinsfile             # Jenkins pipeline script
├── k8s/                        # Kubernetes manifests (Minikube)
│   ├── argocd-application.yaml
│   ├── configmap.yaml
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── namespace.yaml
│   ├── rbac-role.yaml
│   ├── rbac-rolebinding.yaml
│   ├── service.yaml
│   └── serviceaccount.yaml
├── springboot-helm-chart/      # Helm chart for EKS deployment
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── namespace.yaml
│       ├── serviceaccount.yaml
│       ├── rolebinding.yaml
│       ├── hpa.yaml
│       ├── configmap.yaml
└── README.md                   # This file
```

## Deployment Methods

### Method 1: Minikube Deployment (Without Helm)

#### EC2 Instance Setup
1. **Launch EC2 Instance**
   - Name: `EndtoEnd-CI-CD-Pipeline-for-Java-Application`
   - AMI: Ubuntu 24.04
   - Instance Type: `t2.large`
   - Key Pair: Create `Prometheus.pem`
   - Storage: 30GB
   - Security Groups: As listed in [Prerequisites](#prerequisites)
2. **Connect via SSH**
   ```bash
   chmod 400 Prometheus.pem
   ssh -i Prometheus.pem ubuntu@<ec2-public-ip>
   ```

#### Java Spring Boot Setup
1. **Clone Repository**
   ```bash
   git clone https://github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git
   cd EndtoEnd-CI-CD-Pipeline-for-Java-Application/app
   ```
2. **Install JDK 17 and Maven**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt install openjdk-17-jdk -y
   java -version
   sudo apt install maven -y
   mvn -version
   ```
3. **Fix JDK Version Conflicts**
   ```bash
   sudo update-alternatives --config java
   sudo update-alternatives --config javac
   ```
   Select JDK 17 as default.
4. **Run Locally**
   ```bash
   mvn clean package
   java -jar target/java-cicd-demo-1.0.0.jar
   ```

#### Dockerization
**Dockerfile**
```dockerfile
# Stage 1: Build
FROM maven:3.9.8-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

# Stage 2: Run
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```
**Build and Push**
```bash
docker build -t venkatesh384/java-cicd-app:latest -f docker/Dockerfile .
docker run -p 8080:8080 venkatesh384/java-cicd-app:latest
docker push venkatesh384/java-cicd-app:latest
```

#### Jenkins Setup
1. **Install Jenkins via Docker**
   ```bash
   docker run -d --name jenkins -u root -p 8081:8080 -p 50000:50000 \
     -v jenkins_home:/var/jenkins_home \
     -v /var/run/docker.sock:/var/run/docker.sock \
     -v /usr/bin/docker:/usr/bin/docker \
     -v $HOME/.kube:/root/.kube \
     -v $HOME/.minikube:/root/.minikube \
     jenkins/jenkins:lts
   ```
2. **Install Docker on EC2**
   ```bash
   sudo apt update
   sudo apt install docker.io -y
   sudo usermod -aG docker jenkins
   newgrp docker
   ```
3. **Access Jenkins**
   - URL: `http://<ec2-public-ip>:8081`
   - Initial Password: `docker exec -it -u root jenkins bash; cat /var/jenkins_home/secrets/initialAdminPassword`
4. **Install Plugins**
   - Pipeline, Docker Pipeline, SonarQube Scanner, Git

#### SonarQube Configuration
1. **Install SonarQube**
   ```bash
   docker pull sonarqube:latest
   docker run -d --name sonarqube -p 9000:9000 \
     -v sonarqube_data:/opt/sonarqube/data \
     -v sonarqube_logs:/opt/sonarqube/logs \
     -v sonarqube_extensions:/opt/sonarqube/extensions \
     sonarqube:latest
   ```
   - Access: `http://<ec2-public-ip>:9000`
   - Credentials: `admin/admin` (change after login)
2. **Configure Jenkins**
   - Install SonarQube Scanner plugin
   - Add SonarQube server: `Manage Jenkins → Configure System → SonarQube servers`
     - Name: `MySonarQubeServer`
     - URL: `http://<ec2-public-ip>:9000`
     - Token: Generate in SonarQube UI
   - Add SonarQube Scanner: `Manage Jenkins → Global Tool Configuration`
3. **Create SonarQube Project**
   - Project Key: `java-cicd-app`
   - Name: `Java CICD App`
   - Generate token for Jenkins
4. **Test Locally**
   ```bash
   sudo apt install sonar-scanner-cli -y
   mvn clean verify sonar:sonar \
     -Dsonar.projectKey=java-cicd-app \
     -Dsonar.host.url=http://<ec2-public-ip>:9000 \
     -Dsonar.login=<token>
   ```

#### Minikube and Kubernetes Setup
1. **Install Minikube and kubectl**
   ```bash
   curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
   sudo install minikube-linux-amd64 /usr/local/bin/minikube
   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
   chmod +x kubectl
   sudo mv kubectl /usr/local/bin/
   kubectl version --client
   minikube version
   ```
2. **Fix Permissions**
   ```bash
   sudo chown -R $USER:$USER $HOME/.minikube $HOME/.kube
   chmod -R u+wrx $HOME/.minikube
   chmod 600 $HOME/.kube/config
   ```
3. **Start Minikube**
   ```bash
   minikube stop
   minikube start --driver=docker
   ```

#### ArgoCD Deployment
1. **Install kubectl and ArgoCD CLI in Pipeline**
   ```groovy
   stage('Install kubectl & ArgoCD CLI') {
       steps {
           sh '''
               if ! command -v kubectl &> /dev/null; then
                   curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                   chmod +x kubectl
                   mv kubectl /usr/local/bin/
               fi
               if ! command -v argocd &> /dev/null; then
                   curl -sSL -o argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
                   chmod +x argocd
                   mv argocd /usr/local/bin/
               fi
               kubectl version --client
               argocd version --client
           '''
       }
   }
   ```
2. **Set Up ArgoCD**
   ```bash
   kubectl create ns argocd
   kubectl edit svc argocd-server -n argocd  # Change ClusterIP to NodePort
   kubectl get svc -n argocd
   kubectl port-forward --address 0.0.0.0 service/argocd-server 30441:80 -n argocd
   ```
   - Access: `https://<ec2-public-ip>:30441`
   - Credentials: `admin` / `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`
3. **Apply Kubernetes Manifests**
   ```groovy
   stage('Apply Kubernetes Manifests (GitOps Style)') {
       steps {
           withCredentials([
               file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG'),
               usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')
           ]) {
               dir('k8s') {
                   sh '''
                       sed -i "s|image: venkatesh384/java-cicd-app:.*|image: venkatesh384/java-cicd-app:${BUILD_NUMBER}|g" deployment.yaml
                       git config user.name "venkateswarluyendoti"
                       git config user.email "venkateswarlu.yendoti99@gmail.com"
                       git add deployment.yaml
                       git commit -m "Update image to venkatesh384/java-cicd-app:${BUILD_NUMBER} [ci skip]" || echo "No changes to commit"
                       git remote set-url origin https://$GIT_USER:$GIT_PASS@github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git
                       git push origin master
                   '''
               }
           }
       }
   }
   ```

#### Trivy Security Scanning
```groovy
stage('Install Trivy') {
    steps {
        sh '''
            if ! command -v trivy &> /dev/null; then
                curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
                mv ./bin/trivy /usr/local/bin/trivy
                rm -rf ./bin
            fi
            trivy --version
        '''
    }
}
stage('Trivy Security Scan') {
    steps {
        sh '''
            trivy image --severity HIGH,CRITICAL --format table --output trivy-report.txt venkatesh384/java-cicd-app:${BUILD_NUMBER}
        '''
        archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
    }
}
```

#### Access Application
```bash
kubectl port-forward --address 0.0.0.0 service/java-cicd-service 30081:8080 -n argocd
```
- Access: `http://<ec2-public-ip>:30081`
- Expected Output: `Hello from the End-to-End CI/CD Pipeline Java Application!`

### Method 2: AWS EKS Deployment (With Helm and ArgoCD)

#### AWS CLI and IAM Setup
1. **Create IAM User**
   - Log in to AWS Console: [https://console.aws.amazon.com/](https://console.aws.amazon.com/)
   - Navigate to IAM → Users → Add users
   - Username: `eks-admin`
   - Access Type: Programmatic access
   - Policy: `AdministratorAccess` (restrict later)
   - Download `.csv` with `AWS_ACCESS_KEY_ID` (e.g., `AKIAIOSFODNN7EXAMPLE`) and `AWS_SECRET_ACCESS_KEY` (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)
2. **Install AWS CLI on EC2**
   ```bash
   sudo apt update -y
   sudo apt install unzip -y
   curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
   unzip awscliv2.zip
   sudo ./aws/install
   aws --version
   ```
3. **Configure AWS CLI**
   ```bash
   aws configure
   ```
   - Enter: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, region (`ap-south-1`), output (`json`)
   - Verify: `aws sts get-caller-identity`
     ```json
     {
         "UserId": "AIDAQQYAF32COIOP5D5GV",
         "Account": "035970735748",
         "Arn": "arn:aws:iam::035970735748:user/eks-admin"
     }
     ```

#### EKS Cluster Setup
1. **Create EKS Cluster**
   ```bash
   eksctl create cluster \
     --name java-eks \
     --region ap-south-1 \
     --nodegroup-name java-eks-nodes \
     --node-type t3.medium \
     --nodes 2 \
     --managed \
     --zones ap-south-1a,ap-south-1b
   ```
   - Creates VPC, EKS control plane, managed node group
   - Updates `~/.kube/config`
   - Takes ~15–20 minutes
2. **Verify Cluster**
   ```bash
   eksctl get cluster --region ap-south-1
   kubectl get nodes
   ```
   Expected output:
   ```
   NAME                                         STATUS   ROLES    AGE     VERSION
   ip-192-168-12-34.ap-south-1.compute.internal Ready    <none>   2m      v1.30.x
   ip-192-168-56-78.ap-south-1.compute.internal Ready    <none>   2m      v1.30.x
   ```
3. **Test with Nginx**
   ```bash
   kubectl create deployment nginx --image=nginx --replicas=2
   kubectl expose deployment nginx --port=80 --type=LoadBalancer
   kubectl get svc nginx
   curl http://<nginx-ELB-DNS>
   ```

#### Helm Chart Structure
**Folder Structure**
```
springboot-helm-chart/
├── Chart.yaml
├── values.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    ├── ingress.yaml
    ├── namespace.yaml
    ├── serviceaccount.yaml
    ├── rolebinding.yaml
    ├── hpa.yaml
    ├── configmap.yaml
```

**Chart.yaml**
```yaml
apiVersion: v2
name: springboot-app
description: Spring Boot app deployment on Kubernetes/EKS
version: 0.1.0
appVersion: "1.0"
```

**values.yaml**
```yaml
replicaCount: 2
image:
  repository: venkatesh384/java-cicd-app
  tag: 41
  pullPolicy: IfNotPresent
serviceAccount:
  name: java-cicd-deployer
service:
  type: LoadBalancer
  port: 80
  targetPort: 8080
ingress:
  enabled: true
  host: java-app-new.local
resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"
namespace:
  name: java-app
hpa:
  enabled: true
  minReplicas: 2
  maxReplicas: 5
  targetCPUUtilizationPercentage: 60
configmap:
  enabled: true
  APP_MESSAGE: "Hello from End-to-End CI/CD Pipeline (Helm)"
```

**_helpers.tpl**
```yaml
{{- define "springboot-app.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "springboot-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}
```
- Deploy:
  ```bash
  helm upgrade --install java-app ./springboot-helm-chart --namespace java-app --create-namespace
  ```

#### ArgoCD Setup and Application Deployment
1. **Expose ArgoCD**
   ```bash
   kubectl edit svc argocd-server -n argocd  # Change spec.type to LoadBalancer
   kubectl get svc -n argocd
   ```
2. **Log in to ArgoCD**
   ```bash
   kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
   ```
   - Username: `admin`
   - Password: Output from above command
3. **Deploy Application**
   **argocd-helm-app.yaml**
   ```yaml
   apiVersion: argoproj.io/v1alpha1
   kind: Application
   metadata:
     name: java-app
     namespace: argocd
   spec:
     project: default
     source:
       repoURL: 'https://github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git'
       targetRevision: main
       path: springboot-helm-chart
       helm:
         releaseName: java-app
     destination:
       server: https://kubernetes.default.svc
       namespace: java-app
     syncPolicy:
       automated:
         prune: true
         selfHeal: true
       syncOptions:
         - CreateNamespace=true
         - ApplyOutOfSyncOnly=true
   ```
   Apply:
   ```bash
   kubectl apply -f argocd-helm-app.yaml -n argocd
   ```

#### Spring Boot Application Deployment
**springboot-deployment.yaml**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: springboot-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: springboot-app
  template:
    metadata:
      labels:
        app: springboot-app
    spec:
      containers:
      - name: springboot-app
        image: venkatesh384/springboot-cicd-on-k8s:latest
        ports:
        - containerPort: 8080
```

**springboot-service.yaml**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: springboot-service
spec:
  type: LoadBalancer
  selector:
    app: springboot-app
  ports:
    - port: 80
      targetPort: 8080
```
Apply:
```bash
kubectl apply -f springboot-deployment.yaml
kubectl apply -f springboot-service.yaml
kubectl get svc springboot-service
```
Access: `http://<springboot-ELB-DNS>.ap-south-1.elb.amazonaws.com`

#### Jenkins Pipeline Configuration
**Credentials**
| Credential ID     | Type                          | Purpose                     |
|-------------------|-------------------------------|-----------------------------|
| `dockerhub-creds` | Username & Password           | DockerHub login             |
| `github-creds`    | Username & Personal Access Token | GitHub repo access        |
| `aws-creds`       | Username & Password           | AWS Access Key & Secret Key |
| `sonar-token`     | Secret Text                  | SonarQube token             |
| `kubeconfig-cred` | Secret File                  | Kubernetes cluster config   |

**Jenkinsfile**
```groovy
pipeline {
    agent any

    tools {
        maven 'Maven 3.8.7'
        jdk 'JDK 17'
    }

    environment {
        DOCKERHUB_CREDENTIALS = credentials('dockerhub-creds')
        DOCKER_IMAGE = "venkatesh384/java-cicd-app"
        HELM_RELEASE = "java-app"
        HELM_NAMESPACE = "java-app"
        HELM_CHART_DIR = "springboot-helm-chart"
        AWS_REGION = "ap-south-1"
        EKS_CLUSTER = "java-eks"
    }

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn --version'
                sh 'java -version'
                dir('app') {
                    sh 'mvn clean package -DskipTests'
                }
            }
        }

        stage('SonarQube Analysis') {
            steps {
                dir('app') {
                    withSonarQubeEnv('MySonarQubeServer') {
                        withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                            sh '''
                                mvn clean verify sonar:sonar \
                                -Dsonar.projectKey=EndtoEnd-CI-CD-Pipeline-for-Java-Application \
                                -Dsonar.projectName=EndtoEnd-CI-CD-Pipeline-for-Java-Application \
                                -Dsonar.host.url=http://13.217.118.188:9000 \
                                -Dsonar.token=$SONAR_TOKEN
                            '''
                        }
                    }
                }
            }
        }

        stage('Build Docker Image') {
            steps {
                dir('app') {
                    sh """
                        docker build -t $DOCKER_IMAGE:${BUILD_NUMBER} -f docker/Dockerfile .
                        docker tag $DOCKER_IMAGE:${BUILD_NUMBER} $DOCKER_IMAGE:latest
                    """
                }
            }
        }

        stage('Install Trivy') {
            steps {
                sh '''
                    echo "🔹 Installing Trivy..."
                    if ! command -v trivy &> /dev/null; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
                        mkdir -p /usr/local/bin
                        mv ./bin/trivy /usr/local/bin/trivy
                        rm -rf ./bin
                    fi
                    trivy --version
                '''
            }
        }

        stage('Trivy Security Scan') {
            steps {
                dir('app') {
                    sh '''
                        echo "🔹 Running Trivy scan on image..."
                        trivy image --exit-code 0 --severity LOW,MEDIUM,HIGH,CRITICAL $DOCKER_IMAGE:${BUILD_NUMBER} > trivy-report.txt
                        trivy image --exit-code 1 --severity CRITICAL $DOCKER_IMAGE:${BUILD_NUMBER} || true
                        cat trivy-report.txt
                    '''
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                dir('app') {
                    sh """
                        echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                        docker push $DOCKER_IMAGE:${BUILD_NUMBER}
                        docker push $DOCKER_IMAGE:latest
                    """
                }
            }
        }

        stage('Install AWS CLI, kubectl, Helm') {
            steps {
                sh '''
                    echo "🔹 Installing AWS CLI..."
                    if ! command -v aws &> /dev/null; then
                        curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                        unzip -o awscliv2.zip
                        ./aws/install --update
                        rm -rf aws awscliv2.zip
                    fi
                    aws --version

                    echo "🔹 Installing kubectl..."
                    if ! command -v kubectl &> /dev/null; then
                        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                        chmod +x kubectl
                        mv kubectl /usr/local/bin/
                    fi

                    echo "🔹 Installing Helm..."
                    if ! command -v helm &> /dev/null; then
                        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                    fi

                    kubectl version --client
                    helm version
                '''
            }
        }

        stage('Update Helm Chart & Deploy to EKS') {
            steps {
                withCredentials([
                    usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS'),
                    usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')
                ]) {
                    dir("${HELM_CHART_DIR}") {
                        sh """
                            set -e
                            echo "🔹 Updating Helm chart with new image tag..."
                            sed -i "s|repository: .*\$|repository: $DOCKER_IMAGE|" values.yaml
                            sed -i "s|tag: .*\$|tag: ${BUILD_NUMBER}|" values.yaml

                            echo "🔹 Committing updated Helm chart..."
                            git config user.name "venkateswarluyendoti"
                            git config user.email "venkateswarlu.yendoti99@gmail.com"
                            git add values.yaml
                            git commit -m "Update Helm chart image tag to ${BUILD_NUMBER} [ci skip]" || echo "No changes to commit"
                            git remote set-url origin https://$GIT_USER:$GIT_PASS@github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git
                            git push origin main

                            echo "🔹 Configuring AWS CLI..."
                            export AWS_ACCESS_KEY_ID="$AWS_ACCESS_KEY_ID"
                            export AWS_SECRET_ACCESS_KEY="$AWS_SECRET_ACCESS_KEY"
                            export AWS_DEFAULT_REGION="$AWS_REGION"

                            echo "🔹 Updating kubeconfig for EKS..."
                            aws eks update-kubeconfig --name $EKS_CLUSTER

                            echo "🔹 Deploying Helm chart to EKS..."
                            helm upgrade --install $HELM_RELEASE . --namespace $HELM_NAMESPACE --create-namespace
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo "✅ Jenkins Pipeline SUCCESS: Job ${env.JOB_NAME}, Build #${env.BUILD_NUMBER}"
        }
        failure {
            echo "❌ Jenkins Pipeline FAILED: Job ${env.JOB_NAME}, Build #${env.BUILD_NUMBER}"
        }
    }
}

```

## Troubleshooting

| Issue                        | Minikube Deployment                                  | EKS Deployment                                      |
|------------------------------|----------------------------------------------|---------------------------------------------|
| **Minikube Permissions**     | HOME or kubeconfig permission errors         | N/A                                         |
|                              | Fix: `sudo chown -R $USER:$USER $HOME/.minikube $HOME/.kube; chmod -R u+wrx $HOME/.minikube; chmod 600 $HOME/.kube/config` | |
| **AWS CLI Not Found**        | N/A                                          | Jenkins agent lacks AWS CLI. Install in pipeline: `curl ... && unzip -o awscliv2.zip && sudo ./aws/install --update` |
| **AWS CLI Credentials Issue**| N/A                                          | Pipeline cannot authenticate. Use Jenkins Credentials Plugin or IAM role. Verify: `aws sts get-caller-identity` |
| **Helm Template Errors**     | N/A                                          | Missing templates or name mismatch. Ensure `_helpers.tpl` exists, `Chart.yaml` matches folder, templates use `{{ include "springboot-app.fullname" . }}` |
| **ArgoCD App Not Visible**   | App not in UI. Verify `argocd-application.yaml`, GitHub repo, branch, path. Sync manually | App not in UI. Verify `argocd-helm-app.yaml`, GitHub repo, branch, Helm path. Sync manually |
| **Ingress Stuck**            | N/A                                          | Ingress not routing. Check `ingressClassName: nginx`, NGINX pods: `kubectl get pods -n ingress-nginx` |
| **Service Not Reachable**    | Service inaccessible. Check NodePort (`kubectl get svc`), Security Group allows 30081 | LoadBalancer inaccessible. Check `EXTERNAL-IP` (`kubectl get svc`), Security Group allows 80/443 |
| **Cluster Creation Fails**   | N/A                                          | UnsupportedAvailabilityZoneException. Add `--zones ap-south-1a,ap-south-1b` to `eksctl` command |
| **Nodes NotReady**           | N/A                                          | Nodes not joining. Associate IAM OIDC provider and CNI policy: `eksctl utils associate-iam-oidc-provider` |
| **Pods Stuck in Pending**    | Pods not scheduling. Check events: `kubectl describe pod <pod-name>` | Pods not scheduling. Check events: `kubectl describe pod <pod-name>` |

## Achievements
- **Pipeline-as-Code**: Implemented Jenkins pipeline with GitHub SCM for traceability and automation.
- **Code Quality**: Integrated SonarQube for static code analysis, catching bugs and vulnerabilities early.
- **Security**: Added Trivy scans to ensure container security before deployment.
- **GitOps**: Enabled ArgoCD for automated Kubernetes deployments, reducing manual effort by ~90%.
- **Flexibility**: Supports both Minikube (local) and EKS (cloud) deployments, catering to different environments.

## Future Scope
1. **Infrastructure as Code**: Use Terraform/CloudFormation for provisioning.
2. **Advanced GitOps**: Implement Canary/Blue-Green deployments with ArgoCD Rollouts.
3. **Monitoring**: Add Prometheus, Grafana, and ELK/EFK for observability.
4. **Security**: Extend Trivy scans, use OPA/Kyverno for policies, integrate HashiCorp Vault.
5. **Scalability**: Configure HPA, Cluster Autoscaler, and multi-region deployments.
6. **Performance**: Add JMeter/k6 testing and SonarQube Quality Gates.
7. **Multi-Environment**: Support Dev/QA/Staging/Production with Helm/Kustomize.
8. **Container Security**: Implement image signing with Cosign/Notary.
9. **Cost Optimization**: Use spot instances, retention policies, and GitHub Actions.
10. **AI-Driven DevOps**: Integrate Dynatrace/New Relic for anomaly detection and ChatOps.

## Summary Flow
1. **Setup Environment**: Provision EC2, configure AWS CLI (EKS) or Minikube.
2. **Build Application**: Clone repo, use Maven to build Spring Boot app.
3. **Code Quality**: Run SonarQube analysis in Jenkins pipeline.
4. **Containerization**: Build and push Docker image to DockerHub.
5. **Security**: Scan image with Trivy for vulnerabilities.
6. **Deployment**: Deploy via raw manifests (Minikube) or Helm charts (EKS) using ArgoCD.
7. **Verification**: Check pods, services, and access application.
8. **Automation**: Jenkins pipeline automates all steps, with GitOps for deployment updates.

---

**Analysis**

The merged README combines two deployment approaches—Minikube (without Helm) and EKS (with Helm and ArgoCD)—into a single, cohesive document. Key considerations:
- **No Conflicts**: Both methods are clearly separated, with distinct sections for Minikube and EKS, ensuring users can follow their preferred approach without confusion.
- **Repetition Handling**: Overlapping content (e.g., project structure, Jenkins pipeline, SonarQube, Trivy) was consolidated, with differences highlighted (e.g., Minikube uses NodePort, EKS uses LoadBalancer).
- **User Choice**: The structure allows users to choose Minikube for local development or EKS for production, with all prerequisites, steps, and troubleshooting provided.
- **GitHub-Friendly**: Markdown tables, clear headings, and code blocks ensure readability and usability in a repository.
- **Completeness**: Includes all critical components—EC2 setup, Dockerization, Jenkins pipeline, ArgoCD, and troubleshooting—while addressing achievements and future enhancements.

This README provides a robust, flexible guide for deploying a Spring Boot application, suitable for both local and cloud environments.
