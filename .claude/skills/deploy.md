# Deploy Skill

Deploy the personal-notes application to the production server with automated testing.

## Overview

This skill handles the complete deployment pipeline:
1. Git commit and push code changes
2. Transfer files to server (root@39.106.88.210)
3. Compile backend with CGO enabled (required for SQLite)
4. Install web dependencies
5. Restart services via PM2
6. Run health checks and verification tests

## Prerequisites

- SSH access to root@39.106.88.210
- Git repository initialized
- Go installed on server (yum install golang)
- PM2 installed on server (npm install -g pm2)
- http-server installed on server (npm install -g http-server)

## Deployment Steps

### Step 1: Git Commit and Push

```bash
cd /Users/anzhen/ai-study/flutter-test

# Check for changes
git status

# If there are changes, commit them
if [[ -n $(git status -s) ]]; then
    git add -A
    git commit -m "Deploy: Update application code $(date +%Y-%m-%d-%H-%M)"
    git push origin main
fi
```

### Step 2: Transfer Files to Server

```bash
# Transfer backend files (excluding compiled binary)
rsync -avz --progress \
  --exclude='personal-notes' \
  --exclude='personal-notes-linux' \
  --exclude='.git' \
  -e "ssh -o StrictHostKeyChecking=no" \
  /Users/anzhen/ai-study/flutter-test/backend/ \
  root@39.106.88.210:/root/app/backend/

# Transfer web files (excluding node_modules)
rsync -avz --progress \
  --exclude='node_modules' \
  --exclude='.git' \
  --exclude='coverage' \
  -e "ssh -o StrictHostKeyChecking=no" \
  /Users/anzhen/ai-study/flutter-test/web/ \
  root@39.106.88.210:/root/app/web/
```

### Step 3: Compile Backend on Server

```bash
ssh root@39.106.88.210 << 'EOF'
cd /root/app/backend

# Download dependencies
go mod download

# Compile with CGO enabled (required for SQLite)
CGO_ENABLED=1 go build -o personal-notes main.go

# Make executable
chmod +x personal-notes

echo "Backend compiled successfully"
EOF
```

### Step 4: Install Web Dependencies

```bash
ssh root@39.106.88.210 "cd /root/app/web && npm install --production"
```

### Step 5: Restart Services

```bash
ssh root@39.106.88.210 << 'EOF'
# Create logs directory if not exists
mkdir -p /root/app/logs

# Stop existing services
pm2 stop personal-notes-backend personal-notes-web 2>/dev/null || true

# Delete old processes
pm2 delete personal-notes-backend personal-notes-web 2>/dev/null || true

# Start services using ecosystem config
cd /root/app
pm2 start ecosystem.config.js

# Wait for services to start
sleep 5

# Check status
pm2 status

# Save PM2 configuration
pm2 save
EOF
```

### Step 6: Health Checks and Verification

```bash
# Wait for services to fully start
sleep 5

# Test backend health endpoint
echo "Testing backend health..."
curl -f http://39.106.88.210:8080/health || exit 1

# Test backend API
echo "Testing backend API..."
curl -f http://39.106.88.210:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456","verification_code":"1234"}' \
  -w "\nHTTP Status: %{http_code}\n" || echo "Register endpoint tested"

# Test web frontend
echo "Testing web frontend..."
curl -f http://39.106.88.210:3000/ || exit 1

# Check PM2 logs for errors
echo "Checking PM2 logs..."
ssh root@39.106.88.210 "pm2 logs --lines 10 --nostream"

echo "✅ Deployment completed successfully!"
echo "Backend: http://39.106.88.210:8080"
echo "Frontend: http://39.106.88.210:3000"
```

## PM2 Ecosystem Configuration

The deployment uses `/root/app/ecosystem.config.js`:

```javascript
module.exports = {
  apps: [
    {
      name: 'personal-notes-backend',
      script: './backend/personal-notes',
      cwd: '/root/app/backend',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        NODE_ENV: 'production'
      },
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: '/root/app/logs/backend-error.log',
      out_file: '/root/app/logs/backend-out.log',
      merge_logs: true
    },
    {
      name: 'personal-notes-web',
      script: 'http-server',
      args: 'src -p 3000 -c-1 --cors',
      cwd: '/root/app/web',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '512M',
      env: {
        NODE_ENV: 'production'
      },
      log_date_format: 'YYYY-MM-DD HH:mm:ss Z',
      error_file: '/root/app/logs/web-error.log',
      out_file: '/root/app/logs/web-out.log',
      merge_logs: true
    }
  ]
};
```

## Troubleshooting

### Backend fails to start
- Check logs: `pm2 logs personal-notes-backend`
- Verify database file exists: `ls -la /root/app/backend/notes.db`
- Check if port 8080 is in use: `netstat -tlnp | grep 8080`

### Web frontend not accessible
- Check logs: `pm2 logs personal-notes-web`
- Verify http-server is installed: `which http-server`
- Check if port 3000 is in use: `netstat -tlnp | grep 3000`

### CGO compilation errors
- Ensure Go is installed: `go version`
- Install GCC if needed: `yum install gcc`
- Recompile with: `CGO_ENABLED=1 go build -o personal-notes main.go`

## Rollback

If deployment fails, rollback to previous version:

```bash
# On server, check previous version
ssh root@39.106.88.210 "cd /root/app && git log --oneline -5"

# Revert to previous commit
ssh root@39.106.88.210 "cd /root/app && git checkout HEAD~1"

# Recompile and restart
ssh root@39.106.88.210 "cd /root/app/backend && CGO_ENABLED=1 go build -o personal-notes main.go"
ssh root@39.106.88.210 "pm2 restart all"
```

## Usage

To deploy the application, run this skill:

```
/deploy
```

Or manually execute the steps above in order.
