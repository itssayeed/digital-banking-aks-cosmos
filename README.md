TO DELETE RESOURCES to SAVE COST
-=============================

az group delete --name dbanking-rg --yes --no-wait


🧱 PHASE 1 — Infrastructure Provisioning (ONE-TIME ONLY)

⚠️ WARNING
Run this phase only when creating the environment from scratch.
Do NOT re-run on an existing environment.

1. Create Resource Group
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

  📌 Note
Cosmos DB access uses Managed Identity + Native RBAC (no keys).

5. Create Storage Account
az deployment group create `
  --resource-group dbanking-rg `
  --template-file 04-storage.bicep `
  --parameters baseName=dbanking location=southindia

  6. Create AKS Cluster

az deployment group create `
  --resource-group dbanking-rg `
  --template-file 05-aks.bicep `
  --parameters baseName=dbanking location=southindia sshPublicKey="ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC+grrcca6hh2V0o7A43HkXUsaYtw9mWBmajNvg1uRq2U2WyKDdEUEwkF4qvpcdq82ouviq9lhvRPv8rcJVUduepmaocGwsSV5jo3iqHREgIXsqBqAbuhWQ5i8ffsHuaXdeaQH7exlmtPDN1NQD73JBNmgbG8HSnRrKIZ1i01XYLqPcX0m92awWFSTQjLUHPsW1+dcWKGE6WWViPvk+LTW5dza6sur7x8I+YmdrwM2+8VibYQiynJSd9fQ8lKAwdiTyI5XcC9lCzzUcmIQVYxDtD/SIZkuJiYuduXzSm615TOdzMNGQUVURHQwxM6Kte1OnNrldQ3v+9H7aqY4lVB6Hdfql9mMmiVi/BgN9ZwCBDYnbjjgcHC8NB5Rf1JK0q3x818qOgH9wtOVNKNHmDBpjFn8j4nBvaRtKaOIzRDLqNMRLhxjTwICyObBoZbhB4Eq/VTIbq9Zog7nsQzAeJInMSAnK7OHl4M98senzhySgn6eIGYLjctX14gDWO/oSf7Ln3Qkrzxz9ku93wVdjOaKKCjNR7ZM3Jzw1OKTxWdpZ0JPe2LKwsMyUyYRAlduAODAgRWzhkKnmxUADcjj5gPD3KG21UgBapJhFkB1MQLoy/wpn0fACRKUmtmLZkyF+DUvB5Ro+oJPSmFUKOrGxk4UtgR4rrW8ZQtk+NCkFOWAnnw== itssa@Ahmed"

  
az login

az ad signed-in-user show --query id -o tsv

az cosmosdb sql role assignment create `
  --account-name dbankingcosmoskerhjw2iy4ptg `
  --resource-group dbanking-rg `
  --role-definition-name "Cosmos DB Built-in Data Contributor" `
  --principal-id f6acf69f-e510-41cd-adcc-485082ec01dc `
  --scope "/"

7. Create a principle id

az aks show `
  --resource-group dbanking-rg `
  --name dbanking-aks `
  --query identityProfile.kubeletidentity.objectId `
  -o tsv


  7. Assign Cosmos DB Native RBAC to AKS Agent Pool

Run once per environment.

az cosmosdb sql role assignment create `
  --account-name dbankingcosmoskerhjw2iy4ptg `
  --resource-group dbanking-rg `
  --role-definition-name "Cosmos DB Built-in Data Contributor" `
  --principal-id <AKS_AGENTPOOL_PRINCIPAL_ID> `
  --scope "/"

  Use the AKS agentpool managed identity principal ID.

  🐳 PHASE 2 — Build & Push Application Image (REPEATABLE)

Run this whenever application code changes.

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

Incase of any issues kindly check the principle id once and reassign contributor role properly to proper principle id

Step 1 
az aks show `
  --resource-group dbanking-rg `
  --name dbanking-aks `
  --query identityProfile.kubeletidentity.objectId `
  -o tsv

Step 2
az cosmosdb sql role assignment create `
  --account-name dbankingcosmoskerhjw2iy4ptg `
  --resource-group dbanking-rg `
  --role-definition-name "Cosmos DB Built-in Data Contributor" `
  --principal-id 8f98a77c-1f10-46d8-981c-0ee48752b30a `
  --scope "/"

step 3:
kubectl rollout restart deployment finbanking-api

Step 4 :
kubectl get pods

test again via External IP


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


INGRESS
=======

kubectl get nodes


helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update


helm install ingress-nginx ingress-nginx/ingress-nginx `
  --namespace ingress-nginx `
  --create-namespace


kubectl get pods -n ingress-nginx


kubectl get svc -n ingress-nginx


Create finbanking-ingress.yaml file 

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

kubectl get ingress

🔹 6.3.1 Edit your Service YAML

Open your existing service file:

finbanking-service.yaml


Change only this part:

❌ OLD (what you have now)
spec:
  type: LoadBalancer

✅ NEW (what it must be)
spec:
  type: ClusterIP

  finbanking

  kubectl get svc

  Now 
  🔹 6.4.1 Open Swagger via Ingress

Open in browser:

http://52.172.32.45/swagger/index.html

Now test API via INGRESS ip (52.172.32.45) 

get ingress IP from this command
kubectl get svc -n ingress-nginx


If you encounter any issues
STEP A — Verify ingress controller is actually listening on port 80

kubectl describe svc ingress-nginx-controller -n ingress-nginx


STEP B — Check ingress controller logs (most important)

kubectl logs -n ingress-nginx deploy/ingress-nginx-controller --tail=50

STEP C — Verify ingress rule backend service name & port

kubectl describe ingress finbanking-ingress

STEP D — Quick sanity test from inside cluster

kubectl run test-pod --rm -it --image=curlimages/curl -- sh

RUN THIS 
kubectl run curl-test --rm -it --image=curlimages/curl -- sh

curl -v http://finbanking-api-service/swagger/index.html


if diagnositics appear good fine teh type exit

Try this if issue still not resolved

🔧 Step 1 — Patch the ingress controller service

Run exactly this:

kubectl annotate svc ingress-nginx-controller `
  -n ingress-nginx `
  service.beta.kubernetes.io/azure-load-balancer-health-probe-request-path=/healthz












