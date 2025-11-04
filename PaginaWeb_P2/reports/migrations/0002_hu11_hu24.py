# Generated migration file
from django.conf import settings
from django.db import migrations, models
import django.db.models.deletion


class Migration(migrations.Migration):

    dependencies = [
        ('reports', '0001_initial'),
    ]

    operations = [
        # Crear modelo Cuadrilla (HU24)
        migrations.CreateModel(
            name='Cuadrilla',
            fields=[
                ('id', models.BigAutoField(auto_created=True, primary_key=True, serialize=False, verbose_name='ID')),
                ('nombre', models.CharField(max_length=100, unique=True)),
                ('zona_asignada', models.CharField(blank=True, choices=[('norte', 'Norte'), ('sur', 'Sur'), ('centro', 'Centro'), ('oriente', 'Oriente'), ('occidente', 'Occidente')], max_length=20)),
                ('activa', models.BooleanField(default=True)),
                ('capacidad_diaria', models.IntegerField(default=10, help_text='Reportes que puede atender por día')),
                ('fecha_creacion', models.DateTimeField(auto_now_add=True)),
                ('miembros', models.ManyToManyField(blank=True, related_name='cuadrillas', to=settings.AUTH_USER_MODEL)),
            ],
            options={
                'verbose_name': 'Cuadrilla',
                'verbose_name_plural': 'Cuadrillas',
                'ordering': ['nombre'],
            },
        ),
        # Agregar campo cuadrilla_asignada al modelo Report (HU24)
        migrations.AddField(
            model_name='report',
            name='cuadrilla_asignada',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.SET_NULL, related_name='reportes_asignados', to='reports.cuadrilla'),
        ),
        # Agregar campos de foto de validación (HU11)
        migrations.AddField(
            model_name='report',
            name='foto_validacion',
            field=models.ImageField(blank=True, help_text='Foto del lugar limpio después de la recolección', null=True, upload_to='validaciones/%Y/%m/%d/'),
        ),
        migrations.AddField(
            model_name='report',
            name='fecha_foto_validacion',
            field=models.DateTimeField(blank=True, null=True),
        ),
        # Actualizar choices de ActionLog para incluir nuevas acciones
        migrations.AlterField(
            model_name='actionlog',
            name='accion',
            field=models.CharField(choices=[
                ('creado', 'Reporte Creado'), 
                ('asignado', 'Asignado a Encargado'), 
                ('asignado_cuadrilla', 'Asignado a Cuadrilla'), 
                ('iniciado', 'Trabajo Iniciado'), 
                ('foto_validacion', 'Foto de Validación Subida'), 
                ('resuelto', 'Marcado como Resuelto'), 
                ('asignacion_masiva', 'Asignación Masiva')
            ], max_length=25),
        ),
    ]