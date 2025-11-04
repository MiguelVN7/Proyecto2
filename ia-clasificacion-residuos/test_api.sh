#!/bin/bash
# Test script for AI microservice

echo "🧪 Testing EcoTrack AI Waste Classifier Microservice"
echo "=================================================="
echo ""

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if server is running
echo "1️⃣  Checking if server is running..."
if curl -s http://localhost:8080/health > /dev/null; then
    echo -e "${GREEN}✅ Server is running${NC}"
else
    echo -e "${RED}❌ Server is NOT running${NC}"
    echo -e "${YELLOW}💡 Start server with: uvicorn app.main:app --reload --port 8080${NC}"
    exit 1
fi

echo ""

# Test health endpoint
echo "2️⃣  Testing health endpoint..."
HEALTH=$(curl -s http://localhost:8080/health)
echo "Response:"
echo "$HEALTH" | python3 -m json.tool
echo ""

# Test classification endpoint (with example image URL)
echo "3️⃣  Testing classification endpoint..."
echo "Using test image URL..."

RESPONSE=$(curl -s -X POST "http://localhost:8080/classify" \
  -H "Content-Type: application/json" \
  -d '{
    "image_url": "https://images.unsplash.com/photo-1604187351574-c75ca79f5807?w=400",
    "report_id": "ECO-TEST-12345",
    "user_id": "test_user_001"
  }')

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Classification successful${NC}"
    echo "Response:"
    echo "$RESPONSE" | python3 -m json.tool
else
    echo -e "${RED}❌ Classification failed${NC}"
fi

echo ""
echo "=================================================="
echo "🎉 Testing complete!"
echo ""
echo "📚 View API docs at: http://localhost:8080/docs"
