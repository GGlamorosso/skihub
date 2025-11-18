#!/usr/bin/env python3
"""
Script complet pour corriger tous les appels de create_test_user
"""

import re

file_path = 'supabase/seed/create_many_test_users.sql'

with open(file_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

output = []
i = 0
while i < len(lines):
    line = lines[i]
    
    # Si on trouve un SELECT create_test_user, on traite le bloc
    if 'SELECT create_test_user(' in line:
        output.append(line)
        i += 1
        param_count = 0
        
        # Traiter chaque paramètre jusqu'à la fermeture )
        while i < len(lines) and ');' not in lines[i]:
            line = lines[i]
            
            # Paramètre 1: UUID (déjà bon)
            if param_count == 0:
                output.append(line)
            
            # Paramètre 2: username - ajouter ::VARCHAR si manquant
            elif param_count == 1:
                if "::VARCHAR" not in line and "'" in line:
                    line = line.rstrip().rstrip(',') + '::VARCHAR,\n'
                output.append(line)
            
            # Paramètre 3: level - ajouter ::user_level si manquant
            elif param_count == 2:
                if "::user_level" not in line:
                    line = line.rstrip().rstrip(',') + '::user_level,\n'
                output.append(line)
            
            # Paramètre 4: ride_styles (déjà bon normalement)
            elif param_count == 3:
                output.append(line)
            
            # Paramètre 5: languages (déjà bon normalement)
            elif param_count == 4:
                output.append(line)
            
            # Paramètre 6: objectives - ajouter ::TEXT[] si manquant
            elif param_count == 5:
                if "::TEXT[]" not in line and "ARRAY[" in line:
                    line = line.rstrip().rstrip(',') + '::TEXT[],\n'
                output.append(line)
            
            # Paramètre 7: bio - ajouter ::TEXT si manquant
            elif param_count == 6:
                if "::TEXT" not in line and "'" in line and "Bio" not in line:
                    line = line.rstrip().rstrip(',') + '::TEXT,\n'
                output.append(line)
            
            # Paramètre 8: birth_date (déjà bon normalement)
            elif param_count == 7:
                output.append(line)
            
            # Paramètre 9: station_name - ajouter ::VARCHAR si manquant
            elif param_count == 8:
                if "::VARCHAR" not in line and "'" in line:
                    line = line.rstrip().rstrip(',') + '::VARCHAR,\n'
                output.append(line)
            
            # Paramètre 10: date_from - ajouter ::DATE si manquant
            elif param_count == 9:
                if "::DATE" not in line and ("CURRENT_DATE" in line or "INTERVAL" in line):
                    if "CURRENT_DATE" in line and "INTERVAL" not in line:
                        line = line.rstrip().rstrip(',') + '::DATE,\n'
                    elif "INTERVAL" in line:
                        line = re.sub(r'(CURRENT_DATE \+ INTERVAL[^)]+)\)', r'(\1)::DATE', line)
                        if not line.endswith(',\n'):
                            line = line.rstrip() + ',\n'
                output.append(line)
            
            # Paramètre 11: date_to - ajouter ::DATE si manquant
            elif param_count == 10:
                if "::DATE" not in line and ("CURRENT_DATE" in line or "INTERVAL" in line):
                    if "CURRENT_DATE" in line and "INTERVAL" not in line:
                        line = line.rstrip().rstrip(',') + '::DATE,\n'
                    elif "INTERVAL" in line:
                        line = re.sub(r'(CURRENT_DATE \+ INTERVAL[^)]+)\)', r'(\1)::DATE', line)
                        if not line.endswith(',\n'):
                            line = line.rstrip() + ',\n'
                output.append(line)
            
            # Paramètre 12: radius_km - ajouter ::INTEGER si manquant
            elif param_count == 11:
                if "::INTEGER" not in line and line.strip().isdigit():
                    line = line.rstrip().rstrip(',') + '::INTEGER\n'
                output.append(line)
            
            else:
                output.append(line)
            
            # Compter les paramètres (lignes avec des valeurs, pas les commentaires)
            if line.strip() and not line.strip().startswith('--'):
                if ',' in line or (param_count == 11 and ')' in line):
                    param_count += 1
            
            i += 1
        
        # Ajouter la ligne de fermeture
        if i < len(lines):
            output.append(lines[i])
        i += 1
    else:
        output.append(line)
        i += 1

with open(file_path, 'w', encoding='utf-8') as f:
    f.writelines(output)

print("✅ Tous les appels ont été corrigés !")

