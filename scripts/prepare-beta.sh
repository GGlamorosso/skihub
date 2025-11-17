#!/bin/bash

# Script de préparation automatique de la bêta CrewSnow
# Ce script nettoie et prépare l'app Flutter pour compilation/déploiement

set -e  # Arrêter en cas d'erreur

echo "🚀 Préparation de la bêta CrewSnow"
echo "=================================="

# Vérifications préalables
echo "📋 Vérifications préalables..."

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé ou n'est pas dans le PATH"
    exit 1
fi

# Vérifier que nous sommes dans le bon répertoire
if [ ! -f "frontend/pubspec.yaml" ]; then
    echo "❌ Script doit être exécuté depuis la racine du projet CrewSnow"
    echo "   Répertoire actuel: $(pwd)"
    echo "   Assurez-vous d'être dans: /Users/user/Desktop/SKIAPP/crewsnow/"
    exit 1
fi

# Afficher les versions
echo "✅ Flutter version:"
flutter --version | head -1

# Aller dans le dossier frontend
cd frontend

echo ""
echo "🧹 Nettoyage complet..."
echo "========================"

# Nettoyage Flutter
echo "📦 flutter clean..."
flutter clean

# Supprimer les dossiers de build
echo "🗑️  Suppression des caches..."
rm -rf build/
rm -rf .dart_tool/
rm -rf ios/build/
rm -rf android/build/
rm -rf android/app/build/

# Nettoyer les pods iOS
if [ -d "ios" ]; then
    echo "🍎 Nettoyage iOS Pods..."
    cd ios
    rm -rf Pods/
    rm -rf .symlinks/
    rm -f Podfile.lock
    cd ..
fi

echo ""
echo "📚 Récupération des dépendances..."
echo "=================================="

# Récupérer les packages Dart
echo "📦 flutter pub get..."
flutter pub get

# Mise à jour des dépendances
echo "📦 flutter pub deps..."
flutter pub deps

# iOS Pods
if [ -d "ios" ]; then
    echo "🍎 Installation des pods iOS..."
    cd ios
    pod install --repo-update
    cd ..
fi

echo ""
echo "🔍 Analyse du code..."
echo "===================="

# Analyse statique
echo "🔎 flutter analyze..."
if ! flutter analyze --no-fatal-infos; then
    echo "⚠️  Des warnings d'analyse ont été détectés"
    echo "   Cela ne devrait pas empêcher la compilation"
else
    echo "✅ Analyse du code réussie"
fi

echo ""
echo "🏗️  Build de test..."
echo "=================="

# Test build iOS (sans déploiement)
if [ -d "ios" ]; then
    echo "🍎 Test build iOS..."
    if flutter build ios --no-codesign --debug; then
        echo "✅ Build iOS réussie"
    else
        echo "❌ Erreur lors du build iOS"
        echo "   Vérifiez Xcode et les certificats"
        exit 1
    fi
fi

echo ""
echo "🎯 Vérifications finales..."
echo "=========================="

# Vérifier les fichiers critiques
CRITICAL_FILES=(
    "lib/main.dart"
    "lib/config/env_config.dart"
    "lib/services/supabase_service.dart"
    "lib/services/match_service.dart"
    "lib/services/user_service.dart"
)

for file in "${CRITICAL_FILES[@]}"; do
    if [ -f "$file" ]; then
        echo "✅ $file"
    else
        echo "❌ Fichier manquant: $file"
        exit 1
    fi
done

# Vérifier pubspec.yaml
if grep -q "crewsnow_frontend" pubspec.yaml; then
    echo "✅ pubspec.yaml"
else
    echo "❌ pubspec.yaml invalide"
    exit 1
fi

echo ""
echo "📱 Instructions de déploiement..."
echo "==============================="

echo ""
echo "🎉 PRÉPARATION TERMINÉE AVEC SUCCÈS !"
echo ""
echo "Prochaines étapes pour la bêta:"
echo ""
echo "1️⃣  Base de données:"
echo "   - Allez sur Supabase Dashboard > SQL Editor"
echo "   - Exécutez: backend/supabase/seed/complete_beta_setup.sql"
echo "   - Exécutez: backend/supabase/seed/create_test_users.sql (après création des comptes)"
echo "   - Vérifiez: backend/supabase/seed/verify_beta_setup.sql"
echo ""
echo "2️⃣  Edge Functions:"
echo "   - Redéployez 'match-candidates' avec le code corrigé"
echo "   - Testez les 3 fonctions (match-candidates, gatekeeper, manage-consent)"
echo ""
echo "3️⃣  Test de l'app:"
echo "   flutter run --release"
echo ""
echo "4️⃣  Archive Xcode:"
echo "   - Ouvrez: ios/Runner.xcworkspace"
echo "   - Product > Archive"
echo "   - Distribuez vers TestFlight"
echo ""
echo "📖 Guide complet: DEPLOY_BETA_COMPLETE.md"
echo ""
echo "✨ Bonne chance pour votre bêta ! 🚀"
