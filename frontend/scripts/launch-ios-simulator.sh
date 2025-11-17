#!/bin/bash

# Script pour lancer le simulateur iOS et l'app

echo "📱 Lancement du simulateur iOS..."

# Ouvrir le simulateur iOS
open -a Simulator

# Attendre que le simulateur démarre
echo "⏳ Attente du démarrage du simulateur..."
sleep 5

# Lancer l'app Flutter
cd "$(dirname "$0")/.."
echo "🚀 Lancement de CrewSnow..."
flutter run

