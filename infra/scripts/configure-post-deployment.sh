#!/bin/bash
# Post-deployment configuration script
# Configures secrets and settings that cannot be set during Bicep deployment
# due to Azure API "content already consumed" limitations

set -e

# Check required environment variables
if [ -z "$RESOURCE_GROUP" ] || [ -z "$ENVIRONMENT_NAME" ] || [ -z "$LOG_ANALYTICS_NAME" ]; then
  echo "❌ Missing required environment variables:"
  echo "   RESOURCE_GROUP, ENVIRONMENT_NAME, LOG_ANALYTICS_NAME"
  exit 1
fi

echo "🔧 Configuring post-deployment settings..."
echo ""

# 1. Configure Log Analytics for Container App Environment
echo "📊 Configuring Log Analytics integration..."
LOG_ANALYTICS_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_ANALYTICS_NAME" \
  --query id -o tsv)

LOG_ANALYTICS_CUSTOMER_ID=$(az monitor log-analytics workspace show \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_ANALYTICS_NAME" \
  --query customerId -o tsv)

LOG_ANALYTICS_SHARED_KEY=$(az monitor log-analytics workspace get-shared-keys \
  --resource-group "$RESOURCE_GROUP" \
  --workspace-name "$LOG_ANALYTICS_NAME" \
  --query primarySharedKey -o tsv)

# Update Container App Environment with Log Analytics
az containerapp env update \
  --name "$ENVIRONMENT_NAME" \
  --resource-group "$RESOURCE_GROUP" \
  --logs-destination log-analytics \
  --logs-workspace-id "$LOG_ANALYTICS_CUSTOMER_ID" \
  --logs-workspace-key "$LOG_ANALYTICS_SHARED_KEY"

echo "✅ Log Analytics configured for Container App Environment"
echo ""

# 2. Get ACS Connection String (if ACS is deployed)
if [ -n "$ACS_SERVICE_NAME" ]; then
  echo "📧 Retrieving Azure Communication Services connection string..."
  ACS_CONNECTION_STRING=$(az communication list-key \
    --name "$ACS_SERVICE_NAME" \
    --resource-group "$RESOURCE_GROUP" \
    --query primaryConnectionString -o tsv)
  
  echo "✅ ACS Connection String: ${ACS_CONNECTION_STRING:0:50}..."
  echo ""
  
  # Note: You need to manually update the Container App with this connection string
  echo "⚠️  To update Container App with ACS connection string:"
  echo "   az containerapp update \\"
  echo "     --name <CONTAINER_APP_NAME> \\"
  echo "     --resource-group $RESOURCE_GROUP \\"
  echo "     --set-env-vars ACS_CONNECTION_STRING=\"$ACS_CONNECTION_STRING\""
  echo ""
fi

echo "🎉 Post-deployment configuration complete!"
