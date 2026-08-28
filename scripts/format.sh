#!/bin/bash

# Format Swift code according to style guidelines
# Requires: swift-format

echo "🎨 Formatting Swift Code..."
echo ""

if command -v swift-format &> /dev/null; then
    swift-format -i -r Sources/
    swift-format -i -r Tests/
    echo "✅ Code formatted successfully"
else
    echo "⚠️  swift-format not installed. Skipping code formatting."
    echo "Install with: brew install swift-format"
fi
