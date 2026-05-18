# ─────────────────────────────────────────────────────────────────────────────
# Flowtient — Google Firebase Hosting Deployment Script (PowerShell)
#
# WHAT THIS DOES:
#   Deploys the Flowtient static website to Google Firebase Hosting, which
#   provides a free global CDN, automatic HTTPS, and custom domain support.
#
# PREREQUISITES:
#   - Node.js installed (already confirmed: v22+)
#   - Google account (free, no credit card for Spark plan)
#   - Firebase CLI: installed by this script if missing
#
# USAGE (run from LandingPage folder):
#   .\deploy\google\deploy-firebase.ps1
# ─────────────────────────────────────────────────────────────────────────────

$ErrorActionPreference = "Stop"
$SiteRoot = "c:\GenAI_Projects\LandingPage"

Write-Host "`n[Flowtient Deploy] Starting Google Firebase Hosting deployment..." -ForegroundColor Cyan

# ── STEP 1: Install Firebase CLI if missing ───────────────────────────────────
Write-Host "`n[1/5] Checking Firebase CLI..."
$fbVersion = npm list -g firebase-tools 2>$null
if (-not ($fbVersion -match "firebase-tools")) {
    Write-Host "Installing Firebase CLI globally..."
    npm install -g firebase-tools
} else {
    Write-Host "Firebase CLI already installed."
}

# ── STEP 2: Login to Google ───────────────────────────────────────────────────
Write-Host "`n[2/5] Logging in to Google (browser will open)..."
firebase login

# ── STEP 3: Copy config files to site root ────────────────────────────────────
Write-Host "`n[3/5] Copying Firebase config to site root..."
Copy-Item "$SiteRoot\deploy\google\firebase.json" "$SiteRoot\firebase.json" -Force
Copy-Item "$SiteRoot\deploy\google\.firebaserc"   "$SiteRoot\.firebaserc"   -Force

# ── STEP 4: Create Firebase project (first time only) ────────────────────────
Write-Host "`n[4/5] Creating/selecting Firebase project..."
Write-Host "NOTE: If this is your first deploy, Firebase will ask you to create a new project."
Write-Host "      Enter 'flowtient-website' as the project ID when prompted."
Write-Host ""
Set-Location $SiteRoot

# Uncomment the line below ONLY on first deploy to create the project:
# firebase projects:create flowtient-website --display-name "Flowtient Website"

# ── STEP 5: Deploy ────────────────────────────────────────────────────────────
Write-Host "`n[5/5] Deploying to Firebase Hosting..."
firebase deploy --only hosting

# ── OUTPUT ───────────────────────────────────────────────────────────────────
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " FIREBASE DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " Your site is live at: https://flowtient-website.web.app"
Write-Host " Also available at:    https://flowtient-website.firebaseapp.com"
Write-Host ""
Write-Host " NEXT: Connect flowtient.com custom domain" -ForegroundColor Yellow

Write-Host @"

HOW TO CONNECT flowtient.com DOMAIN TO FIREBASE:
──────────────────────────────────────────────
1. Buy flowtient.com from namecheap.com, godaddy.com, or domains.google.com
   (Google Domains is now Squarespace Domains — ~$12/year)

2. In Firebase Console (console.firebase.google.com):
   → Your Project → Hosting → Add custom domain
   → Enter: flowtient.com
   → Firebase gives you 2 DNS records to add

3. In your domain registrar DNS settings, add:
   Type: A
   Name: @
   Value: [IP provided by Firebase — two A records]

   Type: A
   Name: www
   Value: [same IPs]

4. Wait 24 hours (usually much faster). Firebase auto-provisions SSL certificate.
   Visit https://flowtient.com — your site is live with HTTPS!

ESTIMATED MONTHLY COST (Spark / Free Plan):
  Firebase Hosting:     FREE (10 GB storage, 360 MB/day transfer)
  Custom domain:        FREE (SSL included)
  Domain registration:  ~$1/month
  TOTAL:               ~$1/month

Upgrade to Blaze plan only if you exceed free limits (~10K+ daily visitors).
"@
