from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from django.contrib.auth import authenticate, login, logout
from django.contrib import messages
from django.db.models import Q, Count
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.utils import timezone
from django.core.cache import cache
import json
from .models import Report, User, Cuadrilla
from .firestore_service import firestore_service


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
    """Dashboard usando datos de Firestore"""
    user = request.user

    # Obtener todos los reportes de Firestore (con cache)
    cache_key = 'firestore_reports_all'
    all_reports = cache.get(cache_key)

    if all_reports is None:
        all_reports = firestore_service.get_all_reports(limit=500)
        cache.set(cache_key, all_reports, 300)

    # Calcular estadísticas
    reportes_pendientes = [r for r in all_reports
                          if r.get('estado') == 'pendiente']
    reportes_asignados = [r for r in all_reports
                         if r.get('estado') in ['asignado', 'en_proceso']]
    reportes_resueltos = [r for r in all_reports
                         if r.get('estado') == 'resuelto']

    context = {
        'reportes_asignados': len(reportes_asignados),
        'reportes_resueltos': len(reportes_resueltos),
        'reportes_pendientes': len(reportes_pendientes),
        'ultimos_asignados': reportes_asignados[:5],
        'total_reportes': len(all_reports),
        'usando_firestore': True,
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


@login_required
def gestion_reportes_view(request):
    """Vista de gestión de reportes usando Firestore"""

    # Intentar obtener reportes de cache
    cache_key = 'firestore_reports_all'
    reportes_firestore = cache.get(cache_key)

    if reportes_firestore is None:
        # Obtener todos los reportes de Firestore
        reportes_firestore = firestore_service.get_all_reports(limit=500)
        # Guardar en cache por 5 minutos
        cache.set(cache_key, reportes_firestore, 300)

    # Aplicar filtros
    reportes_filtrados = reportes_firestore.copy()

    if estado := request.GET.get('estado'):
        reportes_filtrados = [r for r in reportes_filtrados
                             if r.get('estado') == estado]

    if tipo := request.GET.get('tipo'):
        reportes_filtrados = [r for r in reportes_filtrados
                             if r.get('tipo_residuo') == tipo]

    if prioridad := request.GET.get('prioridad'):
        reportes_filtrados = [r for r in reportes_filtrados
                             if r.get('prioridad') == prioridad]

    # Datos para el mapa
    reportes_mapa = []
    for reporte in reportes_filtrados:
        if reporte.get('latitud') and reporte.get('longitud'):
            reportes_mapa.append({
                'id': reporte['id'],
                'lat': float(reporte['latitud']),
                'lng': float(reporte['longitud']),
                'tipo': reporte.get('tipo_residuo', 'otros'),
                'prioridad': reporte.get('prioridad', 'media'),
                'estado': reporte.get('estado', 'pendiente'),
                'direccion': reporte.get('direccion', ''),
                'cuadrilla': reporte.get('assigned_to_name', 'Sin asignar'),
                'descripcion': reporte.get('descripcion', '')[:100]
            })

    context = {
        'reportes': reportes_filtrados,
        'total_reportes': len(reportes_filtrados),
        'reportes_mapa': json.dumps(reportes_mapa),
        'cuadrillas': Cuadrilla.objects.filter(activa=True),
        'tipos_disponibles': Report.TIPOS_RESIDUO,
        'estados_disponibles': Report.ESTADOS,
        'prioridades_disponibles': Report.PRIORIDADES,
        'usando_firestore': True,  # Flag para templates
    }
    return render(request, 'reports/gestion_reportes.html', context)


@login_required
def cuadrillas_view(request):
    cuadrillas = Cuadrilla.objects.annotate(
        reportes_activos=Count('miembros__reportes_asignados', 
                             filter=Q(miembros__reportes_asignados__estado__in=['asignado', 'en_proceso']))
    )
    usuarios_disponibles = User.objects.filter(is_staff=False, is_superuser=False)
    
    context = {
        'cuadrillas': cuadrillas,
        'usuarios_disponibles': usuarios_disponibles,
    }
    return render(request, 'reports/cuadrillas.html', context)


@login_required
def crear_cuadrilla_view(request):
    if request.method == 'POST':
        nombre = request.POST.get('nombre')
        zona_asignada = request.POST.get('zona_asignada')
        capacidad_diaria = request.POST.get('capacidad_diaria', 10)
        miembros_ids = request.POST.getlist('miembros[]')
        
        try:
            cuadrilla = Cuadrilla.objects.create(
                nombre=nombre,
                zona_asignada=zona_asignada or None,
                capacidad_diaria=int(capacidad_diaria)
            )
            
            if miembros_ids:
                miembros = User.objects.filter(id__in=miembros_ids)
                cuadrilla.miembros.set(miembros)
            
            messages.success(request, f'Cuadrilla "{nombre}" creada exitosamente')
        except Exception as e:
            messages.error(request, f'Error al crear la cuadrilla: {str(e)}')
    
    return redirect('cuadrillas')


@login_required
@csrf_exempt
def asignar_reportes_masivo_view(request):
    """Asignar reportes a cuadrilla - Actualiza Firestore"""
    if request.method == 'POST':
        try:
            cuadrilla_id = request.POST.get('cuadrilla_id')
            reportes_ids = request.POST.getlist('reportes_ids[]')

            cuadrilla = get_object_or_404(Cuadrilla, id=cuadrilla_id)

            # Asignar reportes a los miembros de la cuadrilla
            miembros = list(cuadrilla.miembros.all())
            if not miembros:
                return JsonResponse({
                    'success': False,
                    'error': 'La cuadrilla no tiene miembros'
                })

            # Actualizar reportes en Firestore
            asignados = 0
            for i, reporte_id in enumerate(reportes_ids):
                miembro = miembros[i % len(miembros)]

                # Actualizar en Firestore
                success = firestore_service.assign_report_to_user(
                    reporte_id,
                    str(miembro.id),
                    miembro.get_full_name()
                )

                if success:
                    asignados += 1

            # Limpiar cache
            cache.delete('firestore_reports_all')

            return JsonResponse({
                'success': True,
                'message': f'{asignados} reportes asignados a {cuadrilla.nombre}'
            })

        except Exception as e:
            return JsonResponse({'success': False, 'error': str(e)})

    return JsonResponse({
        'success': False,
        'error': 'Método no permitido'
    })


@login_required
def cerrar_reporte_view(request, reporte_id):
    reporte = get_object_or_404(Report, id=reporte_id, assigned_to=request.user)

    if request.method == 'POST':
        foto_validacion = request.FILES.get('foto_validacion')
        notas_resolucion = request.POST.get('notas_resolucion', '')

        if foto_validacion:
            reporte.foto_validacion = foto_validacion
            reporte.notas_resolucion = notas_resolucion
            reporte.estado = 'resuelto'
            reporte.fecha_resolucion = timezone.now()
            reporte.fecha_foto_validacion = timezone.now()
            reporte.save()

            messages.success(request, f'Reporte #{reporte.id} cerrado exitosamente')
            return redirect('reportes_asignados')
        else:
            messages.error(request, 'La foto de validación es obligatoria')

    context = {'reporte': reporte}
    return render(request, 'reports/cerrar_reporte.html', context)


@login_required
@csrf_exempt
def cambiar_estado_reporte_view(request):
    """
    API endpoint para cambiar el estado de un reporte en Firestore
    Los cambios se sincronizan automáticamente con la app móvil
    """
    if request.method == 'POST':
        try:
            data = json.loads(request.body)
            reporte_id = data.get('reporte_id')
            nuevo_estado = data.get('estado')

            if not reporte_id or not nuevo_estado:
                return JsonResponse({
                    'success': False,
                    'error': 'Faltan parámetros requeridos'
                }, status=400)

            # Mapear estados de Django a Firestore
            estado_mapping = {
                'pendiente': 'received',
                'asignado': 'assigned',
                'en_proceso': 'in_progress',
                'resuelto': 'completed',
                'cancelado': 'cancelled'
            }

            estado_firestore = estado_mapping.get(nuevo_estado, nuevo_estado)

            # Actualizar en Firestore
            success = firestore_service.update_report_status(
                reporte_id,
                estado_firestore
            )

            if success:
                # Limpiar cache para reflejar cambios
                cache.delete('firestore_reports_all')

                return JsonResponse({
                    'success': True,
                    'message': f'Estado del reporte {reporte_id} actualizado a {nuevo_estado}',
                    'reporte_id': reporte_id,
                    'nuevo_estado': nuevo_estado
                })
            else:
                return JsonResponse({
                    'success': False,
                    'error': 'No se pudo actualizar el reporte en Firestore'
                }, status=500)

        except json.JSONDecodeError:
            return JsonResponse({
                'success': False,
                'error': 'JSON inválido'
            }, status=400)
        except Exception as e:
            return JsonResponse({
                'success': False,
                'error': str(e)
            }, status=500)

    return JsonResponse({
        'success': False,
        'error': 'Método no permitido. Use POST'
    }, status=405)
