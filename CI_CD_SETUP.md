# AgroNexus CI/CD Setup Guide

## Overview
Your GitHub Actions CI/CD pipeline automatically:
1. **Tests** Flutter frontend and Java backend on every push
2. **Builds** backend Docker image and pushes to Docker Hub
3. **Deploys** to your Contabo VPS via SSH

## Prerequisites

### 1. Docker Hub Setup
Create a Docker Hub account and personal access token:
- Go to [Docker Hub](https://hub.docker.com/settings/security)
- Create a new Personal Access Token (PAT)

### 2. VPS Setup (Contabo)
SSH into your VPS and prepare it:

```bash
# Install Docker and Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo apt-get install -y docker-compose

# Create deployment directory
mkdir -p /home/$USER/agronexus
cd /home/$USER/agronexus

# Create .env file from template
cp deployment/.env.example .env

# Edit .env with your secrets
nano .env
```

### 3. GitHub Secrets
Go to your GitHub repo → Settings → Secrets and Variables → Actions, and add:

| Secret | Value |
|--------|-------|
| `DOCKER_HUB_USERNAME` | Your Docker Hub username |
| `DOCKER_HUB_TOKEN` | Your Docker Hub personal access token |
| `VPS_HOST` | Your VPS IP address (e.g., 123.45.67.89) |
| `VPS_USER` | SSH user on your VPS (e.g., root or deploy) |
| `VPS_SSH_KEY` | Private SSH key (generate with `ssh-keygen -t ed25519`) |

#### Generate SSH Key for GitHub
```bash
# On your VPS
ssh-keygen -t ed25519 -N "" -f ~/.ssh/github_deploy
cat ~/.ssh/github_deploy.pub >> ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

# Copy the private key to GitHub Secrets
cat ~/.ssh/github_deploy
```

## Pipeline Stages

### Stage 1: Test (Runs on every push)
- **Flutter**: Formatting, analysis, unit tests
- **Backend**: Maven compile, unit tests, integration tests

### Stage 2: Build & Push (Only on main branch)
- Builds multi-stage Docker image with Maven + JRE
- Pushes to Docker Hub with `latest` and commit SHA tags
- Verifies deployment artifacts (Dockerfile, docs, SQL scripts)

### Stage 3: Deploy (Only on main branch after docker build)
- Copies `docker-compose.yml` and `.env` to VPS
- Pulls latest image from Docker Hub
- Stops old containers and starts new ones

## Manual Deployment (if needed)

```bash
# SSH into your VPS
ssh -i ~/.ssh/github_deploy $VPS_USER@$VPS_HOST

# Navigate to project
cd /home/$VPS_USER/agronexus

# Pull latest image
docker pull $DOCKER_HUB_USERNAME/agronexus-backend:latest

# Restart services
docker compose down
docker compose up -d

# Check logs
docker compose logs -f backend
```

## Troubleshooting

### Pipeline fails at "Build backend image"
- Check Maven pom.xml syntax
- Verify Java version is 21 or compatible
- Run locally: `mvn clean package -DskipTests`

### Docker push fails
- Verify Docker Hub credentials in GitHub Secrets
- Check docker-compose.yml image tag matches `DOCKER_HUB_USERNAME`
- Ensure your Docker Hub account has push permissions

### VPS deployment fails
- Verify SSH key is added to `~/.ssh/authorized_keys` on VPS
- Check VPS has Docker and docker-compose installed
- Verify `.env` file exists on VPS with correct secrets
- Check network connectivity: `ssh -i key.pem user@host`

### Containers won't start on VPS
```bash
docker compose logs db
docker compose logs backend
docker compose logs mqtt
```

## Environment Variables

### Backend (from `.env`)
- `POSTGRES_DB` - Database name
- `POSTGRES_USER` - DB user
- `POSTGRES_PASSWORD` - DB password (MUST be strong in production)
- `JWT_SECRET` - JWT signing key (min 256 bits)
- `SPRING_AI_OPENAI_API_KEY` - OpenAI API key for RAG

### Frontend (in pubspec.yaml)
- `API_BASE_URL` - Backend API endpoint

## Next Steps

1. **Add health checks** to docker-compose.yml for better monitoring
2. **Set up monitoring** (e.g., Prometheus + Grafana) on VPS
3. **Configure HTTPS** with Let's Encrypt on VPS
4. **Add database backups** to cron jobs on VPS
5. **Implement blue-green deployments** for zero-downtime updates
