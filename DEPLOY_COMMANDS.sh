#!/bin/bash

# ============================================================================
# Déploiement de TOUTES les Edge Functions Supabase
# ============================================================================
# Vous êtes déjà connecté et le projet est lié ✅
# ============================================================================

cd /Users/user/Desktop/SKIAPP/crewsnow

echo "🚀 Déploiement de toutes les Edge Functions CrewSnow..."
echo ""

# Liste de toutes les fonctions à déployer
FUNCTIONS=(
    "match-candidates"
    "gatekeeper"
    "manage-consent"
    "swipe"
    "swipe-enhanced"
    "send-message-enhanced"
    "stripe-webhook"
    "stripe-webhook-enhanced"
    "create-stripe-customer"
    "analytics-posthog"
    "export-user-data"
    "delete-user-account"
    "webhook-n8n"
)

# Compteurs
SUCCESS=0
FAILED=0

# Déployer chaque fonction
for func in "${FUNCTIONS[@]}"; do
    echo "📦 Déploiement de: $func"
    
    if supabase functions deploy "$func"; then
        echo "✅ $func: Déployé avec succès"
        ((SUCCESS++))
    else
        echo "❌ $func: Échec du déploiement"
        ((FAILED++))
    fi
    echo ""
done

# Résumé
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 Résumé du déploiement"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✅ Succès: $SUCCESS"
echo "❌ Échecs: $FAILED"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ $FAILED -eq 0 ]; then
    echo "🎉 Toutes les Edge Functions sont déployées avec succès !"
else
    echo "⚠️  Certaines fonctions ont échoué. Vérifiez les erreurs ci-dessus."
fi

