<h1 align="center">End-to-End CI/CD Pipeline for Java Application</h1>


<p align="center">
  Complete DevOps workflow for a <b>Spring Boot Java application</b> from AWS EC2 setup → Jenkins CI/CD → Docker → SonarQube → Kubernetes → ArgoCD GitOps deployment.
</p>

---
## 📊 Architecture & Workflow

<img width="1536" height="1024" alt="ChatGPT Image Aug 19, 2025, 02_17_06 PM" src="https://github.com/user-attachments/assets/3ba75467-6777-4ccf-b3c4-1daa26b740ce" />

## **Module 1 – AWS EC2 Instance Setup**

**Purpose:** Provision the server that hosts Jenkins, Docker, SonarQube, Minikube, and the application.

### Steps:

1. **Login AWS Console → EC2 → Launch Instance**
   - **Name:** `EndtoEnd-CI-CD-Pipeline-for-Java-Application`
   - **AMI:** Ubuntu
   - **Instance Type:** `t2.large`
   - **Key Pair:** Create new key pair (`Prometheus.pem`)

2. **Configure Security Groups (Inbound Rules):**

| Port   | Protocol | Source     | Description             |
|--------|----------|------------|-------------------------|
| 30441  | TCP      | 0.0.0.0/0 | ArgoCD NodePort         |
| 9000   | TCP      | 0.0.0.0/0 | SonarQube               |
| 8080   | TCP      | 0.0.0.0/0 | Java CI/CD App          |
| 8443   | TCP      | 0.0.0.0/0 | Kubernetes API          |
| 80     | TCP      | 0.0.0.0/0 | ArgoCD Server           |
| 30081  | TCP      | 0.0.0.0/0 | Java CICD Service       |
| 22     | TCP      | 0.0.0.0/0 | SSH                     |
| 50000  | TCP      | 0.0.0.0/0 | Jenkins Agents          |

3. **Configure Storage:** 30GB

4. **Connect via SSH:**
```bash
chmod 400 "Prometheus.pem"
ssh -i "Prometheus.pem" ubuntu@<ec2-public-ip>
```
Prompt should appear like:

```bash
ubuntu@ip-172-31-39-62:~$
```
  ## <img width="1919" height="893" alt="Screenshot 2025-08-18 201737" src="https://github.com/user-attachments/assets/bd1d5fc7-1beb-49bd-8c06-3292f5a3845b" />
## <img width="1869" height="900" alt="Screenshot 2025-08-18 202139" src="https://github.com/user-attachments/assets/ab2f36b0-c3a0-4707-860b-d7bf8d7ce17c" />
## <img width="1877" height="885" alt="Screenshot 2025-08-18 202206" src="https://github.com/user-attachments/assets/e86b342e-0f91-4ebc-96d9-604ea2295848" />
## <img width="1856" height="609" alt="Screenshot 2025-08-18 202542" src="https://github.com/user-attachments/assets/19725943-d6bb-49a1-8eef-b03b352e0985" />
## <img width="1838" height="925" alt="Screenshot 2025-08-18 202618" src="https://github.com/user-attachments/assets/a7575f46-59cc-4c59-97de-af1434d8d512" />

## **Module 2 – Project Folder Structure**
```bash
EndtoEnd-CI-CD-Pipeline-for-Java-Application/
├── app
│   ├── Jenkinsfile
│   ├── README.md
│   ├── docker/Dockerfile
│   ├── helm/java-cicd-app/...
│   ├── pom.xml
│   ├── src/...
│   └── target/...
└── k8s
    ├── argocd-application.yaml
    ├── configmap.yaml
    ├── deployment.yaml
    ├── hpa.yaml
    ├── namespace.yaml
    ├── rbac-role.yaml
    ├── rbac-rolebinding.yaml
    ├── service.yaml
    └── serviceaccount.yaml
```

## **Module 3 – Java Spring Boot Setup and Environment**
 **Clone Project and Install Prerequisites**
 ```bash
git clone https://github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git
cd EndtoEnd-CI-CD-Pipeline-for-Java-Application/app
```
```bash
sudo apt update && sudo apt upgrade -y
## Install JDK 17
sudo apt install openjdk-17-jdk -y
java -version
```

