module.exports = {
  apps: [
    {
      name: 'personal-notes-backend',
      script: '/root/app/backend/personal-notes',
      cwd: '/root/app/backend',
      instances: 1,
      autorestart: true,
      watch: false,
      max_memory_restart: '1G',
      env: {
        UPLOAD_DIR: '/var/www/uploads/avatars',
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
