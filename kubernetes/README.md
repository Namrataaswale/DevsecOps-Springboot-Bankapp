# End-to-End Setup for Deploying Applications with ArgoCD and EKS

This README provides a complete step-by-step guide with all the commands required to set up ArgoCD on an AWS EKS cluster, deploy your applications, and configure GitOps.

---

## **1. Create an EKS Cluster**

### **Create the Cluster Without a Node Group**
```bash
eksctl create cluster --name=bankapp \
                    --region=ap-south-1 \
                    --version=1.31 \
                    --without-nodegroup
```

### **Associate IAM OIDC Provider**
```bash
eksctl utils associate-iam-oidc-provider \
  --region ap-south-1 \
  --cluster bankapp \
  --approve
```

### **Create a Node Group**
```bash
eksctl create nodegroup --cluster=bankapp \
                     --region=ap-south-1 \
                     --name=bankapp \
                     --node-type=t2.medium \
                     --nodes=2 \
                     --nodes-min=2 \
                     --nodes-max=2 \
                     --node-volume-size=29 \
                     --ssh-access \
                     --ssh-public-key=k8s-in-one-shot
```

---

## **2. Deploy ArgoCD**

### **Create the ArgoCD Namespace**
```bash
kubectl create namespace argocd
```

### **Install ArgoCD Using Official Manifests**
```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### **Verify ArgoCD Pods**
```bash
watch kubectl get pods -n argocd
```

### **Install ArgoCD CLI**
```bash
curl --silent --location -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/download/v2.4.7/argocd-linux-amd64
chmod +x /usr/local/bin/argocd
argocd version
```

### **Change ArgoCD Server Service Type to NodePort**
```bash
kubectl patch svc argocd-server -n argocd -p '{"spec": {"type": "NodePort"}}'
```

### **Verify the NodePort Service**
```bash
kubectl get svc -n argocd
```

### **Expose the Port on Security Groups**
- In the AWS Console, update the security group for your EKS worker nodes to allow inbound traffic on the NodePort assigned to the `argocd-server` service.

### **Access the ArgoCD Web UI**
- Open your browser and navigate to:
  ```
  http://<public-ip-of-worker-node>:<NodePort>
  ```

---

## **3. Configure ArgoCD for EKS**

### **Login to ArgoCD Using CLI**
```bash
argocd login <public-ip-of-worker-node>:<NodePort> --username admin
```

### **Retrieve the Default Admin Password**
```bash
kubectl get secret argocd-initial-admin-secret -n argocd -o jsonpath="{.data.password}" | base64 -d
```

### **Check Available Clusters in ArgoCD**
```bash
argocd cluster list
```

### **Get the EKS Cluster Context**
```bash
kubectl config get-contexts
```

### **Add EKS Cluster to ArgoCD**
```bash
argocd cluster add <cluster-context-name> --name bankapp-eks-cluster
```
- Replace `<cluster-context-name>` with your EKS cluster context name (e.g., `Madhup@bankapp.us-west-1.eksctl.io`).

---

## **4. Deploy Applications Using ArgoCD**

### **Prepare Kubernetes Manifests in a Git Repository**
- Organize your manifests (e.g., `namespace.yaml`, `deployment.yaml`, `service.yaml`) in a Git repository.

### **Create an Application in ArgoCD**
```bash
argocd app create bankapp \
  --repo <your-git-repo-url> \
  --path <path-to-manifests> \
  --dest-server https://kubernetes.default.svc \
  --dest-namespace bankapp-namespace
```

### **Sync the Application**
```bash
argocd app sync bankapp
```

### **Monitor Application Status**
```bash
argocd app list
```

---

## **5. Deploy NGINX Ingress Controller**

### **Install NGINX Ingress Controller Using Helm**
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace
```

### **Verify Installation**
Check if the NGINX Ingress Controller pods are running:
```bash
kubectl get pods -n ingress-nginx
```

### **Retrieve the Load Balancer IP**
Get the external IP assigned to the NGINX Ingress Controller:
```bash
kubectl get svc -n ingress-nginx
```

### **Update DNS**
Point your domain (`junoon.trainwithshubham.com`) to the external IP of the NGINX Load Balancer.

---

## **6. Enable HTTPS for the Application**

### **Install Cert-Manager**
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.1/cert-manager.yaml
```

### **Create Let's Encrypt ClusterIssuer**
Save the following as `letsencrypt-clusterissuer.yaml`:
```yaml
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod-key
    solvers:
    - http01:
        ingress:
          class: nginx
```
Apply the ClusterIssuer:
```bash
kubectl apply -f letsencrypt-clusterissuer.yaml
```

### **Update Ingress with TLS Configuration**
- Modify your Ingress to include TLS and reference the `letsencrypt-prod` ClusterIssuer.
- Apply the updated Ingress:
```bash
kubectl apply -f <your-ingress-file>
```

### **Verify Certificate Issuance**
```bash
kubectl get certificate -n bankapp-namespace
```

---

## **7. Verify Deployment**

### **Check Deployed Resources**
```bash
kubectl get all -n bankapp-namespace
```

### **Access the Application**
- Open your browser and navigate to:
  ```
  https://junoon.trainwithshubham.com
  ```

---

## **8. Add Autoscaling**

### **Install the Metrics Server**
```bash
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

### **Get the Top Nodes and Pods**
```bash
  kubectl top nodes
  kubectl top pods -n bankapp-namespace
```
### **Apply HPA**
```bash
  kubectl apply -f bankapp-hpa.yml
```
---

