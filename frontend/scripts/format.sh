#!/bin/bash

# EcoTrack - Quick Code Formatting Script
# Automatically formats and fixes common code style issues

echo "🎨 EcoTrack - Auto-formatting Code"
echo "=================================="

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Check if we're in Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not in a Flutter project directory"
    exit 1
fi

# Step 1: Format Dart code
print_status "Formatting Dart code..."
dart format lib/ --line-length=80
print_success "Code formatted with 80-character line limit"

# Step 2: Sort imports
print_status "Organizing imports..."
flutter packages pub run import_sorter:main
print_success "Imports organized by type and alphabetically"

# Step 3: Basic analysis
print_status "Running basic code analysis..."
flutter analyze --no-fatal-infos
print_success "Code analysis completed"

print_success "🎉 Auto-formatting completed!"
echo "💡 Run './scripts/analyze.sh' for comprehensive analysis"
