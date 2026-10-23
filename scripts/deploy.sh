#!/bin/bash

# Personal Notes Deployment Script
# Deploys backend and web to production server

set -e  # Exit on error

# Configuration
SERVER="root@39.106.88.210"
DEPLOY_DIR="/root/app"
BACKEND_PORT=8080
WEB_PORT=3000
BACKEND_URL="http://${SERVER}:${BACKEND_PORT}"
WEB_URL="http://${SERVER}:${WEB_PORT}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print colored messages
info() { echo -e "${GREEN}ℹ${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
error() { echo -e "${RED}✗${NC} $1"; exit 1; }
success() { echo -e "${GREEN}✓${NC} $1"; }

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "=========================================="
echo "Personal Notes Deployment"
echo "=========================================="
echo ""

# Step 1: Git Commit and Push
info "Step 1: Git commit and push..."
cd "$PROJECT_DIR"

if [[ -n $(git status -s) ]]; then
    git add -A
    git commit -m "Deploy: Update application code $(date +%Y-%m-%d-%H-%M)"
    git push origin main
    success "Code committed and pushed"
else
    info "No changes to commit"
fi

# Step 2: Transfer files to server
info "Step 2: Transferring files to server..."

# Transfer backend (including compiled binary)
rsync -avz --progress \
  --exclude='personal-notes' \
  --exclude='personal-notes-local' \
  --exclude='notes.db' \
  --exclude='.git' \
  -e "ssh -o StrictHostKeyChecking=no" \
  "$PROJECT_DIR/backend/" \
  "${SERVER}:${DEPLOY_DIR}/backend/"

# Transfer compiled Linux binary
rsync -avz --progress \
  -e "ssh -o StrictHostKeyChecking=no" \
  "$PROJECT_DIR/backend/personal-notes-linux" \
  "${SERVER}:${DEPLOY_DIR}/backend/personal-notes"

# Transfer web
rsync -avz --progress \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='coverage' \
  -e "ssh -o StrictHostKeyChecking=no" \
  "$PROJECT_DIR/web/" \
  "${SERVER}:${DEPLOY_DIR}/web/"

success "Files transferred successfully"

# Step 3: Compile backend locally for Linux
info "Step 3: Compiling backend locally for Linux..."
cd "$PROJECT_DIR/backend"

# Cross-compile for Linux with pure-Go SQLite (no CGO required)
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go build -o personal-notes-linux main.go

success "Backend compiled successfully (pure-Go SQLite, no CGO)"

# Step 4: Install web dependencies
info "Step 4: Installing web dependencies..."
ssh -o StrictHostKeyChecking=no "$SERVER" "cd ${DEPLOY_DIR}/web && npm install --production --silent"
success "Web dependencies installed"

# Step 5: Restart services
info "Step 5: Restarting services..."
ssh -o StrictHostKeyChecking=no "$SERVER" << 'EOF'
# Create logs directory
mkdir -p /root/app/logs

# Stop and delete old processes
pm2 stop personal-notes-backend personal-notes-web 2>/dev/null || true
pm2 delete personal-notes-backend personal-notes-web 2>/dev/null || true

# Start services
cd /root/app
pm2 start ecosystem.config.js

# Wait for services to start
sleep 3

# Save PM2 configuration
pm2 save --force

# Show status
pm2 status
EOF

success "Services restarted"

# Step 6: Health checks
info "Step 6: Running health checks..."
sleep 5

# Test backend health
info "Testing backend health endpoint..."
if curl -sf "${BACKEND_URL}/health" > /dev/null; then
    success "Backend health check passed"
else
    error "Backend health check failed"
fi

# Test backend API
info "Testing backend API..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "${BACKEND_URL}/api/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456","verification_code":"1234"}' || echo "000")

if [[ "$HTTP_STATUS" == "200" || "$HTTP_STATUS" == "400" || "$HTTP_STATUS" == "401" ]]; then
    success "Backend API is responding (HTTP $HTTP_STATUS)"
else
    warn "Backend API test returned HTTP $HTTP_STATUS"
fi

# Test web frontend
info "Testing web frontend..."
if curl -sf "${WEB_URL}/" > /dev/null; then
    success "Web frontend is accessible"
else
    error "Web frontend is not accessible"
fi

# Check PM2 logs for errors
info "Checking PM2 logs for errors..."
ssh -o StrictHostKeyChecking=no "$SERVER" "pm2 logs --lines 5 --nostream --err" || true

echo ""
echo "=========================================="
success "Deployment completed successfully!"
echo "=========================================="
echo ""
echo "📍 Access URLs:"
echo "   Backend API: ${BACKEND_URL}"
echo "   Frontend:    ${WEB_URL}"
echo "   Health:      ${BACKEND_URL}/health"
echo ""
echo "📋 Useful commands:"
echo "   pm2 status                    - Check service status"
echo "   pm2 logs                      - View logs"
echo "   pm2 restart all               - Restart all services"
echo "   ssh ${SERVER} - Connect to server"
echo ""
