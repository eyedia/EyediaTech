# GCP Static Deployment (Cloud Storage + Cloud CDN)

This setup is optimized for low-frequency releases.

## 1) Create bucket

Use a globally unique bucket name, for example `www.eyediatech.com`.

```bash
gsutil mb -l us-central1 gs://www.eyediatech.com
```

## 2) Enable website hosting on bucket

```bash
gsutil web set -m index.html -e index.html gs://www.eyediatech.com
```

## 3) Build site

```bash
npm install
npm run build
```

## 4) Upload static files

```bash
gsutil -m rsync -r -d dist gs://www.eyediatech.com
```

## 5) Make objects public (or use IAM/Cloud CDN origin policies)

```bash
gsutil iam ch allUsers:objectViewer gs://www.eyediatech.com
```

## 6) Configure HTTPS + Cloud CDN + custom domain

Recommended production architecture:
1. External HTTPS Load Balancer
2. Backend bucket pointing to `www.eyediatech.com`
3. Cloud CDN enabled on backend bucket
4. Managed SSL certificate for `www.eyediatech.com`
5. DNS `A` record to LB IP

## 7) Release updates

```bash
npm run build
gsutil -m rsync -r -d dist gs://www.eyediatech.com
gcloud compute url-maps invalidate-cdn-cache <URL_MAP_NAME> --path "/*"
```

## Optional: redirect apex domain

If you use both `eyediatech.com` and `www.eyediatech.com`, configure HTTP(S) redirect at load balancer level.
