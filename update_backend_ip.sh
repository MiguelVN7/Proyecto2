#!/bin/bash

# Script to automatically update backend IP in Flutter config
# Run this script whenever you change WiFi networks

# Get current IP address (macOS)
CURRENT_IP=$(ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n 1)

if [ -z "$CURRENT_IP" ]; then
    echo "❌ Could not detect IP address. Are you connected to WiFi?"
    exit 1
fi

echo "📡 Detected IP: $CURRENT_IP"

# Path to Flutter config file
CONFIG_FILE="frontend/lib/config/api_config.dart"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "❌ Config file not found: $CONFIG_FILE"
    exit 1
fi

# Update IP in config file
sed -i '' "s|return 'http://[0-9.]*:3000';|return 'http://$CURRENT_IP:3000';|g" "$CONFIG_FILE"

echo "✅ Updated backend IP to: $CURRENT_IP"
echo "🔄 Please hot restart your Flutter app"
echo ""
echo "Backend URLs:"
echo "  - Mobile: http://$CURRENT_IP:3000"
echo "  - Health: http://$CURRENT_IP:3000/health"
