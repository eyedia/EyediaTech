param(
  [Parameter(Mandatory = $true)]
  [string]$BucketName,

  [Parameter(Mandatory = $true)]
  [string]$UrlMapName
)

$ErrorActionPreference = 'Stop'

Write-Host 'Installing dependencies (if needed)...'
npm install

Write-Host 'Building project...'
npm run build

Write-Host "Syncing dist/ to gs://$BucketName ..."
gsutil -m rsync -r -d dist "gs://$BucketName"

Write-Host 'Invalidating CDN cache...'
gcloud compute url-maps invalidate-cdn-cache $UrlMapName --path "/*"

Write-Host 'Deployment completed.'
