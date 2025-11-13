from django.core.management.base import BaseCommand
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
            
            estado = 'recibido' if dias < 2 else ('resuelto' if dias > 10 else random.choice(['asignado', 'en_proceso']))
            assigned = random.choice(encargados) if estado != 'recibido' else None
            
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
