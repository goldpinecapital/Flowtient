# ─────────────────────────────────────────────────────────────────────────────
# Flowtient — AWS S3 + CloudFront Deployment Script (PowerShell)
#
# WHAT THIS DOES:
#   1. Creates an S3 bucket configured for static website hosting
#   2. Uploads all website files with correct MIME types and caching headers
#   3. Creates a CloudFront distribution pointing at the S3 bucket
#   4. Outputs the CloudFront URL + instructions to connect Flowtient.com domain
#
# PREREQUISITES:
#   - AWS CLI installed:  https://aws.amazon.com/cli/
#   - AWS account configured: run `aws configure` first
#   - IAM user with: S3FullAccess + CloudFrontFullAccess permissions
#
# USAGE:
#   .\deploy-s3.ps1 -BucketName "flowtient-website" -Region "us-east-1"
# ─────────────────────────────────────────────────────────────────────────────

param(
    [string]$BucketName = "flowtient-website",
    [string]$Region     = "us-east-1",
    [string]$SiteRoot   = "c:\GenAI_Projects\LandingPage"
)

$ErrorActionPreference = "Stop"

Write-Host "`n[Flowtient Deploy] Starting AWS S3 + CloudFront deployment..." -ForegroundColor Cyan

# ── STEP 1: Create S3 bucket ──────────────────────────────────────────────────
Write-Host "`n[1/6] Creating S3 bucket: $BucketName in $Region"

if ($Region -eq "us-east-1") {
    aws s3api create-bucket `
        --bucket $BucketName `
        --region $Region
} else {
    aws s3api create-bucket `
        --bucket $BucketName `
        --region $Region `
        --create-bucket-configuration LocationConstraint=$Region
}

# ── STEP 2: Disable Block Public Access ───────────────────────────────────────
Write-Host "[2/6] Configuring public access settings..."

aws s3api put-public-access-block `
    --bucket $BucketName `
    --public-access-block-configuration `
        "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"

# ── STEP 3: Set bucket policy for public read ─────────────────────────────────
Write-Host "[3/6] Applying public read bucket policy..."

$policy = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::$BucketName/*"
    }
  ]
}
"@

$policy | aws s3api put-bucket-policy --bucket $BucketName --policy file:///dev/stdin

# ── STEP 4: Enable static website hosting ────────────────────────────────────
Write-Host "[4/6] Enabling static website hosting..."

aws s3 website s3://$BucketName/ `
    --index-document index.html `
    --error-document index.html

# ── STEP 5: Upload website files ─────────────────────────────────────────────
Write-Host "[5/6] Uploading website files..."

# HTML — no cache (always fresh)
aws s3 cp "$SiteRoot\index.html" "s3://$BucketName/index.html" `
    --content-type "text/html; charset=utf-8" `
    --cache-control "no-cache, no-store, must-revalidate"

# CSS — cache 1 year (add ?v=X query param to bust if needed)
aws s3 cp "$SiteRoot\styles.css" "s3://$BucketName/styles.css" `
    --content-type "text/css; charset=utf-8" `
    --cache-control "public, max-age=31536000, immutable"

# JS — cache 1 year
aws s3 cp "$SiteRoot\script.js" "s3://$BucketName/script.js" `
    --content-type "application/javascript; charset=utf-8" `
    --cache-control "public, max-age=31536000, immutable"

# If you add images later, uncomment:
# aws s3 sync "$SiteRoot\images" "s3://$BucketName/images" --cache-control "public, max-age=31536000"

Write-Host "[5/6] Upload complete!"

# ── STEP 6: Create CloudFront distribution ───────────────────────────────────
Write-Host "[6/6] Creating CloudFront distribution (takes ~5 minutes to deploy globally)..."

$cfConfig = @"
{
  "CallerReference": "flowtient-$(Get-Date -Format 'yyyyMMddHHmmss')",
  "Comment": "Flowtient.com production distribution",
  "DefaultCacheBehavior": {
    "ViewerProtocolPolicy": "redirect-to-https",
    "TargetOriginId": "S3-$BucketName",
    "ForwardedValues": {
      "QueryString": false,
      "Cookies": { "Forward": "none" }
    },
    "MinTTL": 0,
    "DefaultTTL": 86400,
    "MaxTTL": 31536000,
    "Compress": true
  },
  "Origins": {
    "Quantity": 1,
    "Items": [
      {
        "Id": "S3-$BucketName",
        "DomainName": "$BucketName.s3-website-$Region.amazonaws.com",
        "CustomOriginConfig": {
          "HTTPPort": 80,
          "HTTPSPort": 443,
          "OriginProtocolPolicy": "http-only"
        }
      }
    ]
  },
  "Enabled": true,
  "HttpVersion": "http2",
  "PriceClass": "PriceClass_100",
  "DefaultRootObject": "index.html",
  "Aliases": {
    "Quantity": 2,
    "Items": ["flowtient.com", "www.flowtient.com"]
  },
  "ViewerCertificate": {
    "CloudFrontDefaultCertificate": true
  }
}
"@

$cfResult = $cfConfig | aws cloudfront create-distribution --distribution-config file:///dev/stdin | ConvertFrom-Json
$cfDomain  = $cfResult.Distribution.DomainName
$cfId      = $cfResult.Distribution.Id

# ── OUTPUT ───────────────────────────────────────────────────────────────────
Write-Host "`n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " DEPLOYMENT COMPLETE" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
Write-Host " S3 Bucket URL   : http://$BucketName.s3-website-$Region.amazonaws.com"
Write-Host " CloudFront URL  : https://$cfDomain"
Write-Host " CloudFront ID   : $cfId"
Write-Host ""
Write-Host " NEXT: Connect flowtient.com domain (see instructions below)" -ForegroundColor Yellow
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

Write-Host @"

HOW TO CONNECT flowtient.com DOMAIN TO CLOUDFRONT:
─────────────────────────────────────────────────
1. Buy flowtient.com from: namecheap.com, godaddy.com, or domains.google.com
   Estimated cost: ~$12/year

2. In AWS Console → Certificate Manager (ACM):
   - Request a PUBLIC certificate for: flowtient.com and www.flowtient.com
   - Use DNS validation (add the CNAME record to your domain)

3. Update the CloudFront distribution ($cfId):
   - Add the ACM certificate ARN
   - Set Alternate Domain Names: flowtient.com, www.flowtient.com

4. In your domain registrar DNS settings, add:
   Type: CNAME
   Name: www
   Value: $cfDomain

   Type: A (Alias record, if using Route 53)
   Name: @
   Value: $cfDomain

5. Wait 10-15 minutes for DNS propagation.
   Visit https://flowtient.com — your site is live!

ESTIMATED MONTHLY COST:
  S3 storage (< 1 MB):       ~\$0.00
  CloudFront (10K visitors):  ~\$0.50–\$1.00
  Domain renewal:             ~\$1/month
  TOTAL:                     < \$2/month
"@
