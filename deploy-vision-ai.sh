#!/bin/bash

# 🚀 EcoTrack AI Deployment Script
# Este script configura y despliega la clasificación con Google Vision AI

set -e  # Exit on error

echo "🎯 EcoTrack - Google Vision AI Deployment"
echo "=========================================="
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running from correct directory
if [ ! -f "firebase.json" ]; then
    echo -e "${RED}❌ Error: Debes ejecutar este script desde la raíz del proyecto${NC}"
    echo "   cd /ruta/a/Proyecto\ 2"
    exit 1
fi

echo -e "${YELLOW}📋 Paso 1: Verificando prerequisitos...${NC}"

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI no está instalado${NC}"
    echo "   Instala con: npm install -g firebase-tools"
    exit 1
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Google Cloud CLI no está instalado${NC}"
    echo "   Descarga de: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisitos verificados${NC}"
echo ""

# Login to Firebase (if needed)
echo -e "${YELLOW}📋 Paso 2: Verificando autenticación Firebase...${NC}"
if ! firebase projects:list &> /dev/null; then
    echo "🔐 Necesitas autenticarte con Firebase..."
    firebase login
fi
echo -e "${GREEN}✅ Autenticado en Firebase${NC}"
echo ""

# Set Firebase project
echo -e "${YELLOW}📋 Paso 3: Seleccionando proyecto Firebase...${NC}"
firebase use ecotrack-app-23a64
echo -e "${GREEN}✅ Proyecto seleccionado: ecotrack-app-23a64${NC}"
echo ""

# Enable Vision API
echo -e "${YELLOW}📋 Paso 4: Habilitando Google Vision API...${NC}"
if gcloud services enable vision.googleapis.com --project=ecotrack-app-23a64 2>/dev/null; then
    echo -e "${GREEN}✅ Vision API habilitada${NC}"
else
    echo -e "${YELLOW}⚠️  Vision API ya estaba habilitada o necesitas permisos${NC}"
fi
echo ""

# Install dependencies
echo -e "${YELLOW}📋 Paso 5: Instalando dependencias...${NC}"
cd functions
if [ -f "package.json" ]; then
    npm install
    echo -e "${GREEN}✅ Dependencias instaladas${NC}"
else
    echo -e "${RED}❌ No se encontró package.json${NC}"
    exit 1
fi
cd ..
echo ""

# Ask user if they want to test locally first
echo -e "${YELLOW}🧪 ¿Quieres probar localmente primero? (y/n)${NC}"
read -r test_local

if [ "$test_local" = "y" ] || [ "$test_local" = "Y" ]; then
    echo ""
    echo -e "${YELLOW}🚀 Iniciando emuladores de Firebase...${NC}"
    echo "   Presiona Ctrl+C cuando termines de probar"
    echo ""
    cd functions
    npm run serve
    cd ..
fi

echo ""
echo -e "${YELLOW}📋 Paso 6: Desplegando Cloud Functions...${NC}"
echo "   Esto puede tomar 2-3 minutos..."
echo ""

firebase deploy --only functions

echo ""
echo -e "${GREEN}✅ ¡Deployment completado exitosamente!${NC}"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}🎉 Google Vision AI está activo${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📱 Próximos pasos:"
echo "   1. Abre la app EcoTrack"
echo "   2. Toma una foto de un residuo"
echo "   3. Espera 2-3 segundos"
echo "   4. ¡El badge de IA debería aparecer!"
echo ""
echo "📊 Monitorear:"
echo "   • Ver logs: firebase functions:log"
echo "   • Console: https://console.firebase.google.com/project/ecotrack-app-23a64/functions"
echo "   • Vision API: https://console.cloud.google.com/apis/api/vision.googleapis.com/metrics"
echo ""
echo "🐛 Si algo falla:"
echo "   • Revisa los logs: firebase functions:log --only classifyWaste"
echo "   • Verifica que Vision API esté habilitada"
echo "   • Asegúrate de que la imagen esté en carpeta 'reports/'"
echo ""
echo -e "${GREEN}✨ ¡Listo para clasificar residuos con IA!${NC}"
echo ""
