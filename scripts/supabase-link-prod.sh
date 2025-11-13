#!/bin/bash
# Lier le projet local au projet Supabase PROD

echo "🚀 Liaison au projet CrewSnow PROD..."
echo "⚠️  ATTENTION: Vous allez basculer vers la PRODUCTION!"
read -p "Êtes-vous sûr? (yes/no): " confirm

if [ "$confirm" = "yes" ]; then
    npx supabase link --project-ref ahxezvuxxqfwgztivfle
    
    if [ $? -eq 0 ]; then
        echo "✅ Lié au projet PROD (ahxezvuxxqfwgztivfle)"
        echo "🚨 PROD MODE ACTIVÉ - Soyez très prudent avec:"
        echo "   npx supabase db push    # migrations en PROD"
        echo "   npx supabase db reset   # ⚠️ DESTRUCTIF en PROD"
    else
        echo "❌ Échec de la liaison PROD"
    fi
else
    echo "❌ Liaison annulée"
fi
