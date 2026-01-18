@echo off
SETLOCAL ENABLEEXTENSIONS

echo =====================================================
echo FinBanking API - AKS + Cosmos DB Runbook
echo =====================================================
echo.
echo This is a GUIDED runbook.
echo - Infrastructure steps are MANUAL by design
echo - Application steps are SAFE to auto-run
echo.
echo Press CTRL+C at any time to stop.
pause

REM =====================================================
REM PHASE 0 - Prerequisites
REM =====================================================
echo.
echo [PHASE 0] Prerequisites (manual check)
echo -----------------------------------------------------
echo - Azure CLI installed
echo - Docker installed and running
echo - kubectl installed
echo - Logged into Azure
echo.
echo If not logged in, run:
echo   az login
pause

REM =====================================================
REM PHASE 1 - Infrastructure Provisioning (BICEP)
REM =====================================================
echo.
echo =====================================================
echo PHASE 1 - Infrastructure Provisioning (ONE TIME ONLY)
echo =====================================================
echo.
echo WARNING:
echo - Run this phase ONLY when creating infra from scratch
echo - DO NOT run on an existing environment
echo.
echo Execute the following commands MANUALLY:
echo.

echo az group create --name dbanking-rg --location southindia
echo.
echo az deployment group create --resource-group dbanking-rg --template-file 01-acr.bicep --parameters baseName=dbanking location=southindia
echo az deployment group create --resource-group dbanking-rg --template-file 02-keyvault.bicep --parameters baseName=dbanking location=southindia
echo az deployment group create --resource-group dbanking-rg --template-file 03-cosmos.bicep --parameters baseName=dbanking location=southindia
echo az deployment group create --resource-group dbanking-rg --template-file 04-storage.bicep --parameters baseName=dbanking location=southindia
echo az deployment group create --resource-group dbanking-rg --template-file 05-aks.bicep --parameters baseName=dbanking location=southindia
echo.
echo After infrastructure creation:
echo - Ensure AKS is running
echo - Ensure Cosmos DB exists
echo - Ensure ACR exists
echo.
echo DO NOT continue until infra is confirmed.
pause

REM =====================================================
REM PHASE 1.1 - Cosmos Native RBAC (REFERENCE)
REM =====================================================
echo.
echo =====================================================
echo PHASE 1.1 - Cosmos DB Native RBAC (REFERENCE)
echo =====================================================
echo.
echo This must be done ONCE per environment.
echo Assign Cosmos Native RBAC to AKS AGENTPOOL identity.
echo.
echo Command (example):
echo az cosmosdb sql role assignment create ^
echo   --account-name dbankingcosmoskerhjw2iy4ptg ^
echo   --resource-group dbanking-rg ^
echo   --role-definition-name "Cosmos DB Built-in Data Contributor" ^
echo   --principal-id <AKS_AGENTPOOL_PRINCIPAL_ID> ^
echo   --scope "/"
echo.
echo Ensure this is completed before app deployment.
pause

REM =====================================================
REM PHASE 2 - Build and Push Docker Image
REM =====================================================
echo.
echo =====================================================
echo PHASE 2 - Build and Push Docker Image
echo =====================================================
echo.

echo Logging into Azure Container Registry...
powershell -Command "az acr login --name dbankingacr"
IF ERRORLEVEL 1 GOTO :ERROR

echo.
echo Building Docker image...
powershell -Command "docker build -t dbankingacr.azurecr.io/finbanking-api:v1 ."
IF ERRORLEVEL 1 GOTO :ERROR

echo.
echo Pushing Docker image to ACR...
powershell -Command "docker push dbankingacr.azurecr.io/finbanking-api:v1"
IF ERRORLEVEL 1 GOTO :ERROR

pause

REM =====================================================
REM PHASE 3 - Connect kubectl to AKS
REM =====================================================
echo.
echo =====================================================
echo PHASE 3 - Connect kubectl to AKS
echo =====================================================
echo.

powershell -Command ^
 "az aks get-credentials --resource-group dbanking-rg --name dbanking-aks --overwrite-existing"
IF ERRORLEVEL 1 GOTO :ERROR

echo.
echo Verifying AKS connectivity...
powershell -Command "kubectl get nodes"
pause

REM =====================================================
REM PHASE 4 - Ensure AKS Can Pull From ACR
REM =====================================================
echo.
echo =====================================================
echo PHASE 4 - Attach ACR to AKS (Safe to re-run)
echo =====================================================
echo.

powershell -Command ^
 "az aks update --resource-group dbanking-rg --name dbanking-aks --attach-acr dbankingacr"
pause

REM =====================================================
REM PHASE 5 - Deploy Application to AKS
REM =====================================================
echo.
echo =====================================================
echo PHASE 5 - Deploy Application to AKS
echo =====================================================
echo.

powershell -Command "kubectl apply -f finbanking-deployment.yaml"
IF ERRORLEVEL 1 GOTO :ERROR

powershell -Command "kubectl apply -f finbanking-service.yaml"
IF ERRORLEVEL 1 GOTO :ERROR

pause

REM =====================================================
REM PHASE 6 - Verification
REM =====================================================
echo.
echo =====================================================
echo PHASE 6 - Verification
echo =====================================================
echo.

echo Checking pods...
powershell -Command "kubectl get pods"

echo.
echo Checking services...
powershell -Command "kubectl get svc"
echo.
echo Wait until:
echo - Pod status is RUNNING
echo - EXTERNAL-IP is assigned
pause

REM =====================================================
REM PHASE 7 - Test Application
REM =====================================================
echo.
echo =====================================================
echo PHASE 7 - Test Application
echo =====================================================
echo.
echo Open in browser:
echo   http://<EXTERNAL-IP>/swagger/index.html
echo.
echo Verify CRUD:
echo   POST   /api/accounts
echo   GET    /api/accounts
echo   PUT    /api/accounts/{id}
echo   DELETE /api/accounts/{id}
echo.
pause

echo =====================================================
echo RUNBOOK COMPLETED SUCCESSFULLY
echo =====================================================
echo.
echo DEBUG (use only if needed):
echo   kubectl logs <pod-name>
echo   kubectl describe svc finbanking-api-service
echo   kubectl port-forward deployment/finbanking-api 5035:5035
echo.
pause
exit /B 0

:ERROR
echo.
echo !!! ERROR OCCURRED !!!
echo Check the output above and fix the issue.
echo Runbook stopped to prevent partial deployment.
pause
exit /B 1
