# Managed Identities Architecture

## 🎯 Overview

This architecture uses **managed identities** for all authentication, eliminating the need for passwords and connection strings in your code.

## 🔐 Where Managed Identities Are Used

### 1. **Container App → PostgreSQL**
**What:** Container App authenticates to PostgreSQL using Azure AD
**How:** System-assigned managed identity
**Benefit:** No database password in connection string!

```python
# Instead of this (password in code):
DATABASE_URL = "postgresql://user:PASSWORD@server/db"

# You use this (managed identity):
DATABASE_URL = "postgresql://user@server/db?sslmode=require"
# Azure handles authentication automatically!
```

---

### 2. **Container App → Key Vault**
**What:** Container App reads secrets from Key Vault
**How:** System-assigned managed identity with RBAC
**Benefit:** No Key Vault access keys needed!

```python
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

# Automatically uses managed identity
credential = DefaultAzureCredential()
client = SecretClient(vault_url="https://kvname.vault.azure.net/", credential=credential)
secret = client.get_secret("my-secret")
```

---

### 3. **Container App → ACR** (Container Registry)
**What:** Container App pulls images from ACR
**How:** System-assigned managed identity
**Benefit:** No registry passwords!

Configured automatically in Bicep:
```bicep
resource containerApp 'Microsoft.App/containerApps@2024-03-01' = {
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    configuration: {
      registries: [
        {
          server: acrLoginServer
          identity: 'system'  // Uses managed identity!
        }
      ]
    }
  }
}
```

---

### 4. **API Management → Container App** (Optional Future)
**What:** APIM authenticates requests to backend
**How:** Managed identity
**Benefit:** No API keys between APIM and Container App

---

### 5. **GitHub Actions → Azure** (Your Service Principal)
**What:** GitHub deploys to Azure
**How:** Service Principal stored in GitHub Secrets
**Benefit:** No personal credentials in CI/CD

---

## 📋 How It Works - Step by Step

### Initial Deployment

1. **Deploy Infrastructure** (Bicep)
   ```bash
   az deployment group create \
     --parameters postgresqlAdminPassword='TempPassword123!'
   ```
   - Creates Container App with system-assigned managed identity
   - Creates PostgreSQL with Azure AD auth enabled
   - Creates Key Vault with RBAC

2. **Grant Permissions** (Automatic via Bicep)
   ```bicep
   // Container App → PostgreSQL
   resource postgresqlAadAdmin 'Microsoft.DBforPostgreSQL/flexibleServers/administrators@2023-03-01-preview' = {
     properties: {
       principalId: containerApp.identity.principalId  // Managed identity
       principalType: 'ServicePrincipal'
     }
   }
   
   // Container App → Key Vault
   resource keyVaultRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
     properties: {
       principalId: containerApp.identity.principalId
       roleDefinitionId: 'Key Vault Secrets User'
     }
   }
   ```

3. **Application Code** (No secrets!)
   ```python
   # backend/app/database.py
   import os
   from azure.identity import DefaultAzureCredential
   import psycopg2
   
   # Get connection string from environment (no password!)
   DATABASE_HOST = os.getenv("DATABASE_HOST")
   DATABASE_NAME = os.getenv("DATABASE_NAME")
   
   # Use managed identity for authentication
   credential = DefaultAzureCredential()
   token = credential.get_token("https://ossrdbms-aad.database.windows.net/.default")
   
   conn = psycopg2.connect(
       host=DATABASE_HOST,
       database=DATABASE_NAME,
       user="ca-api-casemanagement-dev@psql-casemanagement-dev",  # Managed identity name
       password=token.token,  # Token, not password!
       sslmode="require"
   )
   ```

---

## 🔧 Configuration Needed

### In Your Backend Code

Install Azure Identity SDK:
```bash
pip install azure-identity azure-keyvault-secrets psycopg2-binary
```

Update `backend/requirements.txt`:
```txt
azure-identity==1.15.0
azure-keyvault-secrets==4.7.0
psycopg2-binary==2.9.9
```

### Database Connection with Managed Identity

```python
# backend/app/config.py
import os
from azure.identity import DefaultAzureCredential
from azure.keyvault.secrets import SecretClient

class Settings:
    def __init__(self):
        # Use Key Vault for configuration
        key_vault_url = os.getenv("KEY_VAULT_URL")
        credential = DefaultAzureCredential()
        client = SecretClient(vault_url=key_vault_url, credential=credential)
        
        # Get database connection details from Key Vault
        self.database_host = client.get_secret("database-host").value
        self.database_name = client.get_secret("database-name").value
        
        # Get Azure AD token for PostgreSQL
        token = credential.get_token("https://ossrdbms-aad.database.windows.net/.default")
        
        # Build connection string (no password!)
        self.database_url = f"postgresql://{os.getenv('MANAGED_IDENTITY_NAME')}@{self.database_host}/{self.database_name}?sslmode=require"
        self.database_token = token.token
```

