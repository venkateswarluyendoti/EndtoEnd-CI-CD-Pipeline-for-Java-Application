## Architecture Overview

The pipeline automates the process from code commit to deployment:
- **Minikube**: Uses raw Kubernetes manifests for local development, deployed via ArgoCD on an EC2 instance.
- **EKS**: Uses Helm charts for production-grade deployment on AWS EKS, managed via ArgoCD and Jenkins.

![Minikube and EKS Architecture](https://github.com/venkateswarluyendoti/EndtoEnd-CI-CD-Pipeline-for-Java-Application/blob/main/architecture_minikube_eks.jpg)