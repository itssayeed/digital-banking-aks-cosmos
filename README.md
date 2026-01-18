# RUNBOOK — FinBanking API  
**AKS + Cosmos DB + Managed Identity (Azure)**

---

## 🎯 Purpose
This runbook provides **deterministic, repeatable steps** to:
- Provision Azure infrastructure using **Bicep**
- Build and push the FinBanking API Docker image to **ACR**
- Deploy the API to **AKS**
- Verify CRUD operations using **Cosmos DB with Managed Identity (Native RBAC)**

> Follow this document step-by-step. Do not blindly execute everything.

---

## 🧭 Scope & Assumptions
- Infrastructure is defined using **individual Bicep files**
- Cosmos DB authentication uses **Azure AD + Native RBAC**
- No secrets or keys are stored in code or Kubernetes YAML
- API listens on **port 5035** internally
- External access is via **LoadBalancer** (Project 1 scope)

---

## 0️⃣ Prerequisites (Manual)
Ensure the following are installed:
- Azure CLI
- Docker (running)
- kubectl

Login to Azure:
```powershell
az login

## PHASE 1 — Infrastructure Provisioning (ONE-TIME ONLY)

⚠️ WARNING
Run this phase only when creating the environment from scratch.
Do NOT re-run on an existing environment.

1 Create Resource Group 

az group create `
  --name dbanking-rg `
  --location southindia

2. Create Azure Container Registry (ACR)

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 01-acr.bicep `
  --parameters baseName=dbanking location=southindia


3. Create Key Vault

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 02-keyvault.bicep `
  --parameters baseName=dbanking location=southindia

4. Create Cosmos DB Account

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 03-cosmos.bicep `
  --parameters baseName=dbanking location=southindia


5. Create Storage Account

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 04-storage.bicep `
  --parameters baseName=dbanking location=southindia


6. Create AKS Cluster

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 05-aks.bicep `
  --parameters baseName=dbanking location=southindia


7. Assign Cosmos DB Native RBAC to AKS Agent Pool

az cosmosdb sql role assignment create `
  --account-name dbankingcosmoskerhjw2iy4ptg `
  --resource-group dbanking-rg `
  --role-definition-name "Cosmos DB Built-in Data Contributor" `
  --principal-id <AKS_AGENTPOOL_PRINCIPAL_ID> `
  --scope "/"

🐳 PHASE 2 — Build & Push Application Image (REPEATABLE)

8. Login to ACR

az acr login --name dbankingacr


9. Build Docker Image

docker build -t dbankingacr.azurecr.io/finbanking-api:v1 .


10. Push Image to ACR

docker push dbankingacr.azurecr.io/finbanking-api:v1


☸️ PHASE 3 — Deploy Application to AKS
11. Connect kubectl to AKS (One-time per machine)
az aks get-credentials `
  --resource-group dbanking-rg `
  --name dbanking-aks `
  --overwrite-existing


Verify:

kubectl get nodes

12. Attach ACR to AKS (Safe to Re-run)
az aks update `
  --resource-group dbanking-rg `
  --name dbanking-aks `
  --attach-acr dbankingacr

13. Deploy Application Manifests
kubectl apply -f finbanking-deployment.yaml
kubectl apply -f finbanking-service.yaml

✅ PHASE 4 — Verification
14. Check Deployment Status
kubectl get pods
kubectl get svc


Wait until:

Pod status = Running

Service has an EXTERNAL-IP

15. Test Application

Open:

http://<EXTERNAL-IP>/swagger/index.html


Verify CRUD:

POST /api/accounts

GET /api/accounts

PUT /api/accounts/{id}

DELETE /api/accounts/{id}

✅ Data stored in Cosmos DB
✅ Auth via Managed Identity
✅ No secrets used

🔎 DEBUG (Not Part of Normal Flow)

Use only if needed:

kubectl logs <pod-name>
kubectl describe svc finbanking-api-service
kubectl port-forward deployment/finbanking-api 5035:5035


Local test:

http://localhost:5035/swagger/index.html




