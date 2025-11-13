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
from reports.models import User, Cuadrilla

# Crear superuser
if not User.objects.filter(username='admin').exists():
    User.objects.create_superuser(username='admin', email='admin@ecotrack.com', password='ecotrack123')
    print('✅ Superuser created: admin / ecotrack123')
else:
    print('ℹ️  Superuser already exists')

# Crear usuarios de cuadrilla por zona
zonas_data = [
    ('norte', 'Norte'),
    ('sur', 'Sur'),
    ('centro', 'Centro'),
    ('oriente', 'Oriente'),
    ('occidente', 'Occidente'),
]

usuarios_creados = []
for zona_key, zona_name in zonas_data:
    # Crear 2 usuarios por zona
    for i in range(1, 3):
        username = f'operador_{zona_key}_{i}'
        if not User.objects.filter(username=username).exists():
            user = User.objects.create_user(
                username=username,
                email=f'{username}@ecotrack.com',
                password='ecotrack123',
                first_name=f'Operador {i}',
                last_name=zona_name,
                zona_asignada=zona_key,
                telefono=f'555-{zona_key[:3].upper()}-{1000+i}'
            )
            usuarios_creados.append(user)
            print(f'✅ Usuario creado: {username} (Zona: {zona_name})')
        else:
            print(f'ℹ️  Usuario ya existe: {username}')

# Crear cuadrillas si no existen
for zona_key, zona_name in zonas_data:
    cuadrilla_nombre = f'Cuadrilla {zona_name}'
    cuadrilla, created = Cuadrilla.objects.get_or_create(
        nombre=cuadrilla_nombre,
        defaults={
            'zona_asignada': zona_key,
            'capacidad_diaria': 10,
            'activa': True
        }
    )

    if created:
        print(f'✅ Cuadrilla creada: {cuadrilla_nombre}')

    # Asignar usuarios a la cuadrilla
    usuarios_zona = User.objects.filter(zona_asignada=zona_key, is_superuser=False)
    if usuarios_zona.exists():
        cuadrilla.miembros.set(usuarios_zona)
        print(f'✅ Asignados {usuarios_zona.count()} miembros a {cuadrilla_nombre}')

print('✅ Configuración de usuarios y cuadrillas completa')
EOF

echo "✅ Starting gunicorn..."
exec gunicorn --bind 0.0.0.0:${PORT:-8080} \
    --workers 2 \
    --threads 4 \
    --timeout 0 \
    --access-logfile - \
    --error-logfile - \
    ecotrack_admin.wsgi:application