---

## 📝 GitHub Secrets Required

Your repository needs these secrets:

### 1. **AZURE_CREDENTIALS** (Service Principal)
```json
{
  "clientId": "xxx",
  "clientSecret": "xxx",
  "subscriptionId": "xxx",
  "tenantId": "xxx"
}
```

**How to create:**
```bash
az ad sp create-for-rbac \
  --name "github-actions-case-management" \
  --role contributor \
  --scopes /subscriptions/{subscription-id}/resourceGroups/rg-case-management-dev \
  --sdk-auth
```

### 2. **POSTGRESQL_ADMIN_PASSWORD**
Temporary password for initial setup. After Azure AD auth is configured, this is only used for emergency access.

```bash
# Generate secure password
openssl rand -base64 32
```

**Add to GitHub:**
1. Go to: Repository → Settings → Secrets and variables → Actions
2. Click "New repository secret"
3. Name: `POSTGRESQL_ADMIN_PASSWORD`
4. Value: Your secure password

---

## 🚀 Deployment Flow

### First Deployment
```bash
# Uses GitHub Actions with service principal
git push origin main

# Or manually with your credentials
az login
az deployment group create \
  --parameters postgresqlAdminPassword='SecurePass123!'
```

### Application Deployment
```bash
# Build backend (managed identity authenticates to ACR)
az acr build --registry acrcasemanagementdev --image api:latest backend/

# Container App automatically:
# 1. Pulls image using managed identity (no password)
# 2. Connects to PostgreSQL using managed identity (no password)
# 3. Reads secrets from Key Vault using managed identity (no password)
```

---

## ✅ Benefits of This Approach

| Aspect | Without Managed Identity | With Managed Identity |
|--------|-------------------------|----------------------|
| **Database Password** | Stored in environment variables | No password needed! |
| **Key Vault Access** | Access keys in code | Automatic via RBAC |
| **ACR Access** | Admin credentials | Automatic authentication |
| **Secret Rotation** | Manual, breaks apps | Automatic, no downtime |
| **Security** | Secrets can leak | No secrets to leak! |
| **Compliance** | Secrets in multiple places | Centralized access control |

---

## 🔍 Verify It's Working

### Check Managed Identity
```bash
# Get Container App's managed identity
az containerapp show \
  --name ca-api-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query identity.principalId -o tsv
```

### Check PostgreSQL AAD Admin
```bash
# Verify managed identity is PostgreSQL admin
az postgres flexible-server ad-admin list \
  --resource-group rg-case-management-dev \
  --server-name psql-casemanagement-dev
```

### Check Key Vault Access
```bash
# List who has access to Key Vault
az role assignment list \
  --scope /subscriptions/{sub-id}/resourceGroups/rg-case-management-dev/providers/Microsoft.KeyVault/vaults/kvcasemanagementdev
```

---

## 🛠️ Troubleshooting

### "Authentication failed for user"
**Issue:** Container App can't connect to PostgreSQL
**Solution:**
1. Verify Azure AD is enabled:
   ```bash
   az postgres flexible-server show --name psql-casemanagement-dev --resource-group rg-case-management-dev --query authConfig
   ```
2. Check managed identity has admin role
3. Ensure app requests correct token scope

### "Key Vault permission denied"
**Issue:** Can't read secrets from Key Vault
**Solution:**
1. Check role assignment:
   ```bash
   az role assignment list --assignee <managed-identity-principal-id>
   ```
2. Grant access:
   ```bash
   az role assignment create \
     --role "Key Vault Secrets User" \
     --assignee <managed-identity-principal-id> \
     --scope /subscriptions/{sub}/resourceGroups/{rg}/providers/Microsoft.KeyVault/vaults/{vault}
   ```

---

## 🎓 What You'll Learn

By using managed identities, you'll understand:
- ✅ **Zero-trust security** - No secrets in code
- ✅ **RBAC (Role-Based Access Control)** - Who can access what
- ✅ **Azure AD integration** - Modern authentication
- ✅ **Service principals** - App-to-app authentication
- ✅ **Token-based auth** - OAuth 2.0 flows
- ✅ **Production-ready patterns** - Enterprise standards

This is **exactly how production Azure apps are secured!** 🚀
