#!/bin/bash

# Script pour corriger tous les appels de fonction dans create_many_test_users.sql
# Ajoute les casts explicites manquants

cd /Users/user/Desktop/SKIAPP/crewsnow

# Remplacer tous les appels SELECT create_test_user pour ajouter les casts
sed -i.bak \
  -e "s/\(SELECT create_test_user(\)/\1/g" \
  -e "s/\([0-9a-f-]\{36\}::UUID,\)/\1/g" \
  -e "s/\(^[[:space:]]*\)'\([a-z_]*\)',/\1'\2'::VARCHAR,/g" \
  -e "s/\(^[[:space:]]*\)'\(expert\|advanced\|intermediate\|beginner\)',/\1'\2'::user_level,/g" \
  -e "s/\(CURRENT_DATE + INTERVAL\)/(\1)::DATE/g" \
  -e "s/\(CURRENT_DATE\),/\1::DATE,/g" \
  -e "s/\(^[[:space:]]*\)\([0-9]\{1,2\}$\)/\1\2::INTEGER/g" \
  supabase/seed/create_many_test_users.sql

echo "✅ Corrections appliquées (backup créé: .bak)"

