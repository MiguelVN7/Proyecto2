#!/usr/bin/env python
"""
Script to create default users for EcoTrack Admin
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ecotrack_admin.settings')
django.setup()

from reports.models import User, Cuadrilla

def create_default_users():
    print("Creating default users...")

    # Create superuser
    if not User.objects.filter(username='admin').exists():
        User.objects.create_superuser(
            username='admin',
            email='admin@ecotrack.com',
            password='ecotrack123',
            nombre='Administrador',
            tipo_usuario='empresa'
        )
        print("✅ Superuser 'admin' created (password: ecotrack123)")
    else:
        print("ℹ️  Superuser 'admin' already exists")

    # Create company users
    company_users = [
        {'username': 'juan.perez', 'nombre': 'Juan Pérez', 'email': 'juan.perez@ecotrack.com'},
        {'username': 'maria.garcia', 'nombre': 'María García', 'email': 'maria.garcia@ecotrack.com'},
        {'username': 'carlos.lopez', 'nombre': 'Carlos López', 'email': 'carlos.lopez@ecotrack.com'},
    ]

    for user_data in company_users:
        if not User.objects.filter(username=user_data['username']).exists():
            User.objects.create_user(
                username=user_data['username'],
                email=user_data['email'],
                password='ecotrack123',
                nombre=user_data['nombre'],
                tipo_usuario='empresa'
            )
            print(f"✅ User '{user_data['username']}' created (password: ecotrack123)")
        else:
            print(f"ℹ️  User '{user_data['username']}' already exists")

    # Create a sample cuadrilla if it doesn't exist
    if not Cuadrilla.objects.filter(nombre='Cuadrilla Principal').exists():
        Cuadrilla.objects.create(
            nombre='Cuadrilla Principal',
            descripcion='Cuadrilla de recolección principal',
            activo=True
        )
        print("✅ Cuadrilla 'Cuadrilla Principal' created")
    else:
        print("ℹ️  Cuadrilla 'Cuadrilla Principal' already exists")

    print("\n🎉 User setup complete!")
    print("\nLogin credentials:")
    print("  Username: admin | Password: ecotrack123 (Superuser)")
    print("  Username: juan.perez | Password: ecotrack123")
    print("  Username: maria.garcia | Password: ecotrack123")
    print("  Username: carlos.lopez | Password: ecotrack123")

if __name__ == '__main__':
    create_default_users()
