#!/bin/bash
# Afficher le statut de la liaison Supabase actuelle

echo "📋 Statut Supabase CLI..."

# Vérifier la connexion
if npx supabase projects list > /dev/null 2>&1; then
    echo "✅ Connecté à Supabase"
    
    # Afficher les projets
    echo ""
    echo "📂 Vos projets:"
    npx supabase projects list
    
    # Afficher le projet actuellement lié
    echo ""
    echo "🔗 Projet actuellement lié:"
    if [ -f "supabase/.branches/default" ]; then
        project_ref=$(cat supabase/.branches/default 2>/dev/null)
        if [ "$project_ref" = "qzpinzxiqupetortbczh" ]; then
            echo "   🔧 DEV - CrewSnow Dev ($project_ref)"
        elif [ "$project_ref" = "ahxezvuxxqfwgztivfle" ]; then
            echo "   🚀 PROD - CrewSnow Prod ($project_ref)"
        else
            echo "   ❓ Projet inconnu ($project_ref)"
        fi
    else
        echo "   ❌ Aucun projet lié"
        echo "   💡 Utilisez: ./scripts/supabase-link-dev.sh"
    fi
else
    echo "❌ Non connecté à Supabase"
    echo "💡 Exécutez: npx supabase login"
fi
