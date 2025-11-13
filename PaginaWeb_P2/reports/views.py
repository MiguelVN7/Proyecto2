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
import re
from .models import Report, User, Cuadrilla
from .firestore_service import firestore_service


def _normalize_value(value):
    """Normalize values for comparisons (case/whitespace insensitive)."""
    return str(value or '').strip().lower()


def _tokenize(value):
    """Split a string into lowercase tokens for fuzzy matching."""
    if not value:
        return set()
    tokens = re.split(r'[^a-z0-9]+', _normalize_value(value))
    return {token for token in tokens if token}


def _pertenece_a_usuario(reporte, user_identifiers, user_identifiers_normalized, user_token_sets):
    """Return True si el reporte está asignado al usuario actual (loose matching)."""
    assigned_to = str(reporte.get('assigned_to') or '').strip()
    assigned_to_normalized = _normalize_value(assigned_to)
    assigned_name = _normalize_value(reporte.get('assigned_to_name'))

    if assigned_to:
        if (assigned_to in user_identifiers or
                assigned_to_normalized in user_identifiers_normalized):
            return True

    if assigned_name:
        assigned_tokens = _tokenize(assigned_name)
        if assigned_tokens:
            for token_set in user_token_sets:
                if token_set and token_set.issubset(assigned_tokens):
                    return True

    return False


def _matches_tipo_residuo(reporte, tipo_objetivo):
    """Compare report type (dict o modelo) contra la opción seleccionada."""
    if not tipo_objetivo:
        return True

    tipo_normalizado = _normalize_value(tipo_objetivo)

    if isinstance(reporte, dict):
        posibles = [
            reporte.get('tipo_residuo'),
            reporte.get('tipo_residuo_display'),
        ]

        raw_data = reporte.get('_firestore_data', {})
        clasificacion_raw = raw_data.get('clasificacion') or raw_data.get('tipo_residuo')
        ai_suggested = raw_data.get('ai_suggested_classification')
        if clasificacion_raw:
            posibles.append(firestore_service._map_clasificacion_to_django(clasificacion_raw))
        if ai_suggested:
            posibles.append(firestore_service._map_clasificacion_to_django(ai_suggested))
    else:
        posibles = [getattr(reporte, 'tipo_residuo', '')]

    posibles_normalizados = {_normalize_value(valor) for valor in posibles if valor is not None}
    return tipo_normalizado in posibles_normalizados


def _matches_search_text(reporte, termino):
    """Check if the search term appears in relevant fields."""
    termino_normalizado = _normalize_value(termino)
    if not termino_normalizado:
        return True

    if isinstance(reporte, dict):
        campos = [
            reporte.get('descripcion', ''),
            reporte.get('direccion', ''),
            str(reporte.get('id', '')),
            reporte.get('tipo_residuo_display', ''),
            reporte.get('tipo_residuo', ''),
        ]
    else:
        campos = [
            getattr(reporte, 'descripcion', ''),
            getattr(reporte, 'direccion', ''),
            str(getattr(reporte, 'id', '')),
            reporte.get_tipo_residuo_display() if hasattr(reporte, 'get_tipo_residuo_display') else '',
        ]

    return any(termino_normalizado in _normalize_value(valor) for valor in campos if valor is not None)


def _get_fecha_reporte(reporte):
    """Return fecha_reporte from dict or model."""
    if isinstance(reporte, dict):
        return reporte.get('fecha_reporte')
    return getattr(reporte, 'fecha_reporte', None)