### JDK Version Conflict Fix
**If multiple JDK versions exist:**
```bash
sudo update-alternatives --config java
sudo update-alternatives --config javac
```
**Select JDK 17 as the default.**

**Install Maven**
```bash
sudo apt install maven -y
mvn -version
```

**Run the application locally:**
```bash
mvn clean package
java -jar target/java-cicd-demo-1.0.0.jar
```

## <img width="1884" height="1025" alt="Screenshot 2025-08-18 202819" src="https://github.com/user-attachments/assets/700de6b6-5447-46f4-a49c-bdf1b4ce70ba" />
## <img width="1910" height="384" alt="Screenshot 2025-08-18 202917" src="https://github.com/user-attachments/assets/c01cb1b2-2254-456f-aa73-00c42b47e68e" />

## **Module 4 – Dockerization**

**Dockerfile:**
```bash
**Stage 1: Build**
FROM maven:3.9.8-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline
COPY src ./src
RUN mvn clean package -DskipTests

 **Stage 2: Run**
FROM openjdk:17-jdk-slim
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
```

# Build & Run
```bash
docker build -t venkatesh384/java-cicd-app:latest -f docker/Dockerfile .
docker run -p 8080:8080 venkatesh384/java-cicd-app:latest
docker push venkatesh384/java-cicd-app:latest
```
## <img width="1909" height="825" alt="Screenshot 2025-08-18 203114" src="https://github.com/user-attachments/assets/a47e21e4-1a4c-4828-b1a2-e327224455be" />

## **Module 5 – Jenkins CI/CD Pipeline**
**Install Jenkins via Docker**
```bash
docker run -d \
  --name jenkins \
  -u root \
  -p 8081:8080 \
  -p 50000:50000 \
  -v jenkins_home:/var/jenkins_home \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /usr/bin/docker:/usr/bin/docker \
  -v $HOME/.kube:/root/.kube \
  -v $HOME/.minikube:/root/.minikube \
  jenkins/jenkins:lts
```
## <img width="965" height="656" alt="Screenshot 2025-08-18 203412" src="https://github.com/user-attachments/assets/ffb43dd7-8e72-4620-90f5-3af6c944b5b9" />

**Notes:**

**-u root allows Jenkins to run as root**

**/var/run/docker.sock allows Jenkins to control Docker**

**Inside container, install Docker CLI if needed:**
```bash
docker exec -it -u root jenkins bash
cat /var/jenkins_home/secrets/initialAdminPassword
```

**Install Docker on EC2 for Jenkins:**
```bash
sudo apt update
sudo apt install docker.io -y
sudo usermod -aG docker jenkins
newgrp docker
```
# Jenkins Pipeline

**Checkout GitHub, Maven build, SonarQube, Docker build, Trivy scan, Kubernetes/ArgoCD deployment.**

### Required Plugins
```bash
1. Pipeline

2. Docker Pipeline

3. SonarQube Scanner

4. Git plugin
```
### Pipeline Credentials:
```bash
Credential ID	          Type	                           Purpose
dockerhub-creds	    Username & Password	               DockerHub login
sonar-token	        Secret Text	                       SonarQube authentication
kubeconfig-cred	    Secret File                        Kubernetes cluster config
github-creds	    Username & Password	               GitHub push access
```
## <img width="1770" height="1062" alt="Screenshot 2025-08-18 203527" src="https://github.com/user-attachments/assets/60728c3d-e6d9-42b7-8976-26d3f01a3975" />
## <img width="1780" height="1001" alt="Screenshot 2025-08-18 203621" src="https://github.com/user-attachments/assets/0713bef1-154e-4a06-a8f4-e66b82c3677a" />
## <img width="1783" height="1004" alt="Screenshot 2025-08-18 203723" src="https://github.com/user-attachments/assets/409d30a4-6fb1-4dfe-80fb-e05148ec1a4b" />
## <img width="1845" height="970" alt="Screenshot 2025-08-18 203844" src="https://github.com/user-attachments/assets/240408b0-7647-43ed-b441-bec8fa60ec0f" />

