from django.urls import path
from . import views

urlpatterns = [
    path('', views.dashboard_view, name='dashboard'),
    path('login/', views.login_view, name='login'),
    path('logout/', views.logout_view, name='logout'),
    path('reportes-asignados/', views.reportes_asignados_view, name='reportes_asignados'),
    path('gestion-reportes/', views.gestion_reportes_view, name='gestion_reportes'),
    path('cuadrillas/', views.cuadrillas_view, name='cuadrillas'),
    path('crear-cuadrilla/', views.crear_cuadrilla_view, name='crear_cuadrilla'),
    path('asignar-reportes-masivo/', views.asignar_reportes_masivo_view, name='asignar_reportes_masivo'),
    path('cerrar-reporte/<int:reporte_id>/', views.cerrar_reporte_view, name='cerrar_reporte'),
    path('historial/', views.historial_view, name='historial'),
    # Nueva ruta para cambiar estado de reportes en Firestore
    path('api/cambiar-estado-reporte/', views.cambiar_estado_reporte_view, name='cambiar_estado_reporte'),
]
