#!/bin/bash

# Script pour lancer l'émulateur et l'application Flutter
# Usage: ./scripts/launch-flutter-app.sh [ios|android]

set -e

# Couleurs pour les messages
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Aller dans le dossier frontend
cd "$(dirname "$0")/../frontend"

echo -e "${BLUE}🚀 Lancement de l'application CrewSnow${NC}"
echo ""

# Vérifier que Flutter est installé
if ! command -v flutter &> /dev/null; then
    echo -e "${YELLOW}❌ Flutter n'est pas installé${NC}"
    exit 1
fi

# Vérifier les appareils disponibles
echo -e "${BLUE}📱 Vérification des appareils disponibles...${NC}"
flutter devices

echo ""
echo -e "${BLUE}Choisissez une option :${NC}"
echo "1) iOS Simulator"
echo "2) Android Emulator"
echo "3) Lancer sans émulateur (utiliser un appareil connecté)"
echo ""
read -p "Votre choix (1-3): " choice

case $choice in
    1)
        echo -e "${GREEN}🍎 Lancement de l'iOS Simulator...${NC}"
        flutter emulators --launch apple_ios_simulator
        echo -e "${YELLOW}⏳ Attente de 5 secondes que le Simulator démarre...${NC}"
        sleep 5
        echo -e "${GREEN}🚀 Lancement de l'application...${NC}"
        flutter run -d apple_ios_simulator
        ;;
    2)
        echo -e "${GREEN}🤖 Lancement de l'Android Emulator...${NC}"
        flutter emulators --launch Medium_Phone_API_36.1
        echo -e "${YELLOW}⏳ Attente de 10 secondes que l'émulateur démarre...${NC}"
        sleep 10
        echo -e "${GREEN}🚀 Lancement de l'application...${NC}"
        flutter run -d Medium_Phone_API_36.1
        ;;
    3)
        echo -e "${GREEN}🚀 Lancement de l'application sur l'appareil connecté...${NC}"
        flutter run
        ;;
    *)
        echo -e "${YELLOW}❌ Choix invalide${NC}"
        exit 1
        ;;
esac