## **Module 6 – SonarQube Installation & Configuration**

**Purpose: Run static code analysis to detect bugs, code smells, and security vulnerabilities before deployment.**

**Step 1 – SonarQube Installation Using Docker**
  --------------------------------------------
```bash
docker pull sonarqube:latest

docker run -d \
  --name sonarqube \
  -p 9000:9000 \
  -v sonarqube_data:/opt/sonarqube/data \
  -v sonarqube_logs:/opt/sonarqube/logs \
  -v sonarqube_extensions:/opt/sonarqube/extensions \
  sonarqube:latest
```

**Access SonarQube UI: http://<server-ip>:9000**
**Default credentials: admin/admin (change after first login)**

**Step 2 – Configure SonarQube in Jenkins**
  ----------------------------------------
**Manage Jenkins → Plugins → Install SonarQube Scanner for Jenkins**

**Manage Jenkins → Configure System → SonarQube servers → Add:**

**Name: MySonarQubeServer**

**Server URL: http://<sonarqube-ip>:9000**

**Authentication Token: Generated from SonarQube UI**

**Manage Jenkins → Global Tool Configuration → Add SonarQube Scanner with name SonarScanner**

## <img width="1911" height="1079" alt="Screenshot 2025-08-18 204106" src="https://github.com/user-attachments/assets/90537db6-23df-4655-aa62-a2e835dc078b" />

**Step 3 – Create SonarQube Project**
  ----------------------------------
**Open SonarQube UI → Projects → Create Project**

**Project Key: java-cicd-app**

**Name: Java CICD App**

**Generate token → Save for Jenkins credentials**

**Step 4 – Update Jenkinsfile**
  ---------------------------
```bash
stage('SonarQube Analysis') {
    steps {
        dir('app') {
            withSonarQubeEnv('MySonarQubeServer') {
                withCredentials([string(credentialsId: 'sonar-token', variable: 'SONAR_TOKEN')]) {
                    sh '''
                        mvn clean verify sonar:sonar \
                        -Dsonar.projectKey=EndtoEnd-CI-CD-Pipeline-for-Java-Application \
                        -Dsonar.projectName=EndtoEnd-CI-CD-Pipeline-for-Java-Application \
                        -Dsonar.host.url=http://<sonarqube-ip>:9000 \
                        -Dsonar.token=$SONAR_TOKEN
                    '''
                }
            }
        }
    }
}
```

**Step 5 – Local Testing**
```bash
brew install sonar-scanner  # Mac
sudo apt install sonar-scanner-cli -y  # Ubuntu
```
```bash
mvn clean verify sonar:sonar \
  -Dsonar.projectKey=java-cicd-app \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=<token>
```

## <img width="1794" height="1027" alt="Screenshot 2025-08-18 204015" src="https://github.com/user-attachments/assets/4cd8612a-5fb6-4c1f-a857-c9311da407be" />

## **Module 7 – Minikube & Kubernetes Setup**

**Install Minikube & kubectl**
```bash
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
kubectl version --client
minikube version
```

# Common Permission Issues & Fixes

**Minikube HOME permission error:**
```bash
sudo chown -R $USER:$USER $HOME/.minikube
chmod -R u+wrx $HOME/.minikube
```

**Kubeconfig permission error:**
```bash
sudo chown -R $USER:$USER $HOME/.kube $HOME/.minikube
chmod -R u+wrx $HOME/.minikube
chmod 600 $HOME/.kube/config
```
# Verify
```bash
ls -ld $HOME/.kube $HOME/.minikube
ls -l $HOME/.kube/config
```

# Start Minikube:
```bash
minikube stop
minikube start --driver=docker
```

**Always run Minikube as a normal user, never with sudo.**

## **Module 8 – ArgoCD Deployment (GitOps)**

