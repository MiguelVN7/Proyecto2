#!/bin/bash

# Script para inicializar la base de datos de desarrollo
# Uso: ./setup_database.sh

echo "🗄️  Configurando base de datos de desarrollo..."

# Crear directorio de uploads si no existe
mkdir -p uploads

# Verificar si SQLite está instalado
if ! command -v sqlite3 &> /dev/null; then
    echo "❌ SQLite3 no está instalado. Instálalo con:"
    echo "   macOS: brew install sqlite"
    echo "   Ubuntu: sudo apt-get install sqlite3"
    exit 1
fi

# Eliminar BD existente si existe (para empezar limpio)
if [ -f "ecotrack.db" ]; then
    echo "🗑️  Eliminando base de datos existente..."
    rm ecotrack.db
fi

# Crear nueva BD con datos de ejemplo
echo "📝 Creando base de datos con datos de ejemplo..."
sqlite3 ecotrack.db < init_database.sql

if [ $? -eq 0 ]; then
    echo "✅ Base de datos creada exitosamente"
    echo "📊 Estadísticas:"
    sqlite3 ecotrack.db "SELECT COUNT(*) as 'Total reportes:' FROM reports;"
    echo ""
    echo "🚀 Para iniciar el servidor:"
    echo "   npm start"
    echo ""
    echo "🔍 Para ver los datos:"
    echo "   sqlite3 ecotrack.db"
    echo "   .tables"
    echo "   SELECT * FROM reports;"
else
    echo "❌ Error al crear la base de datos"
    exit 1
fi
