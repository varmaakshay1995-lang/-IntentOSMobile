#!/bin/bash

# Generate API documentation from Swift code
# Requires: swift-doc or similar

echo "📚 Generating API Documentation..."
echo ""

if command -v swift-doc &> /dev/null; then
    swift-doc generate Sources/IntentOSKit/IntentOSKit.swift -o docs/
    echo "✅ Documentation generated in docs/ directory"
else
    echo "⚠️  swift-doc not installed. Skipping documentation generation."
    echo "Install with: brew install SwiftDocOrg/formulae/swift-doc"
fi
