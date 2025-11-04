#!/bin/bash

# Script de prueba para verificar la integración de IA
# Este script simula el envío de un reporte con una imagen de prueba

echo "🧪 Testing AI Classification Integration"
echo "========================================"
echo ""

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if backend is running
echo "📡 Checking if backend is running..."
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ Backend is running${NC}"
else
    echo -e "${RED}❌ Backend is not running. Please start it first with: node server.js${NC}"
    exit 1
fi

echo ""
echo "📸 Looking for a test image..."

# Find the most recent image in the images directory
IMAGE_FILE=$(ls -t /Users/miguelvillegas/Proyecto\ 2/backend/images/*.{jpg,jpeg,png} 2>/dev/null | head -n 1)

if [ -z "$IMAGE_FILE" ]; then
    echo -e "${RED}❌ No test images found in backend/images/${NC}"
    echo "Please take a photo using the app first, then run this test."
    exit 1
fi

echo -e "${GREEN}✅ Found test image: $(basename "$IMAGE_FILE")${NC}"
echo ""

# Convert image to base64
echo "🔄 Converting image to base64..."
IMAGE_BASE64=$(base64 -i "$IMAGE_FILE")

# Prepare JSON payload
echo "📤 Sending test report to backend..."
RESPONSE=$(curl -s -X POST http://localhost:3000/api/reports \
  -H "Content-Type: application/json" \
  -d '{
    "photo": "data:image/jpeg;base64,'"$IMAGE_BASE64"'",
    "latitude": -12.0464,
    "longitude": -77.0428,
    "accuracy": 10.5,
    "classification": "Test Manual",
    "timestamp": "'$(date -u +"%Y-%m-%dT%H:%M:%SZ")'",
    "device_info": "Test Script"
  }')

echo ""
echo "📊 Response from backend:"
echo "========================"
echo "$RESPONSE" | jq '.' 2>/dev/null || echo "$RESPONSE"
echo ""

# Check if AI classification was successful
if echo "$RESPONSE" | grep -q '"success": true'; then
    REPORT_CODE=$(echo "$RESPONSE" | jq -r '.report_code' 2>/dev/null)
    echo -e "${GREEN}✅ Report created successfully: $REPORT_CODE${NC}"
    echo ""
    echo "🤖 Check the backend logs above for AI classification results"
    echo "   Look for lines like:"
    echo "   - 🤖 Calling AI classification for image"
    echo "   - 🎯 AI Classification: [Category] ([Confidence]% confidence)"
    echo ""
    echo "📱 You can now check the app to see the AI badge on this report!"
else
    echo -e "${RED}❌ Error creating report${NC}"
fi

echo ""
echo "🎉 Test completed!"
