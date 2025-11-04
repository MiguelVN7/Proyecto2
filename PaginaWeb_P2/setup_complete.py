#!/usr/bin/env python3
"""
EcoTrack Admin - Instalador Automático Completo
Ejecutar: python3 setup_complete.py
"""

import os
import sys
from pathlib import Path

print("=" * 60)
print("🚀 INSTALADOR AUTOMÁTICO - EcoTrack Admin Dashboard")
print("=" * 60)
print()

# Verificar que estamos en el directorio correcto
if not Path('manage.py').exists():
    print("❌ Error: manage.py no encontrado")
    print("   Asegúrate de ejecutar este script desde la raíz del proyecto")
    sys.exit(1)

# PASO 1: Crear estructura de carpetas
print("📁 Paso 1/7: Creando estructura de carpetas...")
directories = [
    'reports/templates/reports',
    'reports/management/commands',
    'static/css',
    'media/reportes',
]

for directory in directories:
    Path(directory).mkdir(parents=True, exist_ok=True)
    if 'reports' in directory and 'templates' not in directory:
        (Path(directory) / '__init__.py').touch()

print("   ✅ Estructura creada")

# PASO 2: Crear models.py
print("📝 Paso 2/7: Creando models.py...")
models_content = """from django.db import models
from django.contrib.auth.models import AbstractUser
from django.utils import timezone


class User(AbstractUser):
    ZONAS = [
        ('norte', 'Norte'), ('sur', 'Sur'), ('centro', 'Centro'),
        ('oriente', 'Oriente'), ('occidente', 'Occidente'),
    ]
    zona_asignada = models.CharField(max_length=20, choices=ZONAS, default='centro')
    telefono = models.CharField(max_length=20, blank=True)
    fecha_registro = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Encargado'
        verbose_name_plural = 'Encargados'
    
    def __str__(self):
        return f"{self.get_full_name()} - {self.get_zona_asignada_display()}"


class Report(models.Model):
    TIPOS_RESIDUO = [
        ('organico', 'Orgánico'), ('plastico', 'Plástico'), ('vidrio', 'Vidrio'),
        ('papel', 'Papel/Cartón'), ('metal', 'Metal'), ('electronico', 'Electrónico'),
        ('textil', 'Textil'), ('peligroso', 'Peligroso'), ('construccion', 'Construcción'),
        ('otros', 'Otros'),
    ]
    ESTADOS = [
        ('pendiente', 'Pendiente'), ('asignado', 'Asignado'),
        ('en_proceso', 'En Proceso'), ('resuelto', 'Resuelto'), ('cancelado', 'Cancelado'),
    ]
    PRIORIDADES = [
        ('baja', 'Baja'), ('media', 'Media'), ('alta', 'Alta'), ('urgente', 'Urgente'),
    ]
    
    tipo_residuo = models.CharField(max_length=20, choices=TIPOS_RESIDUO)
    descripcion = models.TextField(blank=True)
    foto = models.ImageField(upload_to='reportes/', blank=True, null=True)
    foto_url = models.URLField(blank=True)
    latitud = models.DecimalField(max_digits=10, decimal_places=7)
    longitud = models.DecimalField(max_digits=10, decimal_places=7)
    direccion = models.CharField(max_length=255, blank=True)
    estado = models.CharField(max_length=20, choices=ESTADOS, default='pendiente')
    prioridad = models.CharField(max_length=20, choices=PRIORIDADES, default='media')
    assigned_to = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, 
                                    blank=True, related_name='reportes_asignados')
    fecha_reporte = models.DateTimeField(default=timezone.now)
    fecha_asignacion = models.DateTimeField(null=True, blank=True)
    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_resolucion = models.DateTimeField(null=True, blank=True)
    notas_resolucion = models.TextField(blank=True)
    reportado_por = models.CharField(max_length=100, blank=True)
    version_app = models.CharField(max_length=20, blank=True)
    
    class Meta:
        ordering = ['-fecha_reporte']
    
    def __str__(self):
        return f"Reporte #{self.id} - {self.get_tipo_residuo_display()}"


class ActionLog(models.Model):
    ACCIONES = [
        ('creado', 'Reporte Creado'), ('asignado', 'Asignado a Encargado'),
        ('iniciado', 'Trabajo Iniciado'), ('resuelto', 'Marcado como Resuelto'),
    ]
    reporte = models.ForeignKey(Report, on_delete=models.CASCADE, related_name='historial')
    usuario = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    accion = models.CharField(max_length=20, choices=ACCIONES)
    descripcion = models.TextField(blank=True)
    fecha_accion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-fecha_accion']
"""

