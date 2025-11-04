from django.contrib import admin
from django.utils.html import format_html
from .models import User, Report, Cuadrilla, ActionLog


@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ['username', 'get_full_name', 'zona_asignada', 'telefono', 'is_active', 'fecha_registro']
    list_filter = ['zona_asignada', 'is_active', 'is_staff']
    search_fields = ['username', 'first_name', 'last_name', 'email']
    ordering = ['-fecha_registro']
    
    fieldsets = (
        ('Información Personal', {
            'fields': ('username', 'first_name', 'last_name', 'email', 'telefono')
        }),
        ('Asignación', {
            'fields': ('zona_asignada',)
        }),
        ('Permisos', {
            'fields': ('is_active', 'is_staff', 'is_superuser', 'groups', 'user_permissions')
        }),
        ('Fechas', {
            'fields': ('last_login', 'date_joined', 'fecha_registro')
        }),
    )


# @admin.register(Cuadrilla)
# class CuadrillaAdmin(admin.ModelAdmin):
#     list_display = ['nombre', 'zona_asignada', 'cantidad_miembros', 'capacidad_diaria', 'reportes_activos', 'activa']
#     list_filter = ['activa', 'zona_asignada']
#     search_fields = ['nombre']
#     filter_horizontal = ['miembros']
    
#     def cantidad_miembros(self, obj):
#         return obj.miembros.count()
#     cantidad_miembros.short_description = 'Miembros'
    
#     fieldsets = (
#         ('Información General', {
#             'fields': ('nombre', 'zona_asignada', 'activa', 'capacidad_diaria')
#         }),
#         ('Integrantes', {
#             'fields': ('miembros',)
#         }),
#     )


@admin.register(Report)
class ReportAdmin(admin.ModelAdmin):
    list_display = ['id', 'tipo_residuo', 'estado_badge', 'prioridad_badge', 'direccion', 
                    'cuadrilla_asignada', 'assigned_to', 'tiene_foto_validacion', 'fecha_reporte']
    list_filter = ['estado', 'prioridad', 'tipo_residuo', 'cuadrilla_asignada']
    search_fields = ['descripcion', 'direccion', 'reportado_por']
    date_hierarchy = 'fecha_reporte'
    ordering = ['-fecha_reporte']
    
    readonly_fields = ['fecha_reporte', 'fecha_asignacion', 'fecha_inicio', 
                       'fecha_resolucion', 'fecha_foto_validacion', 'preview_foto', 'preview_validacion']
    
    def estado_badge(self, obj):
        colors = {
            'pendiente': '#ffc107',
            'asignado': '#17a2b8',
            'en_proceso': '#007bff',
            'resuelto': '#28a745',
            'cancelado': '#6c757d',
        }
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 10px; font-weight: bold;">{}</span>',
            colors.get(obj.estado, '#666'),
            obj.get_estado_display()
        )
    estado_badge.short_description = 'Estado'
    
    def prioridad_badge(self, obj):
        colors = {
            'baja': '#28a745',
            'media': '#ffc107',
            'alta': '#fd7e14',
            'urgente': '#dc3545',
        }
        return format_html(
            '<span style="background-color: {}; color: white; padding: 3px 10px; '
            'border-radius: 10px; font-weight: bold;">{}</span>',
            colors.get(obj.prioridad, '#666'),
            obj.get_prioridad_display()
        )
    prioridad_badge.short_description = 'Prioridad'
    
    def tiene_foto_validacion(self, obj):
        if obj.foto_validacion:
            return format_html('<span style="color: green;">✓ Sí</span>')
        return format_html('<span style="color: red;">✗ No</span>')
    tiene_foto_validacion.short_description = 'Foto Validación'
    
    def preview_foto(self, obj):
        if obj.foto:
            return format_html('<img src="{}" width="200" />', obj.foto.url)
        return "Sin foto"
    preview_foto.short_description = 'Vista Previa Foto'
    
    def preview_validacion(self, obj):
        if obj.foto_validacion:
            return format_html(
                '<img src="{}" width="200" /><br><small>Fecha: {}</small>', 
                obj.foto_validacion.url,
                obj.fecha_foto_validacion.strftime('%d/%m/%Y %H:%M') if obj.fecha_foto_validacion else 'N/A'
            )
        return "Sin foto de validación"
    preview_validacion.short_description = 'Foto de Validación'
    
    fieldsets = (
        ('Información del Reporte', {
            'fields': ('tipo_residuo', 'descripcion', 'foto', 'preview_foto', 'foto_url')
        }),
        ('Ubicación', {
            'fields': ('latitud', 'longitud', 'direccion')
        }),
        ('Estado y Asignación', {
            'fields': ('estado', 'prioridad', 'assigned_to', 'cuadrilla_asignada')
        }),
        ('Validación (HU11)', {
            'fields': ('foto_validacion', 'preview_validacion', 'fecha_foto_validacion'),
            'classes': ('collapse',)
        }),
        ('Fechas', {
            'fields': ('fecha_reporte', 'fecha_asignacion', 'fecha_inicio', 'fecha_resolucion')
        }),
        ('Notas', {
            'fields': ('notas_resolucion',)
        }),
        ('Información Adicional', {
            'fields': ('reportado_por', 'version_app'),
            'classes': ('collapse',)
        }),
    )


@admin.register(ActionLog)
class ActionLogAdmin(admin.ModelAdmin):
    list_display = ['id', 'reporte', 'usuario', 'accion', 'fecha_accion']
    list_filter = ['accion', 'fecha_accion']
    search_fields = ['reporte__id', 'usuario__username', 'descripcion']
    date_hierarchy = 'fecha_accion'
    ordering = ['-fecha_accion']
    
    readonly_fields = ['reporte', 'usuario', 'accion', 'descripcion', 'fecha_accion']
    
    def has_add_permission(self, request):
        return False
    
    def has_change_permission(self, request, obj=None):
        return False