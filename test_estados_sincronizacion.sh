#!/bin/bash

# 🧪 Script de Validación: Sincronización de Estados
# Este script ayuda a verificar que los filtros funcionen correctamente

echo "🧪 Validación de Sincronización de Estados"
echo "=========================================="
echo ""

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}📋 Pasos de Validación:${NC}"
echo ""

echo "1️⃣  Limpiar y recompilar la app Flutter"
echo -e "${YELLOW}   Ejecutar:${NC}"
echo "   cd frontend"
echo "   flutter clean"
echo "   flutter pub get"
echo "   flutter run"
echo ""

echo "2️⃣  Verificar valores en Firestore"
echo -e "${YELLOW}   Ir a Firebase Console:${NC}"
echo "   https://console.firebase.google.com"
echo "   → Firestore Database → Colección 'reports'"
echo ""
echo -e "${YELLOW}   ✅ Verificar que 'estado' tenga valores:${NC}"
echo "      - pending"
echo "      - received"
echo "      - assigned"
echo "      - in_progress"
echo "      - completed"
echo "      - cancelled"
echo ""
echo -e "${YELLOW}   ❌ NO debe tener:${NC}"
echo "      - Pendiente, Recibido, Asignado, etc."
echo ""

echo "3️⃣  Probar desde la App Móvil"
echo -e "${YELLOW}   a) Crear nuevo reporte${NC}"
echo "      → Debe guardar 'estado: pending' en Firestore"
echo ""
echo -e "${YELLOW}   b) Filtrar por cada estado${NC}"
echo "      → Todos: Debe mostrar todos los reportes"
echo "      → Pendiente: Solo reportes con estado=pending"
echo "      → Recibido: Solo reportes con estado=received"
echo "      → Asignado: Solo reportes con estado=assigned"
echo "      → En Proceso: Solo reportes con estado=in_progress"
echo "      → Resuelto: Solo reportes con estado=completed"
echo "      → Cancelado: Solo reportes con estado=cancelled"
echo ""

echo "4️⃣  Probar desde la Página Web"
echo -e "${YELLOW}   a) Iniciar página web Django${NC}"
echo "      cd PaginaWeb_P2"
echo "      python manage.py runserver"
echo ""
echo -e "${YELLOW}   b) Cambiar estado de un reporte${NC}"
echo "      → Login en http://localhost:8000"
echo "      → Ir a Gestión de Reportes"
echo "      → Cambiar estado de un reporte"
echo ""
echo -e "${YELLOW}   c) Verificar en la App${NC}"
echo "      → El cambio debe reflejarse inmediatamente"
echo "      → El filtro debe funcionar correctamente"
echo ""

echo "5️⃣  Pruebas de Sincronización en Tiempo Real"
echo -e "${YELLOW}   Con ambas interfaces abiertas:${NC}"
echo ""
echo "   Test 1: Web → App"
echo "   ─────────────────"
echo "   1. Página Web: Cambiar estado a 'En Proceso'"
echo "   2. App Móvil: Verificar que aparezca en filtro 'En Proceso'"
echo "   3. App Móvil: Verificar que desaparezca de otros filtros"
echo ""
echo "   Test 2: App → Web"
echo "   ─────────────────"
echo "   1. App Móvil: Cambiar estado a 'Resuelto'"
echo "   2. Página Web: Verificar que aparezca en 'Resuelto'"
echo "   3. Página Web: Verificar estadísticas actualizadas"
echo ""

echo "6️⃣  Verificación Final"
echo -e "${YELLOW}   Checklist:${NC}"
echo "   □ App guarda estados normalizados (pending, received, etc.)"
echo "   □ App lee estados normalizados correctamente"
echo "   □ Filtros muestran reportes correctos"
echo "   □ Cambios desde web se reflejan en app"
echo "   □ Cambios desde app se reflejan en web"
echo "   □ Estadísticas se calculan correctamente"
echo ""

echo -e "${GREEN}✅ Si todos los checks pasan, la sincronización está correcta${NC}"
echo ""

# Opcional: Verificar que Flutter esté instalado
if command -v flutter &> /dev/null; then
    echo -e "${GREEN}✅ Flutter instalado: $(flutter --version | head -n 1)${NC}"
else
    echo -e "${YELLOW}⚠️  Flutter no encontrado en PATH${NC}"
fi

echo ""
echo "📚 Documentación completa en: ESTADOS_SINCRONIZACION_FIX.md"
echo ""
