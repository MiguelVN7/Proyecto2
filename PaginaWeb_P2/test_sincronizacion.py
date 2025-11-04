#!/usr/bin/env python
"""
Script de prueba para verificar la sincronización en tiempo real
entre Django Web y la App Móvil a través de Firestore

Uso:
    python test_sincronizacion.py
"""

import os
import sys
import django

# Configurar Django
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'ecotrack_admin.settings')
django.setup()

from reports.firestore_service import firestore_service
import time


def print_header(text):
    """Imprime un encabezado bonito"""
    print("\n" + "=" * 60)
    print(f"  {text}")
    print("=" * 60 + "\n")


def test_connection():
    """Prueba 1: Verificar conexión a Firestore"""
    print_header("PRUEBA 1: Conexión a Firestore")

    try:
        stats = firestore_service.get_stats()
        print(f"✅ Conexión exitosa a Firestore")
        print(f"   Total de reportes: {stats.get('total_reports', 0)}")
        print(f"   Por estado: {stats.get('by_status', {})}")
        return True
    except Exception as e:
        print(f"❌ Error de conexión: {e}")
        return False


def test_get_reports():
    """Prueba 2: Obtener reportes"""
    print_header("PRUEBA 2: Obtener Reportes")

    try:
        reports = firestore_service.get_all_reports(limit=5)
        print(f"✅ Se obtuvieron {len(reports)} reportes")

        if reports:
            print("\n📋 Primeros reportes:")
            for i, report in enumerate(reports[:3], 1):
                print(f"\n   {i}. ID: {report['id']}")
                print(f"      Estado: {report.get('estado', 'N/A')}")
                print(f"      Tipo: {report.get('tipo_residuo', 'N/A')}")
                print(f"      Dirección: {report.get('direccion', 'N/A')[:40]}...")

        return len(reports) > 0
    except Exception as e:
        print(f"❌ Error obteniendo reportes: {e}")
        return False


def test_update_status():
    """Prueba 3: Actualizar estado de un reporte"""
    print_header("PRUEBA 3: Actualizar Estado (Sincronización)")

    try:
        # Obtener primer reporte
        reports = firestore_service.get_all_reports(limit=1)

        if not reports:
            print("⚠️ No hay reportes disponibles para probar")
            return False

        report = reports[0]
        report_id = report['id']
        current_status = report.get('estado', 'pendiente')

        print(f"📝 Reporte seleccionado: {report_id}")
        print(f"   Estado actual: {current_status}")

        # Cambiar estado temporalmente
        test_status = 'in_progress' if current_status != 'in_progress' else 'assigned'

        print(f"\n🔄 Cambiando estado a: {test_status}")
        print("   ⏱️  Ahora verifica tu app móvil...")
        print("   👀 El estado debería cambiar en 1-2 segundos")

        # Actualizar
        success = firestore_service.update_report_status(report_id, test_status)

        if success:
            print(f"\n✅ Estado actualizado exitosamente!")
            print(f"   Firestore ha notificado a todos los clientes")
            print(f"   La app móvil debería mostrar el nuevo estado")

            # Esperar un poco
            print(f"\n⏳ Esperando 5 segundos...")
            time.sleep(5)

            # Revertir al estado original
            print(f"\n🔄 Revirtiendo al estado original: {current_status}")
            firestore_service.update_report_status(report_id, current_status)
            print(f"✅ Estado restaurado")

            return True
        else:
            print(f"❌ No se pudo actualizar el estado")
            return False

    except Exception as e:
        print(f"❌ Error en prueba de actualización: {e}")
        import traceback
        traceback.print_exc()
        return False


def test_assign_report():
    """Prueba 4: Asignar reporte a usuario"""
    print_header("PRUEBA 4: Asignar Reporte (Sincronización)")

    try:
        reports = firestore_service.get_all_reports(limit=1)

        if not reports:
            print("⚠️ No hay reportes disponibles")
            return False

        report = reports[0]
        report_id = report['id']

        print(f"📝 Reporte: {report_id}")
        print(f"\n🔄 Asignando a 'Test User'")

        success = firestore_service.assign_report_to_user(
            report_id,
            "test_user_123",
            "Usuario de Prueba"
        )

        if success:
            print(f"✅ Reporte asignado exitosamente!")
            print(f"   La app móvil debería mostrar 'Usuario de Prueba'")
            return True
        else:
            print(f"❌ No se pudo asignar el reporte")
            return False

    except Exception as e:
        print(f"❌ Error asignando reporte: {e}")
        return False


def main():
    """Ejecutar todas las pruebas"""
    print("\n")
    print("🧪 " + "=" * 58)
    print("   PRUEBAS DE SINCRONIZACIÓN EN TIEMPO REAL")
    print("   Django Web ↔ Firestore ↔ App Móvil")
    print("=" * 60)

    results = {
        'Conexión a Firestore': test_connection(),
        'Obtener Reportes': test_get_reports(),
        'Actualizar Estado': test_update_status(),
        'Asignar Reporte': test_assign_report(),
    }

    # Resumen
    print_header("RESUMEN DE PRUEBAS")

    passed = sum(1 for v in results.values() if v)
    total = len(results)

    for test_name, result in results.items():
        status = "✅ PASS" if result else "❌ FAIL"
        print(f"{status}  {test_name}")

    print(f"\n{'=' * 60}")
    print(f"  Resultado: {passed}/{total} pruebas exitosas")

    if passed == total:
        print(f"  🎉 ¡TODAS LAS PRUEBAS PASARON!")
        print(f"\n  📱 Verifica tu app móvil - debe mostrar los cambios")
    else:
        print(f"  ⚠️  Algunas pruebas fallaron")

    print("=" * 60 + "\n")


if __name__ == '__main__':
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n⚠️  Pruebas interrumpidas por el usuario\n")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Error fatal: {e}\n")
        import traceback
        traceback.print_exc()
        sys.exit(1)
