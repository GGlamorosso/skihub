#!/usr/bin/env python3
"""
Script pour corriger tous les appels de create_test_user
en ajoutant les casts explicites manquants
"""

import re

file_path = 'supabase/seed/create_many_test_users.sql'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern pour trouver les appels SELECT create_test_user
# On va remplacer ligne par ligne dans chaque appel

# 1. Ajouter ::VARCHAR aux usernames (ligne après UUID)
content = re.sub(
    r"(SELECT create_test_user\(\s*'[^']+'::UUID,\s*)'([a-z_]+)',",
    r"\1'\2'::VARCHAR,",
    content
)

# 2. Ajouter ::user_level aux niveaux (expert, advanced, etc.)
content = re.sub(
    r"('(expert|advanced|intermediate|beginner)',)",
    r"\1::user_level",
    content
)

# 3. Ajouter ::TEXT[] aux tableaux objectives (avant la bio)
content = re.sub(
    r"(ARRAY\[[^\]]+\],\s*)(\n\s*'[^']+',\s*-- Bio)",
    r"\1::TEXT[]\2",
    content
)

# 4. Ajouter ::TEXT aux bios
content = re.sub(
    r"('(?:[^']|'')+',\s*-- Bio)",
    r"\1::TEXT",
    content
)

# 5. Ajouter ::VARCHAR aux noms de stations
content = re.sub(
    r"('(?:Chamonix-Mont-Blanc|Val d''Isère|Courchevel|Zermatt|Tignes|Les Arcs|Verbier|St\. Anton)',)",
    r"\1::VARCHAR",
    content
)

# 6. Ajouter ::DATE aux expressions CURRENT_DATE + INTERVAL
content = re.sub(
    r"(CURRENT_DATE \+ INTERVAL '[^']+')",
    r"(\1)::DATE",
    content
)

# 7. Ajouter ::DATE à CURRENT_DATE seul
content = re.sub(
    r"(CURRENT_DATE,)(?!\s*--)",
    r"\1::DATE",
    content
)

# 8. Ajouter ::INTEGER aux nombres finaux (radius_km)
content = re.sub(
    r"(\n\s+)(\d+)(\n\s*\);)(?!\s*--)",
    r"\1\2::INTEGER\3",
    content
)

# 9. Corriger les tableaux objectives qui n'ont pas de cast
# Chercher les ARRAY avec des strings françaises qui ne sont pas encore castés
content = re.sub(
    r"(ARRAY\[(?:'[^']+',?\s*)+\])(\s*\n\s*'[^']+',\s*-- Bio)",
    r"\1::TEXT[]\2",
    content
)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("✅ Fichier corrigé !")

