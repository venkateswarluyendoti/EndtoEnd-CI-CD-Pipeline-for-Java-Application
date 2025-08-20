# Spring Boot CI/CD Application Helm Deployment

This part covers creating a Helm chart for the Spring Boot application, deploying it to Kubernetes, integrating with ArgoCD, and troubleshooting common issues.

---

## **Module 1 – Helm Chart Creation & Deployment**

### **Folder Structure**
```bash
springboot-helm-chart/
├── Chart.yaml
├── values.yaml
├── templates/
│ ├── _helpers.tpl
│ ├── deployment.yaml
│ ├── service.yaml
│ └── ingress.yaml
```

---

### **1. Chart.yaml**
```yaml
apiVersion: v2
name: springboot-helm-chart
description: Helm chart for Spring Boot CI/CD App
type: application
version: 0.1.0
appVersion: "1.0"
```

### **2. values.yaml**

```yaml
replicaCount: 2

image:
  repository: docker.io/venkatesh384/java-cicd-app
  tag: latest
  pullPolicy: IfNotPresent

serviceAccount:
  name: java-cicd-deployer

service:
  type: NodePort
  port: 8080
  nodePort: 30090

resources:
  requests:
    cpu: "100m"
    memory: "128Mi"
  limits:
    cpu: "500m"
    memory: "512Mi"

ingress:
  enabled: true
  host: java-app-new.local

namespace:
  name: java-app
```

### **3. templates/deployment.yaml**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "springboot-helm-chart.fullname" . }}
  namespace: {{ .Values.namespace.name }}
  labels:
    app: {{ include "springboot-helm-chart.name" . }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ include "springboot-helm-chart.name" . }}
  template:
    metadata:
      labels:
        app: {{ include "springboot-helm-chart.name" . }}
    spec:
      serviceAccountName: {{ .Values.serviceAccount.name }}
      containers:
        - name: {{ include "springboot-helm-chart.name" . }}
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          imagePullPolicy: {{ .Values.image.pullPolicy }}
          ports:
            - containerPort: {{ .Values.service.port }}
          env:
            - name: APP_MESSAGE
              valueFrom:
                configMapKeyRef:
                  name: java-cicd-config
                  key: APP_MESSAGE
          readinessProbe:
            httpGet:
              path: /
              port: {{ .Values.service.port }}
            initialDelaySeconds: 5
            periodSeconds: 10
          livenessProbe:
            httpGet:
              path: /
              port: {{ .Values.service.port }}
            initialDelaySeconds: 20
            periodSeconds: 20
          resources:
            {{- toYaml .Values.resources | nindent 12 }}
            
```

### **4. templates/service.yaml**

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ include "springboot-helm-chart.fullname" . }}
  namespace: {{ .Values.namespace.name }}
  labels:
    app: {{ include "springboot-helm-chart.name" . }}
spec:
  type: {{ .Values.service.type }}
  selector:
    app: {{ include "springboot-helm-chart.name" . }}
  ports:
    - name: http
      port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
      nodePort: {{ .Values.service.nodePort }}

```
### **5. templates/ingress.yaml**

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: {{ include "springboot-helm-chart.fullname" . }}
  namespace: {{ .Values.namespace.name }}
  labels:
    app: {{ include "springboot-helm-chart.name" . }}
  annotations:
    nginx.ingress.kubernetes.io/rewrite-target: /
spec:
  rules:
    - host: {{ .Values.ingress.host }}
      http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: {{ include "springboot-helm-chart.fullname" . }}
                port:
                  number: {{ .Values.service.port }}

```

### **6. _helpers.tpl**

```yaml
{{- define "springboot-helm-chart.name" -}}
{{ .Chart.Name }}
{{- end }}

{{- define "springboot-helm-chart.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "springboot-helm-chart.labels" -}}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
app.kubernetes.io/name: {{ include "springboot-helm-chart.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/version: {{ .Chart.AppVersion }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

```
```bash
minikube start --driver=docker
```

**Helm Deployment Commands**
##### Create Helm Chart

```bash
helm create springboot-helm-chart
# Replace generated templates with the above YAML files
```

##### Install/Upgrade Helm Release

```bash
helm upgrade --install java-app ./springboot-helm-chart -n java-app --create-namespace
```
# <img width="853" height="314" alt="Screenshot 2025-08-20 173052" src="https://github.com/user-attachments/assets/8ee10da1-083c-4ab8-b6d4-fe9d5309c364" />

```bash
minikube addons enable ingress
```
# <img width="1920" height="1080" alt="Screenshot (216)" src="https://github.com/user-attachments/assets/4fa35e0c-1bb9-41a8-8b66-d5c757b5c1b6" />


##### Verify Deployment
```bash
kubectl get all -n java-app
kubectl get ingress -n java-app
helm list -n java-app
```
##### Port Forward to Access NodePort

```bash
kubectl port-forward --address 0.0.0.0 service/java-app-springboot-helm-chart 30090:8080 -n java-app
```
# <img width="1850" height="162" alt="image" src="https://github.com/user-attachments/assets/7bd76350-d88a-42f4-9a16-31e9668d4f8c" />

##### Verify via Browser
```bash
http://localhost:30090
http://java-app-new.local  # Add entry in /etc/hosts if using Ingress
```
# <img width="1908" height="350" alt="image" src="https://github.com/user-attachments/assets/3fee90fd-3e7e-4b69-834f-8e660ebbc957" />


## **Module 2 – ArgoCD Integration & Troubleshooting**

##### 1. Create ArgoCD Application
##### Port Forward to Access NodePort

```bash
kubectl port-forward --address 0.0.0.0 service/argocd-server 31163:80 -n argocd
```

# <img width="1917" height="426" alt="image" src="https://github.com/user-attachments/assets/99e63eb8-0537-48c1-88a4-b32cc61d8e80" />
# <img width="964" height="454" alt="image" src="https://github.com/user-attachments/assets/cf3812d0-41df-4fe6-a841-3170ede219c8" />

##### Save as argocd-helm-app.yaml:
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: java-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/venky2350/EndtoEnd-CI-CD-Pipeline-for-Java-Application'
    targetRevision: HEAD
    path: springboot-helm-chart
    helm:
      valueFiles:
        - values.yaml
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: java-app
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

##### Apply to ArgoCD:

```bash
kubectl apply -f argocd-helm-app.yaml -n argocd
```
# <img width="1920" height="1080" alt="Screenshot (217)" src="https://github.com/user-attachments/assets/57cda482-6a7f-41f0-ad28-0340c09a6439" />
# <img width="1920" height="1080" alt="Screenshot (218)" src="https://github.com/user-attachments/assets/dfb3ce4f-c2f7-4008-b637-6e2527369755" />


##### 2. Common Issues & Solutions

```bash
| Issue                                                | Cause                                   | Solution                                                                 |
| ---------------------------------------------------- | --------------------------------------- | ------------------------------------------------------------------------ |
| nodePort: Invalid value                              | NodePort already in use                 | Change `service.nodePort` in values.yaml or via `--set`                  |
| host ... already defined in ingress                  | Host/path conflict                      | Change `ingress.host` in values.yaml or via `--set`                      |
| Deployment ... cannot be imported                    | Existing deployment not managed by Helm | Delete old deployment: `kubectl delete deployment <name> -n <namespace>` |
| ServiceAccount not found                             | Missing SA                              | Create SA: `kubectl create sa java-cicd-deployer -n <namespace>`         |
| ArgoCD authentication required: Repository not found | Invalid repoURL or private repo         | Use correct HTTPS URL & provide credentials in ArgoCD repo settings      |
```

##### 3. Troubleshooting Flow

###### 1. Check Helm release

```bash
helm list -n java-app
helm status java-app -n java-app
```
# <img width="1914" height="455" alt="image" src="https://github.com/user-attachments/assets/863a3e48-989a-4ee1-b703-f010b4d1455d" />

###### 2. Check pods & events

```bash
kubectl get pods -n java-app
kubectl describe deployment java-app-springboot-helm-chart -n java-app
kubectl describe rs -n java-app
```
# <img width="1920" height="1080" alt="image" src="https://github.com/user-attachments/assets/1b45223c-980f-4e04-bc63-52d5b1fb4d95" />
# <img width="1884" height="366" alt="image" src="https://github.com/user-attachments/assets/79fb90af-078f-4aca-b15a-218e3d2a5f18" />
# <img width="1851" height="918" alt="image" src="https://github.com/user-attachments/assets/2ba701df-6240-4442-b4c2-91c4d6e446c9" />
# <img width="1886" height="213" alt="image" src="https://github.com/user-attachments/assets/db74b0ed-7a87-4de3-93e3-f6e3392a21ac" />

###### 3. Check services & ingress

```bash
kubectl get svc -n java-app
kubectl get ingress -n java-app
```
# <img width="1919" height="220" alt="image" src="https://github.com/user-attachments/assets/68ad4e05-ca1a-4a25-bac3-b97400b5aca5" />

###### 4. Resolve NodePort conflict

```bash
helm upgrade --install java-app ./springboot-helm-chart -n java-app --set service.nodePort=30090
```

###### 5. Resolve Ingress conflict

```bash
helm upgrade --install java-app ./springboot-helm-chart -n java-app --set ingress.host=java-app-new.local
```
###### 6. Verify access

```bash
kubectl port-forward --address 0.0.0.0 service/java-app-springboot-helm-chart 30090:8080 -n java-app
```

##### 4. Clean Up Conflicting Resources

```bash
kubectl delete deployment java-app-springboot-helm-chart -n java-app
kubectl delete service java-app-springboot-helm-chart -n java-app
kubectl delete ingress java-app-springboot-helm-chart -n java-app
```


###### Ensure namespace is clean:

```bash
kubectl get all -n java-app
kubectl get ingress -n java-app
```

##### Reinstall Helm chart:

```bash
helm upgrade --install java-app ./springboot-helm-chart -n java-app --create-namespace \
  --set namespace.name=java-app \
  --set service.nodePort=30090 \
  --set ingress.host=java-app-new.local
```
# <img width="827" height="370" alt="Screenshot 2025-08-20 174535" src="https://github.com/user-attachments/assets/68143d35-26c7-409a-a368-bc266c81e8ea" />


##### 5. Flow Diagram

```bash

[Helm Chart] --> helm install/upgrade --> [Kubernetes: Deployment + Service + Ingress]
        |                                      |
        |                                      v
        +--> ArgoCD sync --> Automated deployment monitoring
                |
                v
        Troubleshooting: Pods, NodePort conflicts, Ingress conflicts, SA missing

```

 ######  <img width="1536" height="1024" alt="ChatGPT Image Aug 20, 2025, 06_19_27 PM" src="https://github.com/user-attachments/assets/219e1d29-adc9-4139-8c39-ba61929228fb" />


 ##  Fully Remove Helm Resources

###  1️⃣ Check all resources in the namespace
```bash
kubectl get all -n java-app
```
#### * Look for Pods, Services, Deployments, ConfigMaps, etc.

###  2️⃣ Delete all remaining resources in that namespace
```bash
kubectl delete all --all -n java-app
```
###  3️⃣  Delete the namespace completely
```bash
kubectl delete namespace java-app
```
#### * This ensures a clean slate for Helm to work next time.


### ✅ Outcome

```bash
* Helm chart installed in java-app namespace

* Deployment & NodePort service running

* Ingress configured with unique host

* ArgoCD syncs Helm app automatically

* Troubleshooting steps ensure any conflicts are resolved
```





