def _fecha_sort_key(reporte):
    """Numerical value to sort reports by fecha_reporte."""
    fecha = _get_fecha_reporte(reporte)
    if not fecha:
        return 0
    try:
        return fecha.timestamp()
    except Exception:
        return 0


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

    # Calcular estadísticas usando los estados actuales
    reportes_recibidos = [r for r in all_reports
                          if r.get('estado') == 'recibido']
    reportes_asignados = [r for r in all_reports
                          if r.get('estado') in ['asignado', 'en_proceso']]
    reportes_resueltos = [r for r in all_reports
                          if r.get('estado') == 'resuelto']

    context = {
        'reportes_asignados': len(reportes_asignados),
        'reportes_resueltos': len(reportes_resueltos),
        'reportes_recibidos': len(reportes_recibidos),
        'ultimos_asignados': reportes_asignados[:5],
        'total_reportes': len(all_reports),
        'usando_firestore': True,
    }
    return render(request, 'reports/dashboard.html', context)


@login_required
def reportes_asignados_view(request):
    """Lista de reportes asignados al usuario autenticado usando datos de Firestore."""
    filtro_q = request.GET.get('q', '').strip()
    filtro_tipo = request.GET.get('tipo', '')
    filtro_prioridad = request.GET.get('prioridad', '')

    usando_firestore = True

    # Identificadores posibles para el usuario actual (ids, username, nombre completo)
    user_identifiers_raw = {
        str(request.user.id),
        request.user.username or '',
        request.user.email or '',
        request.user.get_full_name() or '',
        f"{request.user.first_name} {request.user.last_name}".strip(),
    }
    user_identifiers = {ident.strip() for ident in user_identifiers_raw if ident and ident.strip()}
    user_identifiers_normalized = {_normalize_value(ident) for ident in user_identifiers}
    token_sources = user_identifiers | {
        request.user.get_full_name(),
        request.user.first_name,
        request.user.last_name,
        request.user.username.replace('_', ' ') if request.user.username else '',
    }
    user_token_sets = [_tokenize(value) for value in token_sources if value]

    try:
        cache_key = 'firestore_reports_all'
        reportes_firestore = cache.get(cache_key)

        if reportes_firestore is None:
            reportes_firestore = firestore_service.get_all_reports(limit=500)
            cache.set(cache_key, reportes_firestore, 300)

        reportes_base = []
        for reporte in reportes_firestore:
            estado = reporte.get('estado')
            if estado not in ['asignado', 'en_proceso']:
                continue

            if _pertenece_a_usuario(
                reporte,
                user_identifiers,
                user_identifiers_normalized,
                user_token_sets
            ):
                reportes_base.append(reporte)

        # Fallback: si no se encontraron coincidencias, reintentar con el modelo local
        if not reportes_base:
            queryset_local = Report.objects.filter(
                assigned_to=request.user,
                estado__in=['asignado', 'en_proceso']
            )
            if queryset_local.exists():
                usando_firestore = False
                reportes_base = queryset_local
    except Exception:
        # Fallback al modelo local en caso de error con Firestore
        usando_firestore = False
        reportes_base = Report.objects.filter(
            assigned_to=request.user,
            estado__in=['asignado', 'en_proceso']
        )

    reportes_filtrados = reportes_base

    if filtro_q:
        if usando_firestore:
            reportes_filtrados = [
                r for r in reportes_filtrados
                if _matches_search_text(r, filtro_q)
            ]
        else:
            reportes_filtrados = reportes_filtrados.filter(
                Q(descripcion__icontains=filtro_q) |
                Q(direccion__icontains=filtro_q)
            )

    if filtro_tipo:
        if usando_firestore:
            reportes_filtrados = [r for r in reportes_filtrados if _matches_tipo_residuo(r, filtro_tipo)]
        else:
            reportes_filtrados = reportes_filtrados.filter(tipo_residuo=filtro_tipo)

    if filtro_prioridad:
        if usando_firestore:
            reportes_filtrados = [
                r for r in reportes_filtrados
                if _normalize_value(r.get('prioridad')) == _normalize_value(filtro_prioridad)
            ]
        else:
            reportes_filtrados = reportes_filtrados.filter(prioridad=filtro_prioridad)

    if usando_firestore:
        reportes_ordenados = sorted(
            reportes_filtrados,
            key=_fecha_sort_key,
            reverse=True
        )
        total_reportes = len(reportes_ordenados)
    else:
        reportes_ordenados = reportes_filtrados.order_by('-fecha_reporte')
        total_reportes = reportes_filtrados.count()

    context = {
        'reportes': reportes_ordenados,
        'total_reportes': total_reportes,
        'tipos_disponibles': Report.TIPOS_RESIDUO,
        'prioridades_disponibles': Report.PRIORIDADES,
        'filtro_q': filtro_q,
        'filtro_tipo': filtro_tipo,
        'filtro_prioridad': filtro_prioridad,
        'usando_firestore': usando_firestore,
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

    filtro_estado = request.GET.get('estado', '')
    filtro_tipo = request.GET.get('tipo', '')
    filtro_prioridad = request.GET.get('prioridad', '')
    filtro_cuadrilla = request.GET.get('cuadrilla', '')

    if filtro_estado:
        reportes_filtrados = [r for r in reportes_filtrados
                              if r.get('estado') == filtro_estado]

    if filtro_tipo:
        reportes_filtrados = [r for r in reportes_filtrados
                              if _matches_tipo_residuo(r, filtro_tipo)]

    if filtro_prioridad:
        reportes_filtrados = [r for r in reportes_filtrados
                              if r.get('prioridad') == filtro_prioridad]

    # El filtro de cuadrilla solo aplica cuando se trabaja con el modelo local
    if filtro_cuadrilla and hasattr(reportes_filtrados, 'filter'):
        reportes_filtrados = reportes_filtrados.filter(cuadrilla_asignada_id=filtro_cuadrilla)

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
                'estado': reporte.get('estado', 'recibido'),
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
        'filtro_estado': filtro_estado,
        'filtro_tipo': filtro_tipo,
        'filtro_prioridad': filtro_prioridad,
        'filtro_cuadrilla': filtro_cuadrilla,
    }
    return render(request, 'reports/gestion_reportes.html', context)


