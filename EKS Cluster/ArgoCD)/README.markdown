# Spring Boot CI/CD Pipeline on AWS EKS with Jenkins, Helm, and ArgoCD

This repository provides a comprehensive guide to setting up an end-to-end CI/CD pipeline for a Spring Boot application deployed to AWS EKS using Jenkins, Docker, Helm, and ArgoCD. It includes detailed steps for AWS CLI configuration, EKS cluster creation, Helm chart deployment, ArgoCD integration, and troubleshooting common issues. The pipeline incorporates static code analysis with SonarQube and container security scanning with Trivy.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Project Structure](#project-structure)
- [AWS CLI and IAM Setup](#aws-cli-and-iam-setup)
- [EKS Cluster Setup](#eks-cluster-setup)
- [Helm Chart Structure](#helm-chart-structure)
- [ArgoCD Setup and Application Deployment](#argocd-setup-and-application-deployment)
- [Spring Boot Application Deployment](#spring-boot-application-deployment)
- [Jenkins Pipeline Configuration](#jenkins-pipeline-configuration)
- [Troubleshooting](#troubleshooting)
- [Summary Flow](#summary-flow)

## Prerequisites

| Item                | Details                                                                 |
|---------------------|-------------------------------------------------------------------------|
| **EC2 Instance**    | Ubuntu 24.04, 2 vCPU, 4GB RAM, Docker installed, internet access        |
| **AWS Account**     | IAM user with AdministratorAccess or permissions for EKS, EC2, IAM, etc. |
| **AWS CLI**         | Version 2 installed and configured (`aws configure`)                    |
| **Jenkins**         | Installed on EC2 or Docker, with plugins: Git, Pipeline, Docker Pipeline, Kubernetes CLI, SonarQube Scanner, Credentials Binding, GitHub Branch Source |
| **Maven & JDK**     | Maven 3.8.7, JDK 17                                                    |
| **DockerHub**       | Repository: `venkatesh384/java-cicd-app`, credentials stored in Jenkins  |
| **SonarQube**       | Server URL and token configured in Jenkins                              |

## Project Structure

```
EndtoEnd-CI-CD-Pipeline-for-Java-Application/
├── app/                        # Spring Boot project
│   ├── src/                    # Source code
│   ├── pom.xml                 # Maven configuration
│   └── docker/Dockerfile       # Docker configuration
├── springboot-helm-chart/      # Helm chart for Kubernetes deployment
│   ├── Chart.yaml              # Helm chart metadata
│   ├── values.yaml             # Helm chart values
│   └── templates/              # Helm templates
│       ├── deployment.yaml
│       ├── service.yaml
│       ├── ingress.yaml
│       ├── namespace.yaml
│       ├── serviceaccount.yaml
│       ├── rolebinding.yaml
│       ├── hpa.yaml
│       ├── configmap.yaml
└── Jenkinsfile                 # Jenkins pipeline script
```

## AWS CLI and IAM Setup

### Step 1: Create IAM User
1. Log in to AWS Console: [https://console.aws.amazon.com/](https://console.aws.amazon.com/)
2. Navigate to IAM → Users → Add users
3. Set username (e.g., `eks-admin`), select **Programmatic access**
4. Attach **AdministratorAccess** policy (for testing; restrict later)
5. Download `.csv` with **AWS Access Key ID** (e.g., `AKIAIOSFODNN7EXAMPLE`) and **AWS Secret Access Key** (e.g., `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`)

### Step 2: Install AWS CLI on EC2
```bash
sudo apt update -y
sudo apt install unzip -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
aws --version
```

### Step 3: Configure AWS CLI
```bash
aws configure
```
Enter:
- **AWS Access Key ID**: From IAM user
- **AWS Secret Access Key**: From IAM user
- **Default region name**: `ap-south-1`
- **Default output format**: `json`

Verify:
```bash
aws sts get-caller-identity
```
Expected output:
```json
{
    "UserId": "AIDAQQYAF32COIOP5D5GV",
    "Account": "035970735748",
    "Arn": "arn:aws:iam::035970735748:user/eks-admin"
}
```

## EKS Cluster Setup

### Step 1: Create EKS Cluster
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
- Creates VPC, EKS control plane, and managed node group
- Updates `~/.kube/config`
- Takes ~15–20 minutes

  <img width="1910" height="289" alt="Screenshot 2025-08-23 102344" src="https://github.com/user-attachments/assets/ae72e7f0-1ab9-49f0-84b7-730a1fb79b71" />


<img width="1920" height="1080" alt="Screenshot (222)" src="https://github.com/user-attachments/assets/0c36e8af-e319-4cbb-a2bb-53a7f735b54f" />



### Step 2: Verify Cluster
```bash
eksctl get cluster --region ap-south-1
kubectl get nodes
```
Expected output for nodes:
```
NAME                                         STATUS   ROLES    AGE     VERSION
ip-192-168-12-34.ap-south-1.compute.internal Ready    <none>   2m      v1.30.x
ip-192-168-56-78.ap-south-1.compute.internal Ready    <none>   2m      v1.30.x
```

<img width="1474" height="116" alt="Screenshot 2025-08-23 102422" src="https://github.com/user-attachments/assets/4cd260ca-8a62-4197-8b85-79d770ee1a5a" />



### Step 3: Test with Nginx Deployment
```bash
kubectl create deployment nginx --image=nginx --replicas=2
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get svc nginx
curl http://<nginx-ELB-DNS>
```
<img width="1911" height="220" alt="Screenshot 2025-08-23 102618" src="https://github.com/user-attachments/assets/a870da07-d6b9-42b3-a9f6-c6fc6ef7d98d" />

<img width="1906" height="318" alt="Screenshot 2025-08-23 102724" src="https://github.com/user-attachments/assets/e50db24c-26ae-4120-a938-58b7b69a1c52" />


<img width="1920" height="1080" alt="Screenshot (223)" src="https://github.com/user-attachments/assets/af4d4abb-9287-4871-8306-2f4bd13b7b9e" />

<img width="1916" height="564" alt="image" src="https://github.com/user-attachments/assets/4cad9a33-8594-45e1-8c86-621ae5b33cab" />


## Helm Chart Structure

### Folder Structure
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

### Chart.yaml
```yaml
apiVersion: v2
name: springboot-app
description: Spring Boot app deployment on Kubernetes/EKS
version: 0.1.0
appVersion: "1.0"
```

### values.yaml
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

### Helm Fixes (_helpers.tpl)
```yaml
{{- define "springboot-app.name" -}}
{{ .Chart.Name }}
{{- end -}}

{{- define "springboot-app.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end -}}
```
- Ensure all templates reference `{{ include "springboot-app.fullname" . }}`
- Deploy:
```bash
helm upgrade --install java-app ./springboot-helm-chart --namespace java-app --create-namespace
```

## ArgoCD Setup and Application Deployment

### Step 1: Expose ArgoCD
```bash
kubectl edit svc argocd-server -n argocd  # Change spec.type to LoadBalancer
kubectl get svc -n argocd
```

### Step 2: Log in to ArgoCD
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```
- Username: `admin`
- Password: Output from above command

<img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b65d7818-6438-4929-963d-0eac7ebb6eea" />




### Step 3: Deploy Application
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

<img width="1917" height="1079" alt="Screenshot 2025-08-23 185700" src="https://github.com/user-attachments/assets/482ef47f-ba68-4e6c-918a-a55e8e8e7c5f" />




## Spring Boot Application Deployment

### Docker Build & Push
```bash
docker build -t venkatesh384/springboot-cicd-on-k8s:latest .
docker push venkatesh384/springboot-cicd-on-k8s:latest
```

### Deployment and Service Manifests
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

<img width="1910" height="325" alt="image" src="https://github.com/user-attachments/assets/ecd3c5f0-6fde-466e-babb-f1befd8e60a2" />



## Jenkins Pipeline Configuration

### Credentials Configuration
| Credential ID     | Type                          | Notes                        |
|-------------------|-------------------------------|------------------------------|
| `dockerhub-creds` | Username & Password           | DockerHub login              |
| `github-creds`    | Username & Personal Access Token | GitHub repo access         |
| `aws-creds`       | Username & Password           | AWS Access Key & Secret Key  |
| `sonar-token`     | Secret Text                  | SonarQube token              |

### Jenkinsfile
```groovy
pipeline {
    agent any
    environment {
        AWS_REGION = 'ap-south-1'
        EKS_CLUSTER = 'java-eks'
    }
    stages {
        stage('Checkout') {
            steps {
                git branch: 'main', credentialsId: 'github-creds', url: 'https://github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git'
            }
        }
        stage('Maven Build') {
            steps {
                sh 'mvn clean package -DskipTests'
            }
        }
        stage('SonarQube Analysis') {
            steps {
                withSonarQubeEnv('SonarQube') {
                    sh 'mvn clean verify sonar:sonar -Dsonar.projectKey=EndtoEnd-CI-CD-Pipeline-for-Java-Application -Dsonar.host.url=http://<SONAR_SERVER>:9000 -Dsonar.token=$SONAR_TOKEN'
                }
            }
        }
        stage('Docker Build & Push') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                    sh '''
                        docker build -t venkatesh384/java-cicd-app:$BUILD_NUMBER -f docker/Dockerfile .
                        docker tag venkatesh384/java-cicd-app:$BUILD_NUMBER venkatesh384/java-cicd-app:latest
                        docker login -u $DOCKER_USERNAME -p $DOCKER_PASSWORD
                        docker push venkatesh384/java-cicd-app:$BUILD_NUMBER
                        docker push venkatesh384/java-cicd-app:latest
                    '''
                }
            }
        }
        stage('Security Scan with Trivy') {
            steps {
                sh 'trivy image --exit-code 0 --severity LOW,MEDIUM,HIGH,CRITICAL venkatesh384/java-cicd-app:$BUILD_NUMBER > trivy-report.txt'
                sh 'cat trivy-report.txt'
            }
        }
        stage('Install Tools') {
            steps {
                sh '''
                    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
                    unzip -o awscliv2.zip && sudo ./aws/install && rm -rf awscliv2.zip
                    aws --version
                    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                    chmod +x kubectl && sudo mv kubectl /usr/local/bin/
                    kubectl version --client
                    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
                    helm version
                '''
            }
        }
        stage('Configure AWS EKS Kubeconfig') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'aws-creds', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY')]) {
                    sh '''
                        export AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID
                        export AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY
                        export AWS_DEFAULT_REGION=$AWS_REGION
                        aws eks --region $AWS_REGION update-kubeconfig --name $EKS_CLUSTER
                        kubectl get nodes
                    '''
                }
            }
        }
        stage('Helm Deployment') {
            steps {
                sh '''
                    sed -i "s|tag:.*|tag: $BUILD_NUMBER|" springboot-helm-chart/values.yaml
                    helm upgrade --install java-app ./springboot-helm-chart --namespace java-app --create-namespace
                '''
            }
        }
        stage('Commit Helm Updates') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_TOKEN')]) {
                    sh '''
                        git config user.name "jenkins-user"
                        git config user.email "jenkins@example.com"
                        git add springboot-helm-chart/values.yaml
                        git commit -m "Update Helm image tag $BUILD_NUMBER"
                        git push https://$GIT_USERNAME:$GIT_TOKEN@github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git main
                    '''
                }
            }
        }
    }
    post {
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
```


<img width="1911" height="783" alt="Screenshot 2025-08-23 161219" src="https://github.com/user-attachments/assets/25011072-ff29-44d4-9042-6103edc164b5" />



## Troubleshooting

| Issue                        | Explanation                                  | Solution                                                                 |
|------------------------------|----------------------------------------------|--------------------------------------------------------------------------|
| **AWS CLI Not Found**        | Jenkins agent lacks AWS CLI                  | Install in pipeline: `curl ... && unzip -o awscliv2.zip && sudo ./aws/install --update` or use agent with AWS CLI pre-installed |
| **AWS CLI Credentials Issue**| Pipeline cannot authenticate to AWS          | Use Jenkins Credentials Plugin or attach IAM role to EC2. Verify: `aws sts get-caller-identity` |
| **Helm Template Errors**     | Missing templates or name mismatch           | Ensure `_helpers.tpl` exists, `Chart.yaml` matches folder name, templates use `{{ include "springboot-app.fullname" . }}` |
| **ArgoCD App Not Visible**   | App not appearing in ArgoCD UI              | Verify Application YAML, GitHub repo URL, branch, and Helm chart path. Sync manually if needed |
| **Ingress Stuck**            | Ingress not routing traffic                 | Check `ingressClassName: nginx`, verify NGINX pods: `kubectl get pods -n ingress-nginx` |
| **Service Not Reachable**    | LoadBalancer inaccessible                   | Verify `EXTERNAL-IP` (`kubectl get svc`), ensure Security Group allows port 80/443, check pod labels |
| **Cluster Creation Fails**   | UnsupportedAvailabilityZoneException         | Add `--zones ap-south-1a,ap-south-1b` to `eksctl create cluster` command |
| **Nodes NotReady**           | Nodes not joining cluster                   | Associate IAM OIDC provider and CNI policy: `eksctl utils associate-iam-oidc-provider` and `eksctl create iamserviceaccount` |
| **Pods Stuck in Pending**    | Pods not scheduling                         | Check events: `kubectl describe pod <pod-name>`. Ensure VPC CNI addon and storage class are configured |

## Summary Flow

1. **Configure AWS CLI and IAM**: Set up IAM user and AWS CLI on EC2
2. **Create EKS Cluster**: Use `eksctl` to provision cluster and verify nodes
3. **Test Networking**: Deploy Nginx to confirm LoadBalancer functionality
4. **Prepare Helm Chart**: Ensure consistent naming and deploy Spring Boot app
5. **Set Up ArgoCD**: Deploy and configure application via GitOps
6. **Run Jenkins Pipeline**: Automate build, analysis, scan, and deployment
7. **Verify Deployment**: Check pods, services, and access application
8. **Troubleshoot Issues**: Address common errors with provided fixes

---

This setup is ideal for developers seeking a scalable, automated deployment pipeline with monitoring and security checks integrated.
