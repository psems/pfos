#!/usr/bin/env bash
# =============================================================================
# deploy-azure.sh — Deploy wger workout manager to Azure
# =============================================================================
# Prerequisites:
#   1. Azure CLI installed and authenticated (az login)
#   2. Docker installed locally (for testing)
#   3. .env.prod configured with your values
#
# Usage:
#   chmod +x deploy-azure.sh
#   ./deploy-azure.sh [command]
#
# Commands:
#   setup      Create Azure resources (resource group, App Service plan, web app)
#   deploy     Deploy/update the Docker Compose app to Azure
#   logs       Stream live logs from the Azure web app
#   status     Show app status and URL
#   teardown   Delete all Azure resources (DESTRUCTIVE)
#   local      Run locally with Docker Compose (for testing)
#   help       Show this help message
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load environment
if [[ -f "$SCRIPT_DIR/.env.prod" ]]; then
    set -a
    source "$SCRIPT_DIR/.env.prod"
    set +a
else
    echo "ERROR: .env.prod not found. Copy .env.prod and fill in your values."
    exit 1
fi

# Defaults
RESOURCE_GROUP="${AZURE_RESOURCE_GROUP:-wger-rg}"
LOCATION="${AZURE_LOCATION:-eastus}"
APP_PLAN="${AZURE_APP_PLAN:-wger-plan}"
APP_NAME="${AZURE_APP_NAME:-wger-app}"
SKU="${AZURE_SKU:-B2}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log()   { echo -e "${GREEN}[+]${NC} $*"; }
warn()  { echo -e "${YELLOW}[!]${NC} $*"; }
error() { echo -e "${RED}[-]${NC} $*" >&2; }

check_azure_cli() {
    if ! command -v az &> /dev/null; then
        error "Azure CLI not found. Install it: https://docs.microsoft.com/en-us/cli/azure/install-azure-cli"
        exit 1
    fi
    if ! az account show &> /dev/null; then
        error "Not logged in to Azure. Run: az login"
        exit 1
    fi
    log "Azure CLI authenticated as: $(az account show --query user.name -o tsv)"
}

cmd_setup() {
    check_azure_cli

    log "Creating resource group: $RESOURCE_GROUP in $LOCATION"
    az group create \
        --name "$RESOURCE_GROUP" \
        --location "$LOCATION" \
        --output none

    log "Creating App Service plan: $APP_PLAN (SKU: $SKU, Linux)"
    az appservice plan create \
        --name "$APP_PLAN" \
        --resource-group "$RESOURCE_GROUP" \
        --sku "$SKU" \
        --is-linux \
        --output none

    log "Creating web app: $APP_NAME with Docker Compose"
    az webapp create \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --plan "$APP_PLAN" \
        --multicontainer-config-type compose \
        --multicontainer-config-file "$SCRIPT_DIR/docker-compose.azure.yml" \
        --output none

    log "Configuring app settings"
    az webapp config appsettings set \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --settings \
            SECRET_KEY="$SECRET_KEY" \
            DJANGO_DEBUG="$DJANGO_DEBUG" \
            SITE_URL="https://${APP_NAME}.azurewebsites.net" \
            CSRF_TRUSTED_ORIGINS="https://${APP_NAME}.azurewebsites.net" \
            POSTGRES_USER="$POSTGRES_USER" \
            POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
            POSTGRES_DB="$POSTGRES_DB" \
            DJANGO_DB_ENGINE="$DJANGO_DB_ENGINE" \
            DJANGO_DB_DATABASE="$DJANGO_DB_DATABASE" \
            DJANGO_DB_USER="$DJANGO_DB_USER" \
            DJANGO_DB_PASSWORD="$DJANGO_DB_PASSWORD" \
            DJANGO_DB_HOST="$DJANGO_DB_HOST" \
            DJANGO_DB_PORT="$DJANGO_DB_PORT" \
            DJANGO_CACHE_BACKEND="$DJANGO_CACHE_BACKEND" \
            DJANGO_CACHE_LOCATION="$DJANGO_CACHE_LOCATION" \
            CELERY_BROKER="$CELERY_BROKER" \
            CELERY_BACKEND="$CELERY_BACKEND" \
            DOWNLOAD_EXERCISE_IMAGES="$DOWNLOAD_EXERCISE_IMAGES" \
            WEBSITES_ENABLE_APP_SERVICE_STORAGE=true \
        --output none

    log "Enabling persistent storage"
    az webapp config appsettings set \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --settings WEBSITES_ENABLE_APP_SERVICE_STORAGE=true \
        --output none

    log "Enabling logging"
    az webapp log config \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --docker-container-logging filesystem \
        --output none

    echo ""
    log "Setup complete!"
    log "App URL: https://${APP_NAME}.azurewebsites.net"
    warn "First startup may be slow while exercise images download."
}

