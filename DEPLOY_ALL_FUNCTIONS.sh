#!/bin/bash

# ============================================================================
# Déploiement de TOUTES les Edge Functions en une seule commande
# ============================================================================

cd /Users/user/Desktop/SKIAPP/crewsnow

echo "🚀 Déploiement de toutes les Edge Functions..."
echo ""

# Déployer toutes les fonctions une par une
supabase functions deploy match-candidates && \
supabase functions deploy gatekeeper && \
supabase functions deploy manage-consent && \
supabase functions deploy swipe && \
supabase functions deploy swipe-enhanced && \
supabase functions deploy send-message-enhanced && \
supabase functions deploy stripe-webhook && \
supabase functions deploy stripe-webhook-enhanced && \
supabase functions deploy create-stripe-customer && \
supabase functions deploy analytics-posthog && \
supabase functions deploy export-user-data && \
supabase functions deploy delete-user-account && \
supabase functions deploy webhook-n8n

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 Toutes les Edge Functions sont déployées avec succès !"
else
    echo ""
    echo "⚠️  Certaines fonctions ont échoué. Vérifiez les erreurs ci-dessus."
fi

