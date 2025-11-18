#!/bin/bash

# ============================================================================
# 🔧 Script pour corriger toutes les erreurs de l'app
# ============================================================================

set -e

echo "🔧 Correction de toutes les erreurs..."
echo ""

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# ============================================================================
# ÉTAPE 1 : Vérifier que Supabase CLI est connecté
# ============================================================================

echo "📋 Étape 1 : Vérification de Supabase CLI..."

if ! command -v supabase &> /dev/null; then
    echo -e "${RED}❌ Supabase CLI n'est pas installé${NC}"
    echo "   Installez-le avec: npm install -g supabase"
    exit 1
fi

echo -e "${GREEN}✅ Supabase CLI trouvé${NC}"

# ============================================================================
# ÉTAPE 2 : Nettoyer Flutter
# ============================================================================

echo ""
echo "📋 Étape 2 : Nettoyage de Flutter..."

if [ -d "frontend" ]; then
    cd frontend
    
    echo "   🧹 flutter clean..."
    flutter clean > /dev/null 2>&1 || echo -e "${YELLOW}⚠️ flutter clean a échoué (peut être ignoré)${NC}"
    
    echo "   📦 flutter pub get..."
    flutter pub get > /dev/null 2>&1 || echo -e "${YELLOW}⚠️ flutter pub get a échoué${NC}"
    
    cd ..
    echo -e "${GREEN}✅ Flutter nettoyé${NC}"
else
    echo -e "${YELLOW}⚠️ Dossier frontend non trouvé, ignoré${NC}"
fi

# ============================================================================
# ÉTAPE 3 : Vérifier les Edge Functions
# ============================================================================

echo ""
echo "📋 ÉTAPE 3 : Vérification des Edge Functions..."

EDGE_FUNCTIONS=("match-candidates" "gatekeeper" "manage-consent")

for func in "${EDGE_FUNCTIONS[@]}"; do
    if [ -d "supabase/functions/$func" ]; then
        echo "   ✅ $func : trouvée"
    else
        echo -e "   ${YELLOW}⚠️ $func : non trouvée${NC}"
    fi
done

echo ""
echo -e "${GREEN}✅ Vérifications terminées !${NC}"
echo ""
echo "═══════════════════════════════════════════════════════════"
echo "📝 ACTIONS MANUELLES REQUISES :"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "1. 📊 Exécutez le script SQL :"
echo "   supabase/seed/FIX_ALL_ISSUES.sql"
echo "   Dans Supabase Dashboard > SQL Editor"
echo ""
echo "2. 🔧 Si la fonction get_optimized_candidates n'existe pas :"
echo "   Exécutez d'abord : supabase/migrations/20250110_candidate_scoring_views.sql"
echo ""
echo "3. 🚀 Déployez les Edge Functions si nécessaire :"
echo "   supabase functions deploy match-candidates"
echo "   supabase functions deploy gatekeeper"
echo "   supabase functions deploy manage-consent"
echo ""
echo "4. 📱 Relancez l'app :"
echo "   cd frontend && flutter run"
echo ""
echo "═══════════════════════════════════════════════════════════"