cmd_deploy() {
    check_azure_cli

    # Generate the Azure-specific compose file (no ports, no volumes with host paths)
    generate_azure_compose

    log "Deploying Docker Compose configuration to $APP_NAME"
    az webapp config container set \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --multicontainer-config-type compose \
        --multicontainer-config-file "$SCRIPT_DIR/docker-compose.azure.yml" \
        --output none

    log "Restarting app"
    az webapp restart \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --output none

    log "Deployment complete. App URL: https://${APP_NAME}.azurewebsites.net"
}

cmd_logs() {
    check_azure_cli
    log "Streaming logs for $APP_NAME (Ctrl+C to stop)"
    az webapp log tail \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP"
}

cmd_status() {
    check_azure_cli
    log "App status for $APP_NAME:"
    az webapp show \
        --name "$APP_NAME" \
        --resource-group "$RESOURCE_GROUP" \
        --query "{name:name, state:state, url:defaultHostName, resourceGroup:resourceGroup}" \
        --output table
}

cmd_teardown() {
    check_azure_cli
    warn "This will DELETE all resources in resource group: $RESOURCE_GROUP"
    read -rp "Type the resource group name to confirm: " confirm
    if [[ "$confirm" != "$RESOURCE_GROUP" ]]; then
        error "Confirmation failed. Aborting."
        exit 1
    fi
    log "Deleting resource group: $RESOURCE_GROUP"
    az group delete --name "$RESOURCE_GROUP" --yes --no-wait
    log "Deletion initiated (runs in background)."
}

cmd_local() {
    log "Starting wger locally with Docker Compose"
    docker compose -f "$SCRIPT_DIR/docker-compose.yml" --env-file "$SCRIPT_DIR/.env.prod" up -d
    log "wger is starting at http://localhost:${NGINX_PORT:-80}"
    log "Run 'docker compose -f $SCRIPT_DIR/docker-compose.yml logs -f' to follow logs"
}

generate_azure_compose() {
    # Azure App Service multi-container has limitations:
    # - No named volumes (use persistent storage)
    # - No depends_on with conditions
    # - No healthchecks in compose
    # Generate a simplified compose file for Azure
    cat > "$SCRIPT_DIR/docker-compose.azure.yml" << 'AZEOF'
version: "3.8"

services:
  web:
    image: wger/server:latest
    expose:
      - "8000"
    depends_on:
      - db
      - cache
    volumes:
      - ${WEBAPP_STORAGE_HOME}/wger/static:/home/wger/static
      - ${WEBAPP_STORAGE_HOME}/wger/media:/home/wger/media
    restart: always

  celery-worker:
    image: wger/server:latest
    command: /home/wger/venv/bin/celery -A wger worker --loglevel=info
    depends_on:
      - web
    volumes:
      - ${WEBAPP_STORAGE_HOME}/wger/media:/home/wger/media
    restart: always

  celery-beat:
    image: wger/server:latest
    command: /home/wger/venv/bin/celery -A wger beat --loglevel=info
    depends_on:
      - web
    restart: always

  db:
    image: postgres:15-alpine
    volumes:
      - ${WEBAPP_STORAGE_HOME}/postgres:/var/lib/postgresql/data
    expose:
      - "5432"
    restart: always

  cache:
    image: redis:7-alpine
    expose:
      - "6379"
    restart: always

  nginx:
    image: nginx:stable-alpine
    ports:
      - "80:80"
    depends_on:
      - web
    volumes:
      - ${WEBAPP_STORAGE_HOME}/wger/static:/wger/static:ro
      - ${WEBAPP_STORAGE_HOME}/wger/media:/wger/media:ro
    restart: always
AZEOF

    log "Generated docker-compose.azure.yml"
}

cmd_help() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  setup      Create Azure resources (resource group, plan, web app)"
    echo "  deploy     Deploy/update Docker Compose app to Azure"
    echo "  logs       Stream live logs from Azure"
    echo "  status     Show app status and URL"
    echo "  teardown   Delete all Azure resources (DESTRUCTIVE)"
    echo "  local      Run locally with Docker Compose"
    echo "  help       Show this help message"
    echo ""
    echo "First-time setup:"
    echo "  1. Edit .env.prod with your values"
    echo "  2. Run: $0 setup"
    echo "  3. Wait for the app to start (check with: $0 logs)"
    echo ""
    echo "Update deployment:"
    echo "  Run: $0 deploy"
}

# Main
case "${1:-help}" in
    setup)    cmd_setup ;;
    deploy)   cmd_deploy ;;
    logs)     cmd_logs ;;
    status)   cmd_status ;;
    teardown) cmd_teardown ;;
    local)    cmd_local ;;
    help)     cmd_help ;;
    *)
        error "Unknown command: $1"
        cmd_help
        exit 1
        ;;
esac
