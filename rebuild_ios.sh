#!/bin/bash
echo "🧹 Cleaning Flutter build..."
flutter clean

echo "📦 Getting Flutter packages..."
flutter pub get

echo "🔨 Building iOS app..."
cd ios
pod install
cd ..

echo "🚀 Running on iOS..."
flutter run

echo "✅ Done! Native changes should now be applied."