**Install kubectl & ArgoCD CLI (Jenkins Pipeline Snippet)**
```bash
stage('Install kubectl & ArgoCD CLI') {
    steps {
        sh '''
            echo "🔹 Installing kubectl..."
            if ! command -v kubectl &> /dev/null; then
                curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
                chmod +x kubectl
                mv kubectl /usr/local/bin/
            fi

            echo "🔹 Installing Argo CD CLI..."
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
```bash
Apply Kubernetes Manifests (GitOps Style)
stage('Apply Kubernetes Manifests (GitOps Style)') {
    steps {
        withCredentials([
            file(credentialsId: 'kubeconfig-cred', variable: 'KUBECONFIG'),
            usernamePassword(credentialsId: 'github-creds', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_PASS')
        ]) {
            dir('k8s') {
                sh '''
                    echo "🔹 Updating Kubernetes manifests with new image tag..."
                    sed -i "s|image: venkatesh384/java-cicd-app:.*|image: venkatesh384/java-cicd-app:${BUILD_NUMBER}|g" deployment.yaml

                    echo "🔹 Committing changes to Git repo..."
                    git config user.name "venkateswarluyendoti"
                    git config user.email "venkateswarlu.yendoti99@gmail.com"
                    git add deployment.yaml
                    git commit -m "Update image to venkatesh384/java-cicd-app:${BUILD_NUMBER} [ci skip]" || echo "No changes to commit"

                    echo "🔹 Pushing changes to GitHub..."
                    git remote set-url origin https://$GIT_USER:$GIT_PASS@github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application.git
                    git push origin master
                '''
            }
        }
    }
}
```

# ArgoCD UI Steps:
```bash
kubectl create ns argocd
```
```bash
kubectl get svc -n argocd
```
```bash
kubectl edit svc argocd-server -n argocd  # change ClusterIP → NodePort
```

## <img width="1908" height="1072" alt="Screenshot 2025-08-18 204903" src="https://github.com/user-attachments/assets/fae55826-7b9a-42da-bb6a-43d6557fe1d6" />

```bash
kubectl get svc -n argocd
```
## <img width="1902" height="1066" alt="Screenshot 2025-08-18 205010" src="https://github.com/user-attachments/assets/ecdf50b1-649c-438a-9a20-52c6d13394f4" />

## Update EC2 security group for NodePort
```bash
kubectl port-forward --address 0.0.0.0 service/argocd-server 30441:80 -n argocd
```

## Access UI: https://ec2-public-ip:30441

## <img width="1905" height="1078" alt="Screenshot 2025-08-18 205139" src="https://github.com/user-attachments/assets/73260f58-9786-409b-874b-fbc9cdd1f5bf" />

## <img width="1212" height="550" alt="Screenshot 2025-08-18 204524" src="https://github.com/user-attachments/assets/de302d66-c3e1-4c3e-99c1-13a212ec54f9" />

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo
```

## <img width="1895" height="739" alt="Screenshot 2025-08-18 205313" src="https://github.com/user-attachments/assets/9cd93cef-535a-4e09-95e5-2b44444f3a7a" />
## <img width="1806" height="1016" alt="Screenshot 2025-08-18 205458" src="https://github.com/user-attachments/assets/929fe71f-bc7c-44c5-bc7d-49803ef717b0" />
## <img width="1800" height="949" alt="Screenshot 2025-08-18 205518" src="https://github.com/user-attachments/assets/7858ebab-559b-474c-9e29-70f4af47731d" />
## <img width="1920" height="1080" alt="Screenshot (210)" src="https://github.com/user-attachments/assets/4d0dbc2a-03a9-4cf2-92ef-f3b99313de14" />

## **Module 9 – Trivy Installation & Security Scan**

**Integrate Trivy scan in Jenkinsfile (before Docker push):**
```bash
 stage('Install Trivy') {
            steps {
                sh '''
                    echo "🔹 Installing Trivy..."
                    if ! command -v trivy &> /dev/null; then
                        curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh
                        mv ./bin/trivy /usr/local/bin/trivy
                        rm -rf ./bin
                    fi

                    trivy --version
                '''
            }
        }
```
```bash
stage('Trivy Security Scan') {
    steps {
        sh '''
            trivy image --severity HIGH,CRITICAL --format table --output trivy-report.txt venkatesh384/java-cicd-app:${BUILD_NUMBER}
        '''
        archiveArtifacts artifacts: 'trivy-report.txt', allowEmptyArchive: true
    }
}
```
## **Module 10 – Access Application**
## <img width="1920" height="1080" alt="Screenshot (211)" src="https://github.com/user-attachments/assets/f5c83676-cf1b-431f-90c3-a33c89d7bb19" />
## <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/b2afd836-93fd-4a7f-8b4d-9350baa424fa" />

```bash
kubectl port-forward --address 0.0.0.0 service/java-cicd-service 30081:8080 -n argocd
```

## <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/fba304dd-87e2-4e5e-93e4-5d9c652ae316" />

**Open browser: http://ec2-public-ip:30081**


### Output: Hello from the End-to-End CI/CD Pipeline Java Application!


### <img width="1917" height="380" alt="image" src="https://github.com/user-attachments/assets/2e6f7574-a069-4b55-878d-a8bde0d4a35d" />


## 🏆 Achievements

##### * Implemented Jenkins Pipeline-as-Code with GitHub SCM, providing traceability, version control, and fully automated           CI/CD workflows.

##### * Integrated SonarQube & Trivy into Jenkins pipeline, improving code quality and catching security vulnerabilities             early in the CI process.

##### * Automated Docker image build & push to DockerHub, enabling repeatable, versioned, and portable application                   deployments.

##### * Enabled GitOps delivery with Argo CD, reducing manual deployment effort by ~90% and ensuring automated                       synchronization of Kubernetes workloads.

##### * Deployed Spring Boot app on Kubernetes (Minikube) using raw manifests, strengthening Kubernetes fundamentals                 without Helm abstraction.

## 🔭 Future Scope

### This project provides a strong foundation for CI/CD of Java applications. In the future, it can be extended to achieve enterprise-grade DevOps maturity with the following improvements:

### 1. Infrastructure as Code (IaC) & Cloud Integration

* Automate provisioning using Terraform or CloudFormation.

* Deploy on managed Kubernetes services (AWS EKS, Azure AKS, GCP GKE).

* Integrate with cloud-native databases and services.

### 2. Advanced GitOps & Progressive Delivery

* Enhance ArgoCD with Canary and Blue/Green deployments.

* Implement automated rollbacks and traffic shifting (Argo Rollouts, Flagger).

### 3. Monitoring, Logging & Alerting

* Add observability using Prometheus & Grafana dashboards.

* Centralize logs with ELK/EFK stacks.

* Configure Alertmanager for proactive notifications (Slack, Email, Teams).

### 4. Security Enhancements

* Extend Trivy scans to filesystems and Kubernetes clusters.

* Apply Kubernetes security policies with OPA (Open Policy Agent) or Kyverno.

* Use secret management solutions (HashiCorp Vault, AWS Secrets Manager).

### 5. Scalability & Reliability

* Configure Horizontal Pod Autoscaling (HPA) and Cluster Autoscaler.

* Introduce chaos engineering (LitmusChaos, Gremlin) for resiliency.

* Plan multi-region deployments with disaster recovery strategies.

### 6. Performance & Quality Gates

* Automate performance testing (JMeter, k6) in the pipeline.

* Enforce SonarQube Quality Gates for code quality and security.

* Integrate test coverage reports with Jenkins and SonarQube.

### 7. Multi-Environment Deployment

* Extend pipeline to support Dev → QA → Staging → Production.

* Use Helm values overrides or Kustomize for environment configs.

* Introduce approval gates for production releases.

### 8. Container & Registry Improvements

* Push images to multiple registries (DockerHub, ECR, GitHub Packages).

* Implement image signing & verification (Cosign, Notary) for supply chain security.

### 9. Automation & Cost Optimization

* Automate triggers via GitHub Actions or Git webhooks.

* Optimize costs with spot instances and retention policies.

* Archive unused images and logs.

### 10. AI-Driven DevOps 

* Integrate AI-based monitoring tools (e.g., Dynatrace, New Relic) with anomaly detection.

* Use ML-based predictive scaling for workloads.

* Implement ChatOps (Slack/MS Teams bots) for pipeline interactions.





