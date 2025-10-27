# Infrastructure as Code (Bicep)

This folder contains the Azure infrastructure definition for the Case Management System.

## 📁 Structure

```
infra/bicep/
├── main.bicep                              # Main orchestration file
├── main.parameters.dev-optimized.json      # Parameters for dev environment
└── modules/
    ├── acr.bicep                           # Container Registry
    ├── logs.bicep                          # Log Analytics
    ├── networking.bicep                    # VNet, Subnets, NAT Gateway
    ├── keyvault.bicep                      # Key Vault for secrets
    ├── postgres-private.bicep              # PostgreSQL with private endpoint
    ├── containerapps-env-vnet.bicep        # Container App Environment + App
    ├── staticwebapp.bicep                  # Static Web App (frontend)
    ├── communication-services.bicep        # Azure Communication Services (email)
    ├── logic-app.bicep                     # Logic Apps (workflow automation)
    ├── apim.bicep                          # API Management (Consumption)
    ├── frontdoor-waf.bicep                 # Azure Front Door + WAF
    └── postgres-aad-admin.bicep            # PostgreSQL AAD authentication
```

## 🏗️ Resources Created

### Core Infrastructure
1. **Azure Container Registry (ACR)** - Stores Docker images with managed identity
2. **Log Analytics Workspace** - Centralized logging and monitoring
3. **VNet + NAT Gateway** - Private networking with fixed egress IP
4. **Key Vault** - Secure secrets management with RBAC

### Application Layer
5. **Container App Environment** - VNet-injected runtime with autoscaling
6. **Container App (Backend)** - FastAPI application with managed identity
7. **Static Web App (Frontend)** - React frontend on global CDN
8. **PostgreSQL Flexible Server** - Private database with Azure AD auth

### Communication & Automation
9. **Azure Communication Services (ACS)** - Email notifications (~$0.25 per 1,000 emails)
10. **Logic Apps** - Workflow automation for Teams notifications, approvals, etc.

### Security & Gateway
11. **API Management (Consumption)** - Rate limiting, CORS, API gateway
12. **Azure Front Door + WAF** - Global CDN with OWASP protection and bot management

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

## 💰 Cost Estimate (Norway East - Production-Ready)

| Resource | Tier | Estimated Cost |
|----------|------|----------------|
| ACR | Basic | ~$5/month |
| Container App | 0.5 CPU, 1GB RAM | ~$23/month |
| PostgreSQL | B1ms (Burstable) | ~$25/month |
| Static Web App | Free | $0 |
| Log Analytics | Basic ingestion | ~$3/month |
| VNet + NAT Gateway | Standard | ~$10/month |
| API Management | Consumption | ~$5/month |
| Azure Front Door | Standard | ~$35/month |
| Key Vault | Standard | ~$1/month |
| **Communication Services** | **Pay-per-email** | **~$0.25 per 1,000 emails** |
| **Logic Apps** | **Consumption** | **Free (first 4,000 actions)** |
| **Total (base)** | | **~$107/month** |
| **Total (with 10k emails)** | | **~$110/month** |

*Costs vary based on usage. Container Apps scale to zero when idle. Email and Logic Apps are pay-per-use.*

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
