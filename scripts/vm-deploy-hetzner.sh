#!/usr/bin/env bash
set -euo pipefail

REPO_URL=""
BRANCH="main"
BASE_DIR="/opt/eyedeea"
COMPOSE_FILE="docker-compose.yml"
UPSTREAM_PORT="8090"
ENV_FILE="/tmp/.env_eyediatech_web.txt"
DOMAIN=""
DOMAIN_ALIAS=""
WITH_SSL="false"
FORCE_HTTP="false"
DEPLOY_CERT="false"
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
    --env-file)
      ENV_FILE="$2"
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
    --force-http)
      FORCE_HTTP="true"
      shift 1
      ;;
    --deploy-cert)
      DEPLOY_CERT="true"
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

if [[ ! -f "$ENV_FILE" ]]; then
  echo "Env file missing: $ENV_FILE" >&2
  exit 1
fi

if [[ "$DEPLOY_CERT" == "true" && -z "$CERTBOT_EMAIL" ]]; then
  echo "--certbot-email is required when --deploy-cert is used" >&2
  exit 1
fi

if [[ "$FORCE_HTTP" == "true" && "$WITH_SSL" == "true" ]]; then
  echo "--force-http and --with-ssl cannot be used together" >&2
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

if [[ "$DEPLOY_CERT" == "true" ]] && ! command -v certbot >/dev/null 2>&1; then
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
  # .env is deploy-managed, not git-managed; remove stale copy so pull can proceed.
  rm -f "$REPO_DIR/.env"
  git -C "$REPO_DIR" fetch origin
  git -C "$REPO_DIR" checkout "$BRANCH"
  git -C "$REPO_DIR" pull --ff-only origin "$BRANCH"
else
  log "Cloning repository..."
  git clone --branch "$BRANCH" "$REPO_URL" "$REPO_DIR"
fi

log "Applying environment file..."
cp "$ENV_FILE" "$REPO_DIR/.env"

log "Deploying compose stack..."
cd "$REPO_DIR"
docker compose -f "$COMPOSE_FILE" up -d --build

ALIAS_PART=""
if [[ -n "$DOMAIN_ALIAS" ]]; then
  ALIAS_PART=" $DOMAIN_ALIAS"
fi

CERT_PATH="/etc/letsencrypt/live/${DOMAIN}/fullchain.pem"
KEY_PATH="/etc/letsencrypt/live/${DOMAIN}/privkey.pem"
NGINX_SITE_CONF="/etc/nginx/sites-available/root-web-primary.conf"

if [[ -f "$NGINX_SITE_CONF" ]]; then
  existing_cert_path=$(awk '$1=="ssl_certificate" {gsub(";", "", $2); print $2; exit}' "$NGINX_SITE_CONF" || true)
  existing_key_path=$(awk '$1=="ssl_certificate_key" {gsub(";", "", $2); print $2; exit}' "$NGINX_SITE_CONF" || true)

  if [[ -n "${existing_cert_path:-}" && -n "${existing_key_path:-}" && -f "$existing_cert_path" && -f "$existing_key_path" ]]; then
    CERT_PATH="$existing_cert_path"
    KEY_PATH="$existing_key_path"
  fi
fi

ssl_mode="http"
if [[ "$FORCE_HTTP" == "true" ]]; then
  ssl_mode="http"
elif [[ "$DEPLOY_CERT" == "true" ]]; then
  # Bootstrap via HTTP first so nginx can start before cert files exist.
  ssl_mode="http"
elif [[ "$WITH_SSL" == "true" ]]; then
  ssl_mode="https"
elif [[ -f "$CERT_PATH" && -f "$KEY_PATH" ]]; then
  ssl_mode="https"
  log "Detected existing certificate for ${DOMAIN}; preserving HTTPS configuration"
fi

log "Configuring host nginx reverse proxy for root-domain app..."
if [[ "$ssl_mode" == "http" ]]; then
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
else
  cat > /etc/nginx/sites-available/root-web-primary.conf <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN}${ALIAS_PART};
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name ${DOMAIN}${ALIAS_PART};

  ssl_certificate ${CERT_PATH};
  ssl_certificate_key ${KEY_PATH};

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
fi

ln -sfn /etc/nginx/sites-available/root-web-primary.conf /etc/nginx/sites-enabled/root-web-primary.conf
nginx -t
systemctl enable nginx
systemctl restart nginx

if [[ "$WITH_SSL" == "true" && "$DEPLOY_CERT" == "true" ]]; then
  log "Requesting HTTPS certificate for ${DOMAIN}${ALIAS_PART}"
  if [[ -n "$DOMAIN_ALIAS" ]]; then
    certbot --nginx --non-interactive --agree-tos --redirect --expand --keep-until-expiring --preferred-challenges http -m "$CERTBOT_EMAIL" -d "$DOMAIN" -d "$DOMAIN_ALIAS"
  else
    certbot --nginx --non-interactive --agree-tos --redirect --expand --keep-until-expiring --preferred-challenges http -m "$CERTBOT_EMAIL" -d "$DOMAIN"
  fi

  issued_cert_path=$(awk '$1=="ssl_certificate" {gsub(";", "", $2); print $2; exit}' "$NGINX_SITE_CONF" || true)
  issued_key_path=$(awk '$1=="ssl_certificate_key" {gsub(";", "", $2); print $2; exit}' "$NGINX_SITE_CONF" || true)
  if [[ -n "${issued_cert_path:-}" && -n "${issued_key_path:-}" && -f "$issued_cert_path" && -f "$issued_key_path" ]]; then
    CERT_PATH="$issued_cert_path"
    KEY_PATH="$issued_key_path"
  fi

  if [[ ! -f "$CERT_PATH" || ! -f "$KEY_PATH" ]]; then
    echo "Certificate deployment finished, but certificate files were not found for ${DOMAIN}." >&2
    exit 1
  fi

  # Normalize back to our managed config while preserving the certbot-issued cert path.
  cat > /etc/nginx/sites-available/root-web-primary.conf <<EOF
server {
  listen 80;
  listen [::]:80;
  server_name ${DOMAIN}${ALIAS_PART};
  return 301 https://\$host\$request_uri;
}

server {
  listen 443 ssl http2;
  listen [::]:443 ssl http2;
  server_name ${DOMAIN}${ALIAS_PART};

  ssl_certificate ${CERT_PATH};
  ssl_certificate_key ${KEY_PATH};

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

  nginx -t
  systemctl restart nginx
fi

if [[ "$WITH_SSL" == "true" && "$DEPLOY_CERT" != "true" && "$ssl_mode" == "https" ]]; then
  log "Reusing existing HTTPS certificate for ${DOMAIN}"
fi

if [[ "$WITH_SSL" == "true" && "$DEPLOY_CERT" != "true" && "$ssl_mode" != "https" ]]; then
  echo "SSL is enabled, but certificate files were not found for ${DOMAIN}. Run with --deploy-cert first." >&2
  exit 1
fi

log "Service status:"
docker compose -f "$COMPOSE_FILE" ps

log "Done"
