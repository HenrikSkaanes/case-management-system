# Quick fix script to remove NSGs from Container Apps subnets
# Run this if the backend becomes inaccessible again
# 
# Usage: .\scripts\fix-nsg.ps1

$ErrorActionPreference = "Stop"

$resourceGroup = "rg-case-management-dev"
$vnetName = "vnet-casemanagement-dev"
$containerAppName = "ca-api-casemanagement-dev"

Write-Host "🔍 Checking for NSG issues..." -ForegroundColor Cyan

# Check and remove NSG from aca-control subnet
Write-Host "`nChecking aca-control subnet..." -ForegroundColor Yellow
$controlNsg = az network vnet subnet show `
    --resource-group $resourceGroup `
    --vnet-name $vnetName `
    --name aca-control `
    --query "networkSecurityGroup.id" -o tsv

if ($controlNsg) {
    Write-Host "⚠️  NSG found on aca-control subnet - removing..." -ForegroundColor Red
    az network vnet subnet update `
        --resource-group $resourceGroup `
        --vnet-name $vnetName `
        --name aca-control `
        --network-security-group null | Out-Null
    Write-Host "✅ NSG removed from aca-control" -ForegroundColor Green
} else {
    Write-Host "✅ No NSG on aca-control subnet" -ForegroundColor Green
}

# Check and remove NSG from aca-runtime subnet
Write-Host "`nChecking aca-runtime subnet..." -ForegroundColor Yellow
$runtimeNsg = az network vnet subnet show `
    --resource-group $resourceGroup `
    --vnet-name $vnetName `
    --name aca-runtime `
    --query "networkSecurityGroup.id" -o tsv

if ($runtimeNsg) {
    Write-Host "⚠️  NSG found on aca-runtime subnet - removing..." -ForegroundColor Red
    az network vnet subnet update `
        --resource-group $resourceGroup `
        --vnet-name $vnetName `
        --name aca-runtime `
        --network-security-group null | Out-Null
    Write-Host "✅ NSG removed from aca-runtime" -ForegroundColor Green
} else {
    Write-Host "✅ No NSG on aca-runtime subnet" -ForegroundColor Green
}

# Restart Container App if NSGs were removed
if ($controlNsg -or $runtimeNsg) {
    Write-Host "`n🔄 Restarting Container App..." -ForegroundColor Yellow
    
    # Get latest revision
    $latestRevision = az containerapp revision list `
        --name $containerAppName `
        --resource-group $resourceGroup `
        --query "[0].name" -o tsv
    
    az containerapp revision restart `
        --name $containerAppName `
        --resource-group $resourceGroup `
        --revision $latestRevision | Out-Null
    
    Write-Host "✅ Container App restarted" -ForegroundColor Green
    
    Write-Host "`n⏳ Waiting 30 seconds for startup..." -ForegroundColor Yellow
    Start-Sleep -Seconds 30
    
    # Test connectivity
    Write-Host "`n🧪 Testing backend connectivity..." -ForegroundColor Cyan
    try {
        $backendUrl = az containerapp show `
            --name $containerAppName `
            --resource-group $resourceGroup `
            --query "properties.configuration.ingress.fqdn" -o tsv
        
        $response = Invoke-WebRequest -Uri "https://$backendUrl/health" -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ Backend is UP! Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "   URL: https://$backendUrl" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Backend still not responding: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "   Try waiting a bit longer and test manually" -ForegroundColor Yellow
    }
} else {
    Write-Host "`n✅ No NSG issues found! Backend should be working." -ForegroundColor Green
    
    # Still test connectivity
    Write-Host "`n🧪 Testing backend connectivity..." -ForegroundColor Cyan
    try {
        $backendUrl = az containerapp show `
            --name $containerAppName `
            --resource-group $resourceGroup `
            --query "properties.configuration.ingress.fqdn" -o tsv
        
        $response = Invoke-WebRequest -Uri "https://$backendUrl/health" -UseBasicParsing -TimeoutSec 10
        Write-Host "✅ Backend is UP! Status: $($response.StatusCode)" -ForegroundColor Green
        Write-Host "   URL: https://$backendUrl" -ForegroundColor White
    }
    catch {
        Write-Host "❌ Backend not responding despite no NSG issues!" -ForegroundColor Red
        Write-Host "   Check: 1) PostgreSQL is running  2) Container App logs  3) Other network issues" -ForegroundColor Yellow
    }
}

Write-Host "`n✨ Done!" -ForegroundColor Cyan
