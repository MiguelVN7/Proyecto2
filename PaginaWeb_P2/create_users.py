#!/usr/bin/env python
"""Script para crear usuarios y cuadrillas en Cloud SQL"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ecotrack_admin.settings')
django.setup()

from reports.models import User, Cuadrilla

def create_users_and_cuadrillas():
    print("=== Creando usuarios y cuadrillas ===\n")

    # Crear superuser
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser(
            username='admin',
            email='admin@ecotrack.com',
            password='ecotrack123'
        )
        print('✅ Superuser creado: admin / ecotrack123')
    else:
        print('ℹ️  Superuser ya existe: admin')

    # Definir zonas
    zonas_data = [
        ('norte', 'Norte'),
        ('sur', 'Sur'),
        ('centro', 'Centro'),
        ('oriente', 'Oriente'),
        ('occidente', 'Occidente'),
    ]

    # Crear usuarios por zona
    print("\n--- Creando usuarios ---")
    for zona_key, zona_name in zonas_data:
        for i in range(1, 3):  # 2 usuarios por zona
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
                print(f'✅ Usuario creado: {username} (Zona: {zona_name})')
            else:
                print(f'ℹ️  Usuario ya existe: {username}')

    # Crear cuadrillas
    print("\n--- Creando cuadrillas ---")
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
        else:
            print(f'ℹ️  Cuadrilla ya existe: {cuadrilla_nombre}')

        # Asignar usuarios a la cuadrilla
        usuarios_zona = User.objects.filter(zona_asignada=zona_key, is_superuser=False)
        if usuarios_zona.exists():
            cuadrilla.miembros.set(usuarios_zona)
            print(f'   → {usuarios_zona.count()} miembros asignados')

    # Resumen final
    print("\n=== Resumen ===")
    print(f"Total usuarios: {User.objects.count()}")
    print(f"Total cuadrillas: {Cuadrilla.objects.count()}")
    print("\n📋 Usuarios creados:")
    for user in User.objects.all().order_by('zona_asignada', 'username'):
        zona = user.get_zona_asignada_display() if user.zona_asignada else 'Sin zona'
        print(f"  - {user.username} | {zona} | Password: ecotrack123")

if __name__ == '__main__':
    create_users_and_cuadrillas()
