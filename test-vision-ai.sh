#!/bin/bash

# 🧪 Script de Testing para Google Vision AI
# Prueba la clasificación de forma rápida

echo "🧪 Testing Google Vision AI Classification"
echo "=========================================="
echo ""

# Check if function URL is provided
FUNCTION_URL="https://us-central1-ecotrack-app-23a64.cloudfunctions.net/classifyWasteManual"

# Test images (usar URLs públicas de ejemplo)
TEST_IMAGES=(
    "https://images.unsplash.com/photo-1602143407151-7111542de6e8?w=400" # Plastic bottle
    "https://images.unsplash.com/photo-1587334207976-c8f755cb4101?w=400" # Banana
    "https://images.unsplash.com/photo-1604335399105-a0c585fd81a1?w=400" # Paper/cardboard
)

TEST_NAMES=(
    "Botella de plástico"
    "Banana"
    "Cartón"
)

EXPECTED=(
    "Reciclable"
    "Orgánico"
    "Reciclable"
)

echo "📋 Ejecutando ${#TEST_IMAGES[@]} tests..."
echo ""

# Contador de tests exitosos
SUCCESS=0
TOTAL=${#TEST_IMAGES[@]}

for i in "${!TEST_IMAGES[@]}"; do
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Test $((i+1))/${TOTAL}: ${TEST_NAMES[$i]}"
    echo "Expected: ${EXPECTED[$i]}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Download image temporarily (Vision API needs GCS URL)
    # For real testing, you'd need to upload to your Storage first
    echo "⏭️  Skipping ${TEST_NAMES[$i]} (requiere imagen en Firebase Storage)"
    echo ""
    
    # Example for real testing with GCS URL:
    # RESULT=$(curl -s -X POST "$FUNCTION_URL" \
    #     -H "Content-Type: application/json" \
    #     -d "{\"imageUrl\": \"gs://your-bucket/test-image.jpg\"}")
    # 
    # CLASSIFICATION=$(echo "$RESULT" | jq -r '.classification')
    # CONFIDENCE=$(echo "$RESULT" | jq -r '.confidence')
    # 
    # if [ "$CLASSIFICATION" == "${EXPECTED[$i]}" ]; then
    #     echo "✅ PASS - Clasificado correctamente: $CLASSIFICATION ($CONFIDENCE)"
    #     SUCCESS=$((SUCCESS+1))
    # else
    #     echo "❌ FAIL - Esperado: ${EXPECTED[$i]}, Obtenido: $CLASSIFICATION"
    # fi
done

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Resultados: $SUCCESS/$TOTAL tests pasaron"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "💡 Para testing completo:"
echo "   1. Sube imágenes de prueba a Firebase Storage"
echo "   2. Modifica TEST_IMAGES con las URLs de GCS (gs://...)"
echo "   3. Vuelve a ejecutar este script"
echo ""
echo "📱 Mejor opción: Testing en la app real"
echo "   - Toma fotos desde el celular"
echo "   - Verifica clasificación en tiempo real"
echo "   - Revisa logs: firebase functions:log"
echo ""
