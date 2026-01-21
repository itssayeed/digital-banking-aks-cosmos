📘 RUNBOOK.md
FinBanking API — AKS + Cosmos DB + Ingress (Azure)
🎯 Purpose

This runbook documents the end-to-end lifecycle of deploying a .NET API to Azure Kubernetes Service (AKS) using:

Infrastructure as Code (Bicep)

Docker & Azure Container Registry

Managed Identity with Cosmos DB Native RBAC

NGINX Ingress Controller

Azure Standard Load Balancer

It also clearly defines when and how to test at each stage.

🧭 High-Level Architecture (Final State)
Client
  ↓
Azure Load Balancer
  ↓
NGINX Ingress Controller
  ↓
ClusterIP Service
  ↓
Pod (.NET API)
  ↓
Cosmos DB (Managed Identity + Native RBAC)


TO DELETE ALL ABOVE RESOURCES
az group delete --name dbanking-rg --yes --no-wait

🟦 PHASE 1 — Infrastructure Creation (Bicep)
Step 1: Provision Azure resources

Resource Deployment using .Bicep files

Using Bicep, create:

Resource Group

Azure Container Registry (ACR)

Azure Kubernetes Service (AKS)

Cosmos DB (Azure AD / Native RBAC enabled)
az group create `
 --name dbanking-rg `
 --location southindia

  
az deployment group create `
  --resource-group dbanking-rg `
  --template-file 01-acr.bicep `
  --parameters baseName=dbanking location=southindia
  
  
az deployment group create `
  --resource-group dbanking-rg `
  --template-file 02-KeyVault.bicep `
  --parameters baseName=dbanking location=southindia

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 03-cosmos.bicep `
  --parameters baseName=dbanking location=southindia

    
az deployment group create `
  --resource-group dbanking-rg `
  --template-file 04-storage.bicep `
  --parameters baseName=dbanking location=southindia


