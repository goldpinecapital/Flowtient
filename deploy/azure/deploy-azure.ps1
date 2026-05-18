# ─────────────────────────────────────────────────────────────────────────────
# Flowtient — Azure Static Web Apps Deployment Script (PowerShell)
#
# WHAT THIS DOES:
#   Deploys the Flowtient website to Azure Static Web Apps using the Azure CLI.
#   Azure Static Web Apps provides: global CDN, free SSL, custom domain,
#   CI/CD integration, and a generous free tier.
#
# PREREQUISITES:
#   - Azure CLI installed: https://aka.ms/installazurecliwindows
#   - Azure account (free tier available): https://azure.microsoft.com/free/
#   - Azure subscription ID (found in Azure Portal)
#
# USAGE:
#   .\deploy\azure\deploy-azure.ps1 -SubscriptionId "YOUR-SUB-ID"
# ─────────────────────────────────────────────────────────────────────────────

param(
    [string]$SubscriptionId = "",
    [string]$ResourceGroup  = "flowtient-rg",
    [string]$AppName        = "flowtient-website",
    [string]$Location       = "eastus2",
    [string]$SiteRoot       = "c:\GenAI_Projects\LandingPage"
)

$ErrorActionPreference = "Stop"

Write-Host "`n[Flowtient Deploy] Starting Azure Static Web Apps deployment..." -ForegroundColor Cyan

# ── STEP 1: Install Azure CLI if missing ──────────────────────────────────────
Write-Host "`n[1/6] Checking Azure CLI..."
try {
    $azVersion = az version 2>$null | ConvertFrom-Json
    Write-Host "Azure CLI found: v$($azVersion.'azure-cli')"
} catch {
    Write-Host "Azure CLI not found. Download from: https://aka.ms/installazurecliwindows" -ForegroundColor Red
    Start-Process "https://aka.ms/installazurecliwindows"
    exit 1
}

# ── STEP 2: Login ─────────────────────────────────────────────────────────────
Write-Host "`n[2/6] Logging in to Azure (browser will open)..."
az login
if ($SubscriptionId) {
    az account set --subscription $SubscriptionId
}

# ── STEP 3: Create Resource Group ─────────────────────────────────────────────
Write-Host "`n[3/6] Creating resource group: $ResourceGroup in $Location..."
az group create --name $ResourceGroup --location $Location

# ── STEP 4: Copy Azure config to site root ────────────────────────────────────
Write-Host "`n[4/6] Copying Azure config..."
Copy-Item "$SiteRoot\deploy\azure\staticwebapp.config.json" "$SiteRoot\staticwebapp.config.json" -Force

# ── STEP 5: Create Static Web App ─────────────────────────────────────────────
Write-Host "`n[5/6] Creating Azure Static Web App: $AppName..."
$result = az staticwebapp create `
    --name $AppName `
    --resource-group $ResourceGroup `
    --location $Location `
    --sku Free `
    --output json | ConvertFrom-Json

$appUrl    = $result.defaultHostname
$appId     = $result.id
$deployKey = az staticwebapp secrets list --name $AppName --resource-group $ResourceGroup --query "properties.apiKey" -o tsv

# ── STEP 6: Upload files using SWA CLI ────────────────────────────────────────
Write-Host "`n[6/6] Deploying website files..."

# Install SWA CLI if needed
$swaCheck = npm list -g @azure/static-web-apps-cli 2>$null
if (-not ($swaCheck -match "static-web-apps-cli")) {
    Write-Host "Installing Azure SWA CLI..."
    npm install -g @azure/static-web-apps-cli
}

Set-Location $SiteRoot
swa deploy . --deployment-token $deployKey --env production

# ── OUTPUT ───────────────────────────────────────────────────────────────────
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " AZURE DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " Live URL:        https://$appUrl"
Write-Host " Resource Group:  $ResourceGroup"
Write-Host " App ID:          $appId"
Write-Host ""
Write-Host " NEXT: Connect flowtient.com custom domain" -ForegroundColor Yellow

Write-Host @"

HOW TO CONNECT flowtient.com DOMAIN TO AZURE:
───────────────────────────────────────────
1. Buy flowtient.com from namecheap.com, godaddy.com, or azure domain registration
   Cost: ~$12/year

2. In Azure Portal:
   → Static Web Apps → $AppName → Custom domains → Add

3. Choose "Custom domain on other DNS":
   → Enter: flowtient.com
   → Azure provides a TXT record for validation

4. In your domain registrar DNS, add:
   Type: TXT
   Name: @
   Value: [validation string from Azure]

   Type: CNAME
   Name: www
   Value: $appUrl

   Type: ALIAS or A (for apex domain, use your registrar's ALIAS feature)
   Name: @
   Value: $appUrl

5. Back in Azure, click "Validate and add" — Azure auto-provisions SSL.

ESTIMATED MONTHLY COST (Free Plan):
  Azure Static Web Apps:  FREE (100 GB/month bandwidth)
  Global CDN:             FREE (included)
  SSL certificate:        FREE (auto-managed)
  Custom domain:          FREE
  Domain registration:    ~$1/month
  TOTAL:                 ~$1/month
"@
