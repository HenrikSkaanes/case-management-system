# Getting the Azure Communication Services Sender Email

After the infrastructure deployment completes, you need to get the actual sender email address from Azure Portal and update the Container App configuration.

## Why This Step Is Needed

The Azure Managed Domain creates a unique subdomain (like `xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.azurecomm.net`) that is only available **after** the resource is created. Bicep cannot access this value during deployment due to API limitations.

## Steps to Get the Sender Email

### Option 1: Azure Portal (Easiest)

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
