#!/bin/bash

# ============================================================================
# Script pour créer des utilisateurs de test
# ============================================================================
# Ce script exécute le fichier SQL pour créer les utilisateurs de test
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}👥 Création des utilisateurs de test CrewSnow${NC}\n"

# Vérifier si Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo -e "${YELLOW}⚠️  Supabase CLI n'est pas installé${NC}"
    echo "Installez-le avec: brew install supabase/tap/supabase"
    exit 1
fi

# Vérifier si le projet est lié
if [ ! -f ".supabase/config.toml" ]; then
    echo -e "${YELLOW}⚠️  Le projet n'est pas lié${NC}"
    echo "Exécutez: supabase link --project-ref qzpinzxiqupetortbczh"
    exit 1
fi

echo -e "${YELLOW}📋 IMPORTANT :${NC}"
echo "1. Créez d'abord les comptes dans Supabase Dashboard > Authentication > Users"
echo "2. Notez leurs UUIDs"
echo "3. Modifiez le fichier: supabase/seed/create_test_users_simple.sql"
echo "4. Remplacez les UUIDs (cherchez 'REMPLACER_PAR_UUID')"
echo ""
read -p "Appuyez sur Entrée quand vous avez modifié le fichier SQL..."

echo ""
echo -e "${BLUE}📦 Exécution du script SQL...${NC}"
echo ""

# Exécuter le script SQL
if supabase db execute --file supabase/seed/create_test_users_simple.sql; then
    echo ""
    echo -e "${GREEN}✅ Utilisateurs de test créés avec succès !${NC}"
    echo ""
    echo "Vous pouvez maintenant tester le feed dans l'app Flutter 🚀"
else
    echo ""
    echo -e "${YELLOW}⚠️  Erreur lors de l'exécution${NC}"
    echo "Vérifiez que :"
    echo "1. Les UUIDs sont corrects dans le fichier SQL"
    echo "2. Les comptes existent dans Authentication > Users"
    echo "3. La colonne 'objectives' existe dans la table users"
fi

