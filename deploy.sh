#!/bin/bash

# Attendance & Zone Access System - Deployment Script
echo "🚀 Starting deployment of Attendance & Zone Access System..."

# Check if Firebase CLI is installed
if ! command -v firebase &> /dev/null; then
    echo "❌ Firebase CLI not found. Installing..."
    npm install -g firebase-tools
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "📦 Installing dependencies..."
flutter pub get

echo "🏗️  Building Flutter web app..."
flutter build web --release

echo "🔥 Deploying to Firebase..."
firebase deploy

echo "✅ Deployment complete!"
echo "🌐 Your app should be available at: https://your-project-id.web.app"
echo ""
echo "📋 Next steps:"
echo "1. Update Firebase configuration in lib/firebase_options.dart"
echo "2. Set up authentication in Firebase Console"
echo "3. Configure custom domain (optional)"
echo "4. Set up monitoring and analytics"
