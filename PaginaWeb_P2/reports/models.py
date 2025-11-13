from django.db import models
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


class Cuadrilla(models.Model):
    """Modelo para gestionar cuadrillas de recolección"""
    nombre = models.CharField(max_length=100, unique=True)
    miembros = models.ManyToManyField(User, related_name='cuadrillas', blank=True)
    zona_asignada = models.CharField(max_length=20, choices=User.ZONAS, blank=True)
    activa = models.BooleanField(default=True)
    capacidad_diaria = models.IntegerField(default=10, help_text='Reportes que puede atender por día')
    fecha_creacion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        verbose_name = 'Cuadrilla'
        verbose_name_plural = 'Cuadrillas'
        ordering = ['nombre']
    
    def __str__(self):
        return f"{self.nombre} ({self.miembros.count()} miembros)"
    
    def reportes_activos(self):
        """Cuenta reportes asignados que no están resueltos"""
        return self.reportes_asignados.exclude(estado='resuelto').count()


class Report(models.Model):
    TIPOS_RESIDUO = [
        ('reciclable', 'Reciclable'),
        ('no_reciclable', 'No Reciclable'),
        ('organico', 'Orgánico'),
    ]
    ESTADOS = [
        ('recibido', 'Recibido'), ('asignado', 'Asignado'),
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
    estado = models.CharField(max_length=20, choices=ESTADOS, default='recibido')
    prioridad = models.CharField(max_length=20, choices=PRIORIDADES, default='media')
    assigned_to = models.ForeignKey('User', on_delete=models.SET_NULL, null=True, 
                                    blank=True, related_name='reportes_asignados')
    
    # HU24: Asignación a cuadrilla
    cuadrilla_asignada = models.ForeignKey('Cuadrilla', on_delete=models.SET_NULL, 
                                           null=True, blank=True, 
                                           related_name='reportes_asignados')
    
    fecha_reporte = models.DateTimeField(default=timezone.now)
    fecha_asignacion = models.DateTimeField(null=True, blank=True)
    fecha_inicio = models.DateTimeField(null=True, blank=True)
    fecha_resolucion = models.DateTimeField(null=True, blank=True)
    notas_resolucion = models.TextField(blank=True)
    reportado_por = models.CharField(max_length=100, blank=True)
    version_app = models.CharField(max_length=20, blank=True)
    
    # HU11: Foto de validación (obligatoria al cerrar)
    foto_validacion = models.ImageField(
        upload_to='validaciones/%Y/%m/%d/', 
        null=True, 
        blank=True,
        help_text='Foto del lugar limpio después de la recolección'
    )
    fecha_foto_validacion = models.DateTimeField(null=True, blank=True)
    
    class Meta:
        ordering = ['-fecha_reporte']
    
    def __str__(self):
        return f"Reporte #{self.id} - {self.get_tipo_residuo_display()}"
    
    def puede_cerrarse(self):
        """Verifica si el reporte puede ser cerrado (HU11)"""
        return self.estado in ['en_proceso', 'asignado'] and self.foto_validacion
    
    def cerrar_reporte(self):
        """Cierra el reporte si cumple requisitos"""
        if self.puede_cerrarse():
            self.estado = 'resuelto'
            self.fecha_resolucion = timezone.now()
            self.save()
            return True
        return False


class ActionLog(models.Model):
    ACCIONES = [
        ('creado', 'Reporte Creado'), 
        ('asignado', 'Asignado a Encargado'),
        ('asignado_cuadrilla', 'Asignado a Cuadrilla'),
        ('iniciado', 'Trabajo Iniciado'), 
        ('foto_validacion', 'Foto de Validación Subida'),
        ('resuelto', 'Marcado como Resuelto'),
        ('asignacion_masiva', 'Asignación Masiva'),
    ]
    reporte = models.ForeignKey(Report, on_delete=models.CASCADE, related_name='historial')
    usuario = models.ForeignKey(User, on_delete=models.SET_NULL, null=True)
    accion = models.CharField(max_length=25, choices=ACCIONES)
    descripcion = models.TextField(blank=True)
    fecha_accion = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        ordering = ['-fecha_accion']
    
    def __str__(self):
        return f"{self.get_accion_display()} - Reporte #{self.reporte.id}"