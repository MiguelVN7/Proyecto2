#!/bin/bash

# EcoTrack - Analysis Configuration Switcher
# Switch between strict and relaxed static analysis configurations

echo "🔧 EcoTrack - Analysis Configuration Manager"
echo "============================================"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're in Flutter project
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ Not in a Flutter project directory"
    exit 1
fi

# Show current configuration
echo "📋 Available configurations:"
echo "   1. strict   - Comprehensive analysis (for code reviews)"
echo "   2. relaxed  - Essential rules only (for development)"
echo "   3. status   - Show current configuration"
echo ""

# Get user choice
if [ $# -eq 0 ]; then
    echo -n "Choose configuration (1-3): "
    read choice
else
    choice=$1
fi

case $choice in
    1|strict)
        print_status "Switching to STRICT analysis configuration..."
        if [ -f "analysis_options_strict.yaml" ]; then
            cp analysis_options_strict.yaml analysis_options.yaml
        else
            # Use the current comprehensive config as strict
            if [ ! -f "analysis_options_backup.yaml" ]; then
                cp analysis_options.yaml analysis_options_backup.yaml
            fi
        fi
        print_success "✅ Strict configuration activated"
        print_warning "This will show ALL quality suggestions (may be verbose)"
        ;;
    2|relaxed)
        print_status "Switching to RELAXED analysis configuration..."
        # Backup current config if it's the first time
        if [ ! -f "analysis_options_backup.yaml" ]; then
            cp analysis_options.yaml analysis_options_backup.yaml
        fi
        cp analysis_options_relaxed.yaml analysis_options.yaml
        print_success "✅ Relaxed configuration activated"
        print_warning "Only critical errors and naming conventions will be enforced"
        ;;
    3|status)
        print_status "Current analysis configuration:"
        if grep -q "Balanced Static Code Analysis" analysis_options.yaml 2>/dev/null; then
            echo "📊 RELAXED - Essential rules only"
        else
            echo "📊 STRICT - Comprehensive analysis"
        fi
        ;;
    *)
        echo "❌ Invalid choice. Use: strict, relaxed, or status"
        exit 1
        ;;
esac

echo ""
print_status "💡 Tips:"
echo "   • Use 'relaxed' during development to reduce noise"
echo "   • Use 'strict' before committing for thorough review"
echo "   • Run './scripts/analyze.sh' to test current configuration"
