#!/bin/bash

echo "🚀 Iniciando servidor EcoTrack con SQLite..."

# Detener procesos anteriores
pkill -f server.js 2>/dev/null || true
sleep 1

# Iniciar servidor en background
cd /Users/miguelvillegas/Proyecto\ 2/eco_track_backend
npm run dev &
SERVER_PID=$!

# Esperar a que inicie
sleep 3

echo "📊 Probando health check..."
curl -s http://localhost:3000/health | jq . || curl -s http://localhost:3000/health

echo -e "\n\n📝 Enviando reporte de prueba..."
curl -s -X POST http://localhost:3000/api/reports \
  -H 'Content-Type: application/json' \
  -d '{
    "photo": "data:image/png;base64,iVBORw0KGgo=",
    "latitude": 4.61,
    "longitude": -74.07,
    "accuracy": 4.2,
    "classification": "Botella de plástico PET"
  }' | jq . || echo "Sin jq instalado"

echo -e "\n\n📈 Verificando estadísticas..."
curl -s http://localhost:3000/api/stats | jq . || curl -s http://localhost:3000/api/stats

echo -e "\n\n📋 Listando reportes..."
curl -s http://localhost:3000/api/reports | jq . || curl -s http://localhost:3000/api/reports

echo -e "\n\n✅ Pruebas completadas. Servidor corriendo en PID: $SERVER_PID"
echo "Para detenerlo: kill $SERVER_PID"
