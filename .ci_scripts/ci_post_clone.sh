#!/bin/sh

# Xcode Cloud CI Script for Flutter iOS builds
# This script runs after the repository is cloned

set -e

echo "🚀 Starting Xcode Cloud CI Post-Clone Script..."

# Navigate to project root
cd "$CI_WORKSPACE"

# Install Flutter (if not already installed)
if ! command -v flutter &> /dev/null; then
    echo "📦 Installing Flutter..."
    git clone https://github.com/flutter/flutter.git -b stable --depth 1 "$HOME/flutter"
    export PATH="$HOME/flutter/bin:$PATH"
fi

# Add Flutter to PATH (in case it was installed but not in PATH)
export PATH="$HOME/flutter/bin:$PATH"

# Verify Flutter installation
echo "🔍 Verifying Flutter installation..."
flutter --version
flutter doctor -v

# Get Flutter dependencies
echo "📚 Getting Flutter dependencies..."
flutter pub get

# Generate Flutter iOS files
echo "📱 Generating Flutter iOS files..."
flutter precache --ios

# Install CocoaPods dependencies
echo "🍎 Installing CocoaPods dependencies..."
cd ios
if ! command -v pod &> /dev/null; then
    echo "⚠️  CocoaPods not found, installing..."
    sudo gem install cocoapods
fi
pod install --repo-update
cd ..

echo "✅ CI Post-Clone Script completed successfully!"

