#!/bin/bash

# EcoTrack - Comprehensive Code Analysis Script
# This script runs all static analysis tools configured for the project

echo "🔍 EcoTrack - Running Comprehensive Code Analysis"
echo "=================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if we're in Flutter project
if [ ! -f "pubspec.yaml" ]; then
    print_error "Not in a Flutter project directory. Please run from project root."
    exit 1
fi

# Step 1: Get dependencies
print_status "Step 1: Getting Flutter dependencies..."
flutter pub get
if [ $? -eq 0 ]; then
    print_success "Dependencies retrieved successfully"
else
    print_error "Failed to get dependencies"
    exit 1
fi

# Step 2: Format code
print_status "Step 2: Formatting Dart code..."
dart format lib/ --set-exit-if-changed
if [ $? -eq 0 ]; then
    print_success "Code formatting completed"
else
    print_warning "Code formatting found issues (auto-fixed)"
fi

# Step 3: Sort imports
print_status "Step 3: Organizing import statements..."
flutter packages pub run import_sorter:main
if [ $? -eq 0 ]; then
    print_success "Import organization completed"
else
    print_warning "Import sorter encountered issues"
fi

# Step 4: Run Flutter analyzer
print_status "Step 4: Running Flutter analyzer..."
flutter analyze
if [ $? -eq 0 ]; then
    print_success "Flutter analysis passed"
else
    print_error "Flutter analysis found issues"
    # Don't exit, continue with other checks
fi

# Step 5: Run Dart Code Metrics
print_status "Step 5: Running advanced code metrics..."
flutter packages pub run dart_code_metrics:metrics analyze lib --reporter=console-verbose
if [ $? -eq 0 ]; then
    print_success "Code metrics analysis completed"
else
    print_warning "Code metrics found potential improvements"
fi

# Step 6: Check for anti-patterns  
print_status "Step 6: Checking for anti-patterns..."
flutter packages pub run dart_code_metrics:metrics check-anti-patterns lib
if [ $? -eq 0 ]; then
    print_success "Anti-pattern check passed"
else
    print_warning "Anti-patterns detected"
fi

# Step 7: Generate metrics report
print_status "Step 7: Generating comprehensive metrics report..."
mkdir -p analysis_reports
flutter packages pub run dart_code_metrics:metrics analyze lib --reporter=html --output-directory=analysis_reports
if [ $? -eq 0 ]; then
    print_success "Metrics report generated in analysis_reports/"
else
    print_warning "Failed to generate metrics report"
fi

# Step 8: Check test coverage (if tests exist)
if [ -d "test" ] && [ "$(ls -A test)" ]; then
    print_status "Step 8: Running tests with coverage..."
    flutter test --coverage
    if [ $? -eq 0 ]; then
        print_success "Tests passed with coverage report"
    else
        print_warning "Some tests failed"
    fi
else
    print_warning "No tests found - consider adding unit tests"
fi

echo ""
print_success "🎉 Code analysis completed!"
echo "📊 Check analysis_reports/ for detailed metrics"
echo "🔧 Run 'flutter run' to test the application"
