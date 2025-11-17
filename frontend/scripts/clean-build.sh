#!/bin/bash

# Script pour nettoyer les fichiers de build et réduire la taille du projet

echo "🧹 Nettoyage des fichiers de build..."

cd "$(dirname "$0")/.."

# Nettoyer Flutter
echo "📦 Nettoyage Flutter..."
flutter clean

# Nettoyer les pods iOS (optionnel, décommentez si nécessaire)
# echo "📦 Nettoyage CocoaPods..."
# cd ios
# rm -rf Pods Podfile.lock
# cd ..

# Nettoyer les fichiers temporaires
echo "🗑️  Suppression des fichiers temporaires..."
find . -name "*.DS_Store" -delete
find . -name ".dart_tool" -type d -exec rm -rf {} + 2>/dev/null || true

echo "✅ Nettoyage terminé !"
echo ""
echo "Taille actuelle du projet :"
du -sh . 2>/dev/null