Path('reports/models.py').write_text(models_content, encoding='utf-8')
print("   ✅ models.py creado")

# PASO 3: Crear views.py
print("📝 Paso 3/7: Creando views.py...")
views_content = """from django.shortcuts import render, redirect
from django.contrib.auth.decorators import login_required
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.db.models import Q
from .models import Report, User


def login_view(request):
    if request.user.is_authenticated:
        return redirect('dashboard')
    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')
        user = authenticate(request, username=username, password=password)
        if user:
            login(request, user)
            messages.success(request, f'¡Bienvenido {user.get_full_name()}!')
            return redirect('dashboard')
        else:
            messages.error(request, 'Usuario o contraseña incorrectos')
    return render(request, 'reports/login.html')


def logout_view(request):
    logout(request)
    messages.info(request, 'Sesión cerrada')
    return redirect('login')


@login_required
def dashboard_view(request):
    user = request.user
    context = {
        'reportes_asignados': Report.objects.filter(assigned_to=user, estado__in=['asignado', 'en_proceso']).count(),
        'reportes_resueltos': Report.objects.filter(assigned_to=user, estado='resuelto').count(),
        'reportes_pendientes': Report.objects.filter(estado='pendiente').count(),
        'ultimos_asignados': Report.objects.filter(assigned_to=user, estado__in=['asignado', 'en_proceso'])[:5],
    }
    return render(request, 'reports/dashboard.html', context)


@login_required
def reportes_asignados_view(request):
    reportes = Report.objects.filter(assigned_to=request.user, estado__in=['asignado', 'en_proceso'])
    
    if q := request.GET.get('q'):
        reportes = reportes.filter(Q(descripcion__icontains=q) | Q(direccion__icontains=q))
    if tipo := request.GET.get('tipo'):
        reportes = reportes.filter(tipo_residuo=tipo)
    if prioridad := request.GET.get('prioridad'):
        reportes = reportes.filter(prioridad=prioridad)
    
    context = {
        'reportes': reportes.order_by('-fecha_reporte'),
        'total_reportes': reportes.count(),
        'tipos_disponibles': Report.TIPOS_RESIDUO,
        'prioridades_disponibles': Report.PRIORIDADES,
    }
    return render(request, 'reports/reportes_asignados.html', context)


@login_required
def historial_view(request):
    reportes = Report.objects.filter(assigned_to=request.user, estado='resuelto')
    
    if q := request.GET.get('q'):
        reportes = reportes.filter(Q(descripcion__icontains=q) | Q(direccion__icontains=q))
    if tipo := request.GET.get('tipo'):
        reportes = reportes.filter(tipo_residuo=tipo)
    if desde := request.GET.get('fecha_desde'):
        reportes = reportes.filter(fecha_resolucion__gte=desde)
    if hasta := request.GET.get('fecha_hasta'):
        reportes = reportes.filter(fecha_resolucion__lte=hasta)
    
    context = {
        'reportes': reportes.order_by('-fecha_resolucion'),
        'total_resueltos': reportes.count(),
        'tipos_disponibles': Report.TIPOS_RESIDUO,
    }
    return render(request, 'reports/historial.html', context)
"""

Path('reports/views.py').write_text(views_content, encoding='utf-8')
print("   ✅ views.py creado")

# PASO 4: Crear URLs
print("📝 Paso 4/7: Creando URLs...")
reports_urls = """from django.urls import path
from . import views

urlpatterns = [
    path('', views.dashboard_view, name='dashboard'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('reportes-asignados/', views.reportes_asignados_view, name='reportes_asignados'),
    path('historial/', views.historial_view, name='historial'),
]
"""

Path('reports/urls.py').write_text(reports_urls, encoding='utf-8')

main_urls = """from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

urlpatterns = [
    path('admin/', admin.site.urls),
    path('', include('reports.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
"""

Path('ecotrack_admin/urls.py').write_text(main_urls, encoding='utf-8')
print("   ✅ URLs creados")

# PASO 5: Actualizar settings
print("📝 Paso 5/7: Actualizando settings.py...")
settings_file = Path('ecotrack_admin/settings.py')
content = settings_file.read_text(encoding='utf-8')

if "'reports'" not in content:
    content = content.replace("INSTALLED_APPS = [", "INSTALLED_APPS = [\n    'reports',")

