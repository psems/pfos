# Deploy wger on Azure

Deploy [wger](https://github.com/wger-project/wger) (workout manager) to Azure App Service using Docker Compose.

## Architecture

```
Azure App Service (Linux, Docker Compose)
├── nginx          → Reverse proxy, static files (port 80)
├── web            → wger Django app (port 8000)
├── celery-worker  → Background task processing
├── celery-beat    → Periodic task scheduler
├── db             → PostgreSQL 15
└── cache          → Redis 7
```

## Prerequisites

- [Azure CLI](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli) installed
- Azure subscription (logged in via `az login`)
- [Docker](https://docs.docker.com/get-docker/) (for local testing only)

## Quick Start

### 1. Configure environment

Edit `.env.prod` and set at minimum:

```sh
SECRET_KEY=<random-64-char-string>
POSTGRES_PASSWORD=<strong-password>
DJANGO_DB_PASSWORD=<same-as-above>
AZURE_APP_NAME=<globally-unique-name>
```

Generate a secret key:
```sh
python3 -c "import secrets; print(secrets.token_urlsafe(64))"
```

### 2. Deploy to Azure

```sh
# Create all Azure resources and deploy
./deploy-azure.sh setup
```

This creates:
- A resource group
- A Linux App Service plan (B2 tier by default)
- A multi-container web app running the Docker Compose stack

### 3. Verify

```sh
# Check status
./deploy-azure.sh status

# Stream logs
./deploy-azure.sh logs
```

The app will be available at `https://<AZURE_APP_NAME>.azurewebsites.net`.

First startup is slow while the database initializes and exercise images download.

## Commands

| Command | Description |
|---------|-------------|
| `./deploy-azure.sh setup` | Create Azure resources and deploy |
| `./deploy-azure.sh deploy` | Update an existing deployment |
| `./deploy-azure.sh logs` | Stream live logs |
| `./deploy-azure.sh status` | Show app URL and state |
| `./deploy-azure.sh teardown` | Delete all Azure resources |
| `./deploy-azure.sh local` | Run locally with Docker Compose |

## Local Testing

```sh
./deploy-azure.sh local
# App runs at http://localhost:80
```

Or directly:
```sh
docker compose --env-file .env.prod up -d
```

## Default Credentials

wger creates a default admin user on first run:
- **Username:** `admin`
- **Password:** `adminadmin`

Change this immediately after first login.

## Cost

The default B2 App Service plan (~$54/month) is the minimum recommended for running all containers. You can adjust `AZURE_SKU` in `.env.prod`:

| SKU | vCPUs | RAM | Approx. Cost |
|-----|-------|-----|-------------|
| B1  | 1     | 1.75 GB | ~$13/mo |
| B2  | 2     | 3.5 GB  | ~$54/mo |
| B3  | 4     | 7 GB    | ~$108/mo |
| P1V2 | 1    | 3.5 GB  | ~$81/mo |

B1 may be too constrained for all 6 containers. B2 is recommended.

## Cleanup

```sh
./deploy-azure.sh teardown
```

This deletes the entire resource group and all resources within it.

## Files

```
deploy-wger/
├── docker-compose.yml       # Full stack for local development
├── docker-compose.azure.yml # Generated at deploy time for Azure
├── deploy-azure.sh          # Deployment automation script
├── .env.prod                # Environment configuration (edit this)
├── nginx/
│   └── nginx.conf           # Nginx reverse proxy config
└── README.md                # This file
```
