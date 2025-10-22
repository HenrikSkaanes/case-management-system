# Getting the Azure Communication Services Sender Email

After the infrastructure deployment completes, you need to get the actual sender email address and connection string from Azure, then update the Container App configuration.

## Why This Step Is Needed

The Azure Managed Domain creates a unique subdomain (like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net`) that is only available **after** the resource is created. Bicep cannot access this value during deployment due to API limitations with `listKeys()` causing "content already consumed" errors.

## Complete Setup Script (Easiest Method)

Copy and paste this script after infrastructure deployment:

```bash
# Set your resource group name
RESOURCE_GROUP="rg-case-management-dev"
CONTAINER_APP="ca-api-casemanagement-dev"
ACS_SERVICE="acs-casemanagement-dev"
EMAIL_SERVICE="email-casemanagement-dev"

# 1. Get the ACS connection string
echo "📡 Getting ACS connection string..."
ACS_CONNECTION_STRING=$(az communication list-key \
  --name $ACS_SERVICE \
  --resource-group $RESOURCE_GROUP \
  --query "primaryConnectionString" -o tsv)

echo "✅ Connection string retrieved"

# 2. Get the sender email domain
echo "📧 Getting sender email domain..."
SENDER_DOMAIN=$(az communication email domain show \
  --email-service-name $EMAIL_SERVICE \
  --resource-group $RESOURCE_GROUP \
  --domain-name AzureManagedDomain \
  --query "fromSenderDomain" -o tsv)

SENDER_EMAIL="DoNotReply@${SENDER_DOMAIN}"
echo "✅ Sender email: $SENDER_EMAIL"

# 3. Update Container App with ACS configuration
echo "🔧 Updating Container App..."
az containerapp update \
  --name $CONTAINER_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars "ACS_SENDER_EMAIL=$SENDER_EMAIL" \
  --secrets "acs-connection-string=$ACS_CONNECTION_STRING" \
  --replace-env-vars "ACS_CONNECTION_STRING=secretref:acs-connection-string"

echo "✅ Container App updated successfully!"
echo ""
echo "Configuration complete! Email service is now ready."
echo "Sender email: $SENDER_EMAIL"
```

## Manual Steps (If You Prefer)

### Step 1: Get Connection String

**Azure Portal:**
1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to: **rg-case-management-dev** → **acs-casemanagement-dev**
3. Click **Keys** in the left menu
4. Copy the **Primary connection string**

**Azure CLI:**
```bash
az communication list-key \
  --name acs-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query "primaryConnectionString" -o tsv
```

### Step 2: Get Sender Email

**Azure Portal:**

1. Go to [Azure Portal](https://portal.azure.com)
2. Navigate to your resource group: **rg-case-management-dev**
3. Find the Email Communication Service: **email-casemanagement-dev**
4. Click on **Domains** in the left menu
5. Click on **AzureManagedDomain**
6. Copy the **MailFrom** address (e.g., `DoNotReply@xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net`)

### Option 2: Azure CLI

```bash
# Get the email service resource ID
EMAIL_SERVICE_ID=$(az communication email list -g rg-case-management-dev --query "[0].id" -o tsv)

# Get the domain details
az communication email domain show \
  --email-service-name email-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --domain-name AzureManagedDomain \
  --query "fromSenderDomain" -o tsv

# Output will be something like: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net
```

## Update Container App with Real Sender Email

Once you have the sender email, update the Container App:

```bash
# Set variables
SENDER_EMAIL="DoNotReply@xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net"  # Replace with actual value
RESOURCE_GROUP="rg-case-management-dev"
CONTAINER_APP="ca-api-casemanagement-dev"

# Update the Container App environment variable
az containerapp update \
  --name $CONTAINER_APP \
  --resource-group $RESOURCE_GROUP \
  --set-env-vars "ACS_SENDER_EMAIL=$SENDER_EMAIL"
```

## Verify Configuration

Test that the email service is working:

```bash
# Check Container App environment variables
az containerapp show \
  --name ca-api-casemanagement-dev \
  --resource-group rg-case-management-dev \
  --query "properties.template.containers[0].env[?name=='ACS_SENDER_EMAIL']" -o table

# Test the API endpoint
curl -X POST https://ca-api-casemanagement-dev.agreeablesmoke-8b3eacca.norwayeast.azurecontainerapps.io/api/tickets/1/respond \
  -H "Content-Type: application/json" \
  -d '{
    "response": "Test email",
    "customer_email": "your-test-email@example.com",
    "customer_name": "Test User",
    "ticket_title": "Test Ticket",
    "sent_by": "Admin"
  }'
```

## Automation (Future Enhancement)

To avoid manual steps, we could:
1. Use an Azure Function or Logic App triggered after ACS deployment
2. Use Bicep deployment scripts to fetch and update the value
3. Use a secondary workflow step to update the Container App

For now, the manual approach above works fine and only needs to be done once per environment.