if "AUTH_USER_MODEL" not in content:
    content += """

# EcoTrack Configuration
AUTH_USER_MODEL = 'reports.User'
LOGIN_URL = '/login/'
LOGIN_REDIRECT_URL = '/'
LOGOUT_REDIRECT_URL = '/login/'
MEDIA_URL = '/media/'
import os
MEDIA_ROOT = os.path.join(BASE_DIR, 'media')
LANGUAGE_CODE = 'es-co'
TIME_ZONE = 'America/Bogota'
"""

settings_file.write_text(content, encoding='utf-8')
print("   ✅ settings.py actualizado")

# PASO 6: Crear templates
print("📝 Paso 6/7: Creando templates HTML...")

base_html = """<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{% block title %}EcoTrack{% endblock %}</title>
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.10.0/font/bootstrap-icons.css" rel="stylesheet">
    <style>
        body { background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%); min-height: 100vh; }
        .navbar { background: linear-gradient(135deg, #2ecc71, #27ae60) !important; }
        .card { border-radius: 15px; box-shadow: 0 4px 6px rgba(0,0,0,0.1); border: none; }
        .badge-prioridad-urgente { background-color: #e74c3c; }
        .badge-prioridad-alta { background-color: #f39c12; }
        .badge-prioridad-media { background-color: #3498db; }
        .badge-prioridad-baja { background-color: #95a5a6; }
        .badge-estado-asignado { background-color: #3498db; }
        .badge-estado-en_proceso { background-color: #9b59b6; }
        .badge-estado-resuelto { background-color: #2ecc71; }
    </style>
</head>
<body>
    {% if user.is_authenticated %}
    <nav class="navbar navbar-expand-lg navbar-dark">
        <div class="container-fluid">
            <a class="navbar-brand" href="{% url 'dashboard' %}"><i class="bi bi-recycle"></i> EcoTrack</a>
            <div class="collapse navbar-collapse">
                <ul class="navbar-nav me-auto">
                    <li class="nav-item"><a class="nav-link" href="{% url 'dashboard' %}">Dashboard</a></li>
                    <li class="nav-item"><a class="nav-link" href="{% url 'reportes_asignados' %}">Reportes Asignados</a></li>
                    <li class="nav-item"><a class="nav-link" href="{% url 'historial' %}">Historial</a></li>
                </ul>
                <div class="text-white">
                    {{ user.get_full_name }} <a href="{% url 'logout' %}" class="btn btn-outline-light btn-sm">Salir</a>
                </div>
            </div>
        </div>
    </nav>
    {% endif %}
    <div class="container-fluid py-4">
        {% if messages %}{% for message in messages %}
        <div class="alert alert-{{ message.tags }} alert-dismissible fade show">
            {{ message }}<button type="button" class="btn-close" data-bs-dismiss="alert"></button>
        </div>
        {% endfor %}{% endif %}
        {% block content %}{% endblock %}
    </div>
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
</body>
</html>"""

login_html = """{% extends 'reports/base.html' %}
{% block content %}
<div class="row justify-content-center" style="min-height: 80vh; align-items: center;">
    <div class="col-md-5">
        <div class="card p-5">
            <div class="text-center mb-4">
                <i class="bi bi-recycle text-success" style="font-size: 4rem;"></i>
                <h2 class="mt-3">EcoTrack Admin</h2>
            </div>
            <form method="post">
                {% csrf_token %}
                <div class="mb-3">
                    <label>Usuario</label>
                    <input type="text" name="username" class="form-control" required>
                </div>
                <div class="mb-3">
                    <label>Contraseña</label>
                    <input type="password" name="password" class="form-control" required>
                </div>
                <button type="submit" class="btn btn-success w-100">Iniciar Sesión</button>
            </form>
            <small class="text-center d-block mt-3 text-muted">
                <strong>Usuarios:</strong> juan.perez / maria.garcia / carlos.lopez<br>
                <strong>Contraseña:</strong> ecotrack123
            </small>
        </div>
    </div>
</div>
{% endblock %}"""

