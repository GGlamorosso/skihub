#!/bin/bash

# ============================================================================
# Script de déploiement de toutes les Edge Functions Supabase
# ============================================================================
# Usage: ./scripts/deploy-all-functions.sh [--critical-only]
# ============================================================================

set -e  # Arrêter en cas d'erreur

# Couleurs pour les messages
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Déploiement des Edge Functions CrewSnow${NC}\n"

# Vérifier si Supabase CLI est installé
if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI n'est pas installé${NC}"
    echo -e "${YELLOW}Installez-le avec:${NC}"
    echo "  brew install supabase/tap/supabase"
    echo "  ou"
    echo "  npm install -g supabase"
    exit 1
fi

# Vérifier si on est connecté
if ! supabase projects list &> /dev/null; then
    echo -e "${YELLOW}⚠️  Vous n'êtes pas connecté à Supabase${NC}"
    echo -e "${YELLOW}Exécutez: supabase login${NC}"
    exit 1
fi

# Vérifier si le projet est lié
if [ ! -f ".supabase/config.toml" ]; then
    echo -e "${YELLOW}⚠️  Le projet n'est pas lié${NC}"
    echo -e "${YELLOW}Exécutez: supabase link --project-ref VOTRE_PROJECT_REF${NC}"
    exit 1
fi

# Liste des fonctions critiques (minimum pour bêta)
CRITICAL_FUNCTIONS=(
    "match-candidates"
    "gatekeeper"
    "manage-consent"
)

# Liste de toutes les fonctions disponibles
ALL_FUNCTIONS=(
    "match-candidates"
    "gatekeeper"
    "manage-consent"
    "swipe"
    "swipe-enhanced"
    "send-message-enhanced"
    "stripe-webhook-enhanced"
    "create-stripe-customer"
    "analytics-posthog"
    "export-user-data"
    "delete-user-account"
    "webhook-n8n"
)

# Déterminer quelles fonctions déployer
if [ "$1" == "--critical-only" ]; then
    FUNCTIONS_TO_DEPLOY=("${CRITICAL_FUNCTIONS[@]}")
    echo -e "${YELLOW}📋 Mode: Déploiement des fonctions CRITIQUES uniquement (3 fonctions)${NC}\n"
else
    FUNCTIONS_TO_DEPLOY=("${ALL_FUNCTIONS[@]}")
    echo -e "${BLUE}📋 Mode: Déploiement de TOUTES les fonctions (${#ALL_FUNCTIONS[@]} fonctions)${NC}"
    echo -e "${YELLOW}💡 Astuce: Utilisez --critical-only pour déployer seulement les 3 fonctions critiques${NC}\n"
fi

# Compteurs
SUCCESS=0
FAILED=0
SKIPPED=0

# Déployer chaque fonction
for func in "${FUNCTIONS_TO_DEPLOY[@]}"; do
    func_path="supabase/functions/$func"
    
    # Vérifier si la fonction existe
    if [ ! -f "$func_path/index.ts" ]; then
        echo -e "${YELLOW}⏭️  $func: Fichier non trouvé, ignoré${NC}"
        ((SKIPPED++))
        continue
    fi
    
    echo -e "${BLUE}📦 Déploiement de: $func${NC}"
    
    # Déployer la fonction
    if supabase functions deploy "$func" --no-verify-jwt 2>&1 | tee /tmp/supabase-deploy.log; then
        echo -e "${GREEN}✅ $func: Déployé avec succès${NC}\n"
        ((SUCCESS++))
    else
        echo -e "${RED}❌ $func: Échec du déploiement${NC}"
        echo -e "${YELLOW}Vérifiez les logs ci-dessus pour plus de détails${NC}\n"
        ((FAILED++))
    fi
done

# Résumé
echo -e "\n${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📊 Résumé du déploiement${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Succès: $SUCCESS${NC}"
echo -e "${RED}❌ Échecs: $FAILED${NC}"
echo -e "${YELLOW}⏭️  Ignorés: $SKIPPED${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}🎉 Tous les déploiements ont réussi !${NC}"
    exit 0
else
    echo -e "${RED}⚠️  Certains déploiements ont échoué. Vérifiez les erreurs ci-dessus.${NC}"
    exit 1
fi

