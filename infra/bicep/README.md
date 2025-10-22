# Infrastructure as Code (Bicep)

This folder contains the Azure infrastructure definition for the Case Management System.

## 📁 Structure

```
infra/bicep/
├── main.bicep                      # Main orchestration file
├── main.parameters.dev.json        # Parameters for dev environment
└── modules/
    ├── acr.bicep                   # Container Registry
    ├── logs.bicep                  # Log Analytics
    ├── environment.bicep           # Container App Environment
    └── app.bicep                   # Container App
```

## 🏗️ Resources Created

1. **Azure Container Registry (ACR)** - Stores Docker images
2. **Log Analytics Workspace** - Collects logs and metrics
3. **Container App Environment** - Runtime infrastructure
4. **Container App** - Your application

## 🚀 Manual Deployment (for testing)

If you want to deploy manually before setting up CI/CD:

```bash
# Login to Azure
az login

# Create resource group
az group create --name rg-case-management-dev --location norwayeast

# Deploy infrastructure
az deployment group create \
  --resource-group rg-case-management-dev \
  --template-file main.bicep \
  --parameters main.parameters.dev.json
```

## 🤖 Automated Deployment (GitHub Actions)

The normal workflow uses GitHub Actions to automatically deploy:

1. Push code to `main` branch
2. GitHub Actions:
   - Deploys infrastructure (if changed)
   - Builds Docker image
   - Pushes to ACR
   - Updates Container App

See `.github/workflows/deploy.yml` for the automation.

## 📝 Parameters

Edit `main.parameters.dev.json` to customize:

- `baseName`: Base name for resources (default: "casemanagement")
- `environmentName`: Environment (dev/test/prod)
- `location`: Azure region (default: "norwayeast")
- `imageTag`: Docker image tag (default: "latest")

## 💰 Cost Estimate (Norway East)

| Resource | Tier | Estimated Cost |
|----------|------|----------------|
| ACR | Basic | ~$5/month |
| Container App | 0.5 CPU, 1GB RAM | ~$10-15/month |
| Log Analytics | 30 day retention | ~$2-5/month |
| **Total** | | **~$17-25/month** |

*Costs vary based on usage. Container Apps scale to zero when idle.*

## 🔧 Customization

To change resources (e.g., increase CPU/memory):

1. Edit `modules/app.bicep` parameters
2. Or override in `main.bicep` when calling the module
3. Commit changes
4. GitHub Actions will deploy updates

## 🛡️ Security

- ACR: Admin user enabled (needed for GitHub Actions)
- Container App: HTTPS only, external ingress
- Secrets: Managed by Bicep, stored securely in Azure

## 📊 Monitoring

Access logs and metrics:
1. Go to Azure Portal
2. Navigate to your Container App
3. Click "Logs" or "Metrics"
4. Query using Kusto Query Language (KQL)

Example query:
```kql
ContainerAppConsoleLogs_CL
| where TimeGenerated > ago(1h)
| project TimeGenerated, Log_s
| order by TimeGenerated desc
```
