#!/usr/bin/env bash
set -euo pipefail

REPO_URL=""
BRANCH="main"
BASE_DIR="/opt/eyedeea"
COMPOSE_FILE="docker-compose.yml"
UPSTREAM_PORT="8090"
DOMAIN=""
DOMAIN_ALIAS=""
WITH_SSL="false"
CERTBOT_EMAIL=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo-url)
      REPO_URL="$2"
      shift 2
      ;;
    --branch)
      BRANCH="$2"
      shift 2
      ;;
    --base-dir)
      BASE_DIR="$2"
      shift 2
      ;;
    --compose-file)
      COMPOSE_FILE="$2"
      shift 2
      ;;
    --upstream-port)
      UPSTREAM_PORT="$2"
      shift 2
      ;;
    --domain)
      DOMAIN="$2"
      shift 2
      ;;
    --domain-alias)
      DOMAIN_ALIAS="$2"
      shift 2
      ;;
    --with-ssl)
      WITH_SSL="true"
      shift 1
      ;;
    --certbot-email)
      CERTBOT_EMAIL="$2"
      shift 2
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

log() {
  printf "[deploy-root-web] %s\n" "$1"
}

if [[ -z "$REPO_URL" ]]; then
  echo "--repo-url is required" >&2
  exit 1
fi

if [[ -z "$DOMAIN" ]]; then
  echo "--domain is required" >&2
  exit 1
fi

if [[ "$WITH_SSL" == "true" && -z "$CERTBOT_EMAIL" ]]; then
  echo "--certbot-email is required when --with-ssl is used" >&2
  exit 1
fi

if ! command -v git >/dev/null 2>&1; then
  log "Installing git..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y git
fi

if ! command -v docker >/dev/null 2>&1; then
  log "Installing Docker..."
  curl -fsSL https://get.docker.com | sh
  systemctl enable docker
  systemctl start docker
fi

if ! command -v nginx >/dev/null 2>&1; then
  log "Installing nginx..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y nginx
fi

if [[ "$WITH_SSL" == "true" ]] && ! command -v certbot >/dev/null 2>&1; then
  log "Installing certbot..."
  apt-get update
  DEBIAN_FRONTEND=noninteractive apt-get install -y certbot python3-certbot-nginx
fi

if ! docker compose version >/dev/null 2>&1; then
  echo "docker compose plugin is required but not available" >&2
  exit 1
fi

REPO_NAME=$(basename "$REPO_URL")
APP_DIR_NAME="${REPO_NAME%.git}"
REPO_DIR="$BASE_DIR/$APP_DIR_NAME"
mkdir -p "$BASE_DIR"

if [[ -d "$REPO_DIR/.git" ]]; then
  log "Updating repository..."
  git -C "$REPO_DIR" fetch origin
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
else
  log "Cloning repository..."
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

log "Deploying compose stack..."
cd "$REPO_DIR"
docker compose -f "$COMPOSE_FILE" up -d --build

ALIAS_PART=""
if [[ -n "$DOMAIN_ALIAS" ]]; then
  ALIAS_PART=" $DOMAIN_ALIAS"
fi

log "Configuring host nginx reverse proxy for root-domain app..."
cat > /etc/nginx/sites-available/root-web-primary.conf <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN}${ALIAS_PART};

  location / {
    proxy_pass http://127.0.0.1:${UPSTREAM_PORT};
    proxy_http_version 1.1;
    proxy_set_header Host \$host;
    proxy_set_header X-Real-IP \$remote_addr;
    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    proxy_set_header X-Forwarded-Proto \$scheme;
    proxy_set_header Upgrade \$http_upgrade;
    proxy_set_header Connection "upgrade";
  }
}
EOF

ln -sfn /etc/nginx/sites-available/root-web-primary.conf /etc/nginx/sites-enabled/root-web-primary.conf
nginx -t
systemctl enable nginx
systemctl restart nginx

if [[ "$WITH_SSL" == "true" ]]; then
  log "Requesting HTTPS certificate for ${DOMAIN}${ALIAS_PART}"
  if [[ -n "$DOMAIN_ALIAS" ]]; then
    certbot --nginx --non-interactive --agree-tos --redirect --keep-until-expiring --preferred-challenges http -m "$CERTBOT_EMAIL" -d "$DOMAIN" -d "$DOMAIN_ALIAS"
  else
    certbot --nginx --non-interactive --agree-tos --redirect --keep-until-expiring --preferred-challenges http -m "$CERTBOT_EMAIL" -d "$DOMAIN"
  fi
  systemctl restart nginx
fi

log "Service status:"
docker compose -f "$COMPOSE_FILE" ps

log "Done"
