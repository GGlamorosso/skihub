#!/bin/bash
# Lier le projet local au projet Supabase DEV

echo "🔗 Liaison au projet CrewSnow DEV..."
npx supabase link --project-ref qzpinzxiqupetortbczh

if [ $? -eq 0 ]; then
    echo "✅ Lié au projet DEV (qzpinzxiqupetortbczh)"
    echo "📁 Vous pouvez maintenant utiliser:"
    echo "   npx supabase db push    # pour pousser les migrations"
    echo "   npx supabase db pull    # pour récupérer le schema"
    echo "   npx supabase db reset   # pour reset la DB"
else
    echo "❌ Échec de la liaison. Vérifiez:"
    echo "   1. Que vous êtes connecté: npx supabase login"
    echo "   2. Que le project-ref est correct"
    echo "   3. Que vous avez les permissions sur le projet"
fi
