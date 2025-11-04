#!/bin/bash
set -e

echo "=== Starting EcoTrack Web ==="
cd /app
export PYTHONPATH=/app:$PYTHONPATH

echo "Waiting for database..."
sleep 5

echo "Running migrations..."
python manage.py migrate --noinput

echo "Creating superuser if not exists..."
python manage.py shell << 'EOF'
from reports.models import User
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(username='admin', email='admin@ecotrack.com', password='ecotrack123')
    print('✅ Superuser created: admin / ecotrack123')
else:
    print('ℹ️  Superuser already exists')
EOF

echo "✅ Starting gunicorn..."
exec gunicorn --bind 0.0.0.0:${PORT:-8080} \
    --workers 2 \
    --threads 4 \
    --timeout 0 \
    --access-logfile - \
    --error-logfile - \
    ecotrack_admin.wsgi:application