dashboard_html = """{% extends 'reports/base.html' %}
{% block content %}
<h1><i class="bi bi-speedometer2"></i> Dashboard</h1>
<p>Bienvenido, {{ user.get_full_name }} - Zona {{ user.get_zona_asignada_display }}</p>
<div class="row mt-4">
    <div class="col-md-4"><div class="card p-4"><h3>{{ reportes_asignados }}</h3><p>Reportes Asignados</p></div></div>
    <div class="col-md-4"><div class="card p-4"><h3>{{ reportes_resueltos }}</h3><p>Reportes Resueltos</p></div></div>
    <div class="col-md-4"><div class="card p-4"><h3>{{ reportes_pendientes }}</h3><p>Reportes Pendientes</p></div></div>
</div>
<div class="card mt-4 p-4">
    <h5>Últimos Reportes Asignados</h5>
    {% if ultimos_asignados %}
    <table class="table mt-3">
        <tr><th>ID</th><th>Tipo</th><th>Ubicación</th><th>Estado</th><th>Fecha</th></tr>
        {% for r in ultimos_asignados %}
        <tr>
            <td>#{{ r.id }}</td>
            <td>{{ r.get_tipo_residuo_display }}</td>
            <td>{{ r.direccion|truncatewords:5 }}</td>
            <td><span class="badge badge-estado-{{ r.estado }}">{{ r.get_estado_display }}</span></td>
            <td>{{ r.fecha_reporte|date:"d/m/Y" }}</td>
        </tr>
        {% endfor %}
    </table>
    {% else %}<p>No hay reportes asignados</p>{% endif %}
</div>
{% endblock %}"""

asignados_html = """{% extends 'reports/base.html' %}
{% block content %}
<h1><i class="bi bi-clipboard-check"></i> Reportes Asignados (HU#1)</h1>
<div class="card p-4 mt-4">
    <form method="get" class="row g-3">
        <div class="col-md-3"><input type="text" name="q" class="form-control" placeholder="Buscar..."></div>
        <div class="col-md-2">
            <select name="tipo" class="form-select">
                <option value="">Todos los tipos</option>
                {% for v, l in tipos_disponibles %}<option value="{{ v }}">{{ l }}</option>{% endfor %}
            </select>
        </div>
        <div class="col-md-2">
            <select name="prioridad" class="form-select">
                <option value="">Todas</option>
                {% for v, l in prioridades_disponibles %}<option value="{{ v }}">{{ l }}</option>{% endfor %}
            </select>
        </div>
        <div class="col-md-2"><button type="submit" class="btn btn-success w-100">Filtrar</button></div>
    </form>
</div>
<div class="card mt-4 p-4">
    <h5>Total: {{ total_reportes }}</h5>
    <table class="table mt-3">
        <tr><th>ID</th><th>Tipo</th><th>Descripción</th><th>Ubicación</th><th>Prioridad</th><th>Fecha</th></tr>
        {% for r in reportes %}
        <tr>
            <td>#{{ r.id }}</td>
            <td><span class="badge bg-secondary">{{ r.get_tipo_residuo_display }}</span></td>
            <td>{{ r.descripcion|truncatewords:10 }}</td>
            <td>{{ r.direccion|truncatewords:5 }}</td>
            <td><span class="badge badge-prioridad-{{ r.prioridad }}">{{ r.get_prioridad_display }}</span></td>
            <td>{{ r.fecha_reporte|date:"d/m/Y" }}</td>
        </tr>
        {% empty %}<tr><td colspan="6" class="text-center">No hay reportes</td></tr>{% endfor %}
    </table>
</div>
{% endblock %}"""

historial_html = """{% extends 'reports/base.html' %}
{% block content %}
<h1><i class="bi bi-clock-history"></i> Historial (HU#2)</h1>
<div class="card p-4 mt-4">
    <form method="get" class="row g-3">
        <div class="col-md-2"><input type="text" name="q" class="form-control" placeholder="Buscar..."></div>
        <div class="col-md-2"><input type="date" name="fecha_desde" class="form-control"></div>
        <div class="col-md-2"><input type="date" name="fecha_hasta" class="form-control"></div>
        <div class="col-md-2">
            <select name="tipo" class="form-select">
                <option value="">Todos</option>
                {% for v, l in tipos_disponibles %}<option value="{{ v }}">{{ l }}</option>{% endfor %}
            </select>
        </div>
        <div class="col-md-2"><button type="submit" class="btn btn-success w-100">Filtrar</button></div>
    </form>
</div>
<div class="card mt-4 p-4">
    <h5>Total Resueltos: {{ total_resueltos }}</h5>
    <table class="table mt-3">
        <tr><th>ID</th><th>Tipo</th><th>Ubicación</th><th>Fecha Reporte</th><th>Fecha Resolución</th><th>Notas</th></tr>
        {% for r in reportes %}
        <tr>
            <td>#{{ r.id }}</td>
            <td>{{ r.get_tipo_residuo_display }}</td>
            <td>{{ r.direccion|truncatewords:5 }}</td>
            <td>{{ r.fecha_reporte|date:"d/m/Y" }}</td>
            <td>{{ r.fecha_resolucion|date:"d/m/Y" }}</td>
            <td>{{ r.notas_resolucion|truncatewords:10 }}</td>
        </tr>
        {% empty %}<tr><td colspan="6" class="text-center">No hay reportes resueltos</td></tr>{% endfor %}
    </table>
</div>
{% endblock %}"""