@login_required
def cuadrillas_view(request):
    cuadrillas = list(
        Cuadrilla.objects.all()
        .prefetch_related('miembros')
        .order_by('nombre')
    )
    usuarios_disponibles = User.objects.filter(is_staff=False, is_superuser=False)

    reportes_por_cuadrilla = {c.id: 0 for c in cuadrillas}
    usando_firestore = True

    try:
        cache_key = 'firestore_reports_all'
        reportes_firestore = cache.get(cache_key)

        if reportes_firestore is None:
            reportes_firestore = firestore_service.get_all_reports(limit=500)
            cache.set(cache_key, reportes_firestore, 300)

        miembros_por_id = {}
        for cuadrilla in cuadrillas:
            for miembro in cuadrilla.miembros.all():
                miembros_por_id[str(miembro.id)] = cuadrilla.id

        for reporte in reportes_firestore:
            if reporte.get('estado') not in ['asignado', 'en_proceso']:
                continue

            assigned_to = str(reporte.get('assigned_to') or '').strip()
            cuadrilla_id = miembros_por_id.get(assigned_to)
            if cuadrilla_id:
                reportes_por_cuadrilla[cuadrilla_id] += 1

    except Exception:
        usando_firestore = False
        cuadrillas_conteo = Cuadrilla.objects.annotate(
            activos=Count(
                'miembros__reportes_asignados',
                filter=Q(miembros__reportes_asignados__estado__in=['asignado', 'en_proceso'])
            )
        )
        for item in cuadrillas_conteo:
            reportes_por_cuadrilla[item.id] = item.activos

    for cuadrilla in cuadrillas:
        cuadrilla.reportes_activos_display = reportes_por_cuadrilla.get(cuadrilla.id, 0)

    context = {
        'cuadrillas': cuadrillas,
        'usuarios_disponibles': usuarios_disponibles,
        'usando_firestore': usando_firestore,
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
                'recibido': 'received',
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
