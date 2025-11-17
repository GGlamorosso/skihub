#!/bin/bash

# Script pour lancer Flutter avec DevTools et Hot Reload

echo "🚀 Lancement de CrewSnow avec preview..."
echo ""

cd "$(dirname "$0")/.."

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter n'est pas installé ou pas dans le PATH"
    exit 1
fi

# Lancer l'app en mode debug
echo "📱 Lancement de l'application..."
flutter run --debug

# Note: DevTools s'ouvrira automatiquement ou sera accessible via:
# - Cmd+Shift+P → "Flutter: Open DevTools" dans Cursor
# - Ou http://localhost:9100 dans le navigateur