templates = {
    'base.html': base_html,
    'login.html': login_html,
    'dashboard.html': dashboard_html,
    'reportes_asignados.html': asignados_html,
    'historial.html': historial_html,
}

for filename, content in templates.items():
    Path(f'reports/templates/reports/{filename}').write_text(content, encoding='utf-8')

print("   ✅ Templates creados")

# PASO 7: Crear comando de datos
print("📝 Paso 7/7: Creando comando load_sample_data...")

command_content = """from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import random
from reports.models import User, Report, ActionLog


class Command(BaseCommand):
    help = 'Carga datos de ejemplo'

    def handle(self, *args, **options):
        self.stdout.write('Cargando datos...')
        ActionLog.objects.all().delete()
        Report.objects.all().delete()
        User.objects.filter(is_superuser=False).delete()
        
        # Crear encargados
        encargados_data = [
            {'username': 'juan.perez', 'email': 'juan@ecotrack.com', 'first_name': 'Juan',
             'last_name': 'Pérez', 'zona_asignada': 'norte'},
            {'username': 'maria.garcia', 'email': 'maria@ecotrack.com', 'first_name': 'María',
             'last_name': 'García', 'zona_asignada': 'sur'},
            {'username': 'carlos.lopez', 'email': 'carlos@ecotrack.com', 'first_name': 'Carlos',
             'last_name': 'López', 'zona_asignada': 'centro'},
        ]
        
        encargados = []
        for data in encargados_data:
            user = User.objects.create_user(password='ecotrack123', **data)
            encargados.append(user)
        
        # Crear reportes
        ubicaciones = [
            (6.244203, -75.581212, 'Calle 50 #30-20, El Poblado'),
            (6.230833, -75.590553, 'Carrera 45 #22-10, Laureles'),
            (6.267417, -75.568389, 'Avenida 33 #15-40, Buenos Aires'),
        ]
        
        tipos = ['organico', 'plastico', 'vidrio', 'papel', 'metal']
        ahora = timezone.now()
        
        for i in range(20):
            tipo = random.choice(tipos)
            ubicacion = random.choice(ubicaciones)
            dias = random.randint(0, 30)
            fecha_reporte = ahora - timedelta(days=dias)
            
            estado = 'pendiente' if dias < 2 else ('resuelto' if dias > 10 else random.choice(['asignado', 'en_proceso']))
            assigned = random.choice(encargados) if estado != 'pendiente' else None
            
            reporte = Report.objects.create(
                tipo_residuo=tipo,
                descripcion=f'Acumulación de {tipo}',
                latitud=Decimal(str(ubicacion[0])),
                longitud=Decimal(str(ubicacion[1])),
                direccion=ubicacion[2],
                estado=estado,
                prioridad=random.choice(['baja', 'media', 'alta']),
                assigned_to=assigned,
                fecha_reporte=fecha_reporte,
            )
            
            if estado == 'resuelto':
                reporte.fecha_resolucion = fecha_reporte + timedelta(days=random.randint(1, 5))
                reporte.notas_resolucion = 'Residuos recolectados correctamente'
                reporte.save()
        
        self.stdout.write(self.style.SUCCESS(f'✅ {len(encargados)} encargados, 20 reportes creados'))
        self.stdout.write('Usuarios: juan.perez, maria.garcia, carlos.lopez | Password: ecotrack123')
"""

Path('reports/management/commands/load_sample_data.py').write_text(command_content, encoding='utf-8')
print("   ✅ Comando creado")

print()
print("=" * 60)
print("✅ INSTALACIÓN COMPLETADA")
print("=" * 60)
print()
print("📋 SIGUIENTES PASOS:")
print()
print("1️⃣  Crear migraciones:")
print("    python manage.py makemigrations")
print()
print("2️⃣  Aplicar migraciones:")
print("    python manage.py migrate")
print()
print("3️⃣  Cargar datos de ejemplo:")
print("    python manage.py load_sample_data")
print()
print("4️⃣  Ejecutar servidor:")
print("    python manage.py runserver")
print()
print("5️⃣  Abrir navegador:")
print("    http://127.0.0.1:8000")
print()
print("👤 USUARIOS DE PRUEBA:")
print("    Usuario: juan.perez")
print("    Password: ecotrack123")
print()
print("=" * 60)