az deployment group create `
  --resource-group dbanking-rg `
  --template-file 05-aks.bicep `
  --parameters baseName=dbanking location=southindia sshPublicKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+grrcca6hh2V0o7A43HkXUsaYtw9mWBmajNvg1uRq2U2WyKDdEUEwkF4qvpcdq82ouviq9lhvRPv8rcJVUduepmaocGwsSV5jo3iqHREgIXsqBqAbuhWQ5i8ffsHuaXdeaQH7exlmtPDN1NQD73JBNmgbG8HSnRrKIZ1i01XYLqPcX0m92awWFSTQjLUHPsW1+dcWKGE6WWViPvk+LTW5dza6sur7x8I+YmdrwM2+8VibYQiynJSd9fQ8lKAwdiTyI5XcC9lCzzUcmIQVYxDtD/SIZkuJiYuduXzSm615TOdzMNGQUVURHQwxM6Kte1OnNrldQ3v+9H7aqY4lVB6Hdfql9mMmiVi/BgN9ZwCBDYnbjjgcHC8NB5Rf1JK0q3x818qOgH9wtOVNKNHmDBpjFn8j4nBvaRtKaOIzRDLqNMRLhxjTwICyObBoZbhB4Eq/VTIbq9Zog7nsQzAeJInMSAnK7OHl4M98senzhySgn6eIGYLjctX14gDWO/oSf7Ln3Qkrzxz9ku93wVdjOaKKCjNR7ZM3Jzw1OKTxWdpZ0JPe2LKwsMyUyYRAlduAODAgRWzhkKnmxUADcjj5gPD3KG21UgBapJhFkB1MQLoy/wpn0fACRKUmtmLZkyF+DUvB5Ro+oJPSmFUKOrGxk4UtgR4rrW8ZQtk+NCkFOWAnnw== itssa@Ahmed"




✅ No application testing in this phase

🟦 PHASE 2 — Local Development & Identity Validation
Step 2: Run API locally
dotnet build
dotnet run


Test:

http://localhost:5035/swagger/index.html


❌ Cosmos calls will fail until RBAC is assigned.

Step 3: Assign Cosmos RBAC to local user
az ad signed-in-user show --query id -o tsv

az cosmosdb sql role assignment create \
  --account-name <cosmos-name> \
  --resource-group <rg-name> \
  --role-definition-name "Cosmos DB Built-in Data Contributor" \
  --principal-id <USER_OBJECT_ID> \
  --scope "/"


Restart API and test CRUD locally.

✅ TEST POINT #1 — LOCAL

App logic

Cosmos connectivity

Managed Identity (local)

🟦 PHASE 3 — Containerization & Registry
Step 4: Build Docker image
docker build -t finbanking-api:local .

Step 5: Push image to ACR
az acr login --name <acr-name>

docker tag finbanking-api:local <acr-name>.azurecr.io/finbanking-api:v1
docker push <acr-name>.azurecr.io/finbanking-api:v1


❌ No testing here (image only)

🟦 PHASE 4 — AKS Deployment (LoadBalancer Test)
Step 6: Attach ACR to AKS
az aks update \
  --resource-group <rg-name> \
  --name <aks-name> \
  --attach-acr <acr-name>

Step 7: Deploy application to AKS
kubectl apply -f finbanking-deployment.yaml
kubectl apply -f finbanking-service.yaml


Initial service type:

spec:
  type: LoadBalancer

Step 8: Assign Cosmos RBAC to AKS kubelet identity
az aks show \
  --resource-group <rg-name> \
  --name <aks-name> \
  --query identityProfile.kubeletidentity.objectId \
  -o tsv

az cosmosdb sql role assignment create \
  --account-name <cosmos-name> \
  --resource-group <rg-name> \
  --role-definition-name "Cosmos DB Built-in Data Contributor" \
  --principal-id <KUBELET_OBJECT_ID> \
  --scope "/"


Restart pods:

kubectl rollout restart deployment finbanking-api

Step 9: Test via Service LoadBalancer
kubectl get svc


Test:

http://<SERVICE-EXTERNAL-IP>/swagger/index.html


✅ TEST POINT #2 — AKS + LoadBalancer

AKS deployment

ACR image pull

Managed Identity in AKS

Cosmos RBAC for pods

🟦 PHASE 5 — Ingress Introduction (Production Pattern)

Only start this phase after LoadBalancer testing succeeds.

Step 10: Install NGINX Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update

helm install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --create-namespace


Get ingress IP:

kubectl get svc -n ingress-nginx

Step 11: Create Ingress resource
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: finbanking-ingress
spec:
  ingressClassName: nginx
  rules:
    - http:
        paths:
          - path: /
            pathType: Prefix
            backend:
              service:
                name: finbanking-api-service
                port:
                  number: 80

kubectl apply -f finbanking-ingress.yaml

Step 12: Fix Azure Load Balancer health probe (CRITICAL)
kubectl annotate svc ingress-nginx-controller \
  -n ingress-nginx \
  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path=/healthz


⏳ Wait 1–2 minutes.

Step 13: Test via Ingress IP
http://<INGRESS-IP>/swagger/index.html


✅ TEST POINT #3 — AKS + Ingress

🟦 PHASE 6 — Final Hardening (ClusterIP Only)
Step 14: Switch app Service to ClusterIP
spec:
  type: ClusterIP

kubectl apply -f finbanking-service.yaml


Verify:

kubectl get svc


App service must have NO external IP.

Step 15: Final test (production model)
http://<INGRESS-IP>/swagger/index.html


✅ FINAL TEST

Only ingress exposed

App is private

Production-grade setup

🧠 Key Lessons Learned

Always validate via LoadBalancer before ingress

Ingress does not replace testing, it refines exposure

Azure Standard Load Balancer requires /healthz probe for NGINX ingress

Internal success ≠ external success

Annotations bridge Kubernetes and Azure behavior

🏁 Status

Project 1: COMPLETE
Do not modify further. Use as reference architecture.