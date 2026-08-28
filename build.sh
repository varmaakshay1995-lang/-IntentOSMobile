#!/bin/bash

# IntentOS Mobile Build Script
# Builds and prepares the app for installation

set -e

echo "🚀 IntentOS Mobile Build Script"
echo "================================="
echo ""

# Check Swift version
echo "📦 Checking Swift version..."
swift --version
echo ""

# Clean previous build
echo "🧹 Cleaning previous builds..."
swift package clean
echo ""

# Run tests
echo "✅ Running tests..."
swift test
echo ""

# Build
echo "🔨 Building IntentOSKit framework..."
swift build -c release
echo ""

# Build app
echo "📱 Building IntentOS Mobile app..."
swift build -c release --product IntentOSApp
echo ""

echo "✨ Build complete! App is ready."
echo ""
echo "To open in Xcode:"
echo "  open Package.swift"
echo ""
echo "To run on simulator:"
echo "  xcode-select --install  # If needed"
echo "  open -a Simulator"
echo "  open Package.swift"
echo ""
