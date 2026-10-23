# Deployment Scripts

This directory contains deployment automation scripts for the Personal Notes application.

## Scripts

### deploy.sh

Full deployment script that automates the entire deployment process.

**Usage:**
```bash
./scripts/deploy.sh
```

**What it does:**
1. Commits and pushes code changes to git
2. Transfers backend and web files to server (root@39.106.88.210)
3. Compiles backend on server with CGO enabled (required for SQLite)
4. Installs web dependencies
5. Restarts services using PM2
6. Runs health checks and verification tests

**Requirements:**
- SSH access to root@39.106.88.210
- rsync installed locally
- Go installed on server
- PM2 installed on server
- http-server installed on server

## Manual Deployment

If you need to deploy manually, follow these steps:

### 1. Transfer Files

```bash
# Backend
rsync -avz --exclude='personal-notes' --exclude='notes.db' \
  -e "ssh -o StrictHostKeyChecking=no" \
  backend/ root@39.106.88.210:/root/app/backend/

# Web
rsync -avz --exclude='node_modules' \
  -e "ssh -o StrictHostKeyChecking=no" \
  web/ root@39.106.88.210:/root/app/web/
```

### 2. Compile Backend

```bash
ssh root@39.106.88.210 "cd /root/app/backend && CGO_ENABLED=1 go build -o personal-notes main.go"
```

### 3. Restart Services

```bash
ssh root@39.106.88.210 "cd /root/app && pm2 restart all"
```

### 4. Verify Deployment

```bash
# Backend health
curl http://39.106.88.210:8080/health

# Web frontend
curl http://39.106.88.210:3000/
```

## Server Information

- **Server:** root@39.106.88.210
- **Backend Port:** 8080
- **Web Port:** 3000
- **Deploy Directory:** /root/app
- **Logs:** /root/app/logs

## PM2 Commands

```bash
pm2 status                    # Check service status
pm2 logs                      # View all logs
pm2 logs backend              # View backend logs
pm2 logs web                  # View web logs
pm2 restart all               # Restart all services
pm2 stop all                  # Stop all services
pm2 monit                     # Monitor services
```

## Troubleshooting

### Backend won't start
```bash
# Check logs
ssh root@39.106.88.210 "pm2 logs personal-notes-backend --lines 50"

# Verify binary exists and is executable
ssh root@39.106.88.210 "ls -lh /root/app/backend/personal-notes"

# Check if port is in use
ssh root@39.106.88.210 "netstat -tlnp | grep 8080"
```

### Web not accessible
```bash
# Check logs
ssh root@39.106.88.210 "pm2 logs personal-notes-web --lines 50"

# Verify http-server is installed
ssh root@39.106.88.210 "which http-server"

# Check if port is in use
ssh root@39.106.88.210 "netstat -tlnp | grep 3000"
```

### Database errors
```bash
# Check database file
ssh root@39.106.88.210 "ls -lh /root/app/backend/notes.db"

# Backup database
ssh root@39.106.88.210 "cp /root/app/backend/notes.db /root/app/backend/notes.db.backup"
```

## Rollback

If deployment fails:

```bash
# On server, check git history
ssh root@39.106.88.210 "cd /root/app && git log --oneline -5"

# Revert to previous version
ssh root@39.106.88.210 "cd /root/app && git checkout HEAD~1"

# Recompile backend
ssh root@39.106.88.210 "cd /root/app/backend && CGO_ENABLED=1 go build -o personal-notes main.go"

# Restart services
ssh root@39.106.88.210 "pm2 restart all"
```
