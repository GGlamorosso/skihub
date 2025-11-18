# 🔧 Correction de l'erreur SQL - Explication

## ❌ Erreur rencontrée

```
ERROR: 42883: function create_test_user(uuid, unknown, unknown, ride_style[], language_code[], text[], unknown, date, unknown, timestamp without time zone, timestamp without time zone, integer) does not exist
```

## 🔍 Cause du problème

PostgreSQL ne peut pas inférer automatiquement les types de certains paramètres dans les appels de fonction. Il faut ajouter des **casts explicites** (`::TYPE`).

## ✅ Solution : Ajouter des casts explicites

Pour chaque appel de `create_test_user`, vous devez ajouter des casts sur :

1. **Username** : `'username'::VARCHAR`
2. **Level** : `'expert'::user_level` (ou `'advanced'`, `'intermediate'`, `'beginner'`)
3. **Objectives** : `ARRAY[...]::TEXT[]`
4. **Bio** : `'texte bio'::TEXT`
5. **Station name** : `'Chamonix-Mont-Blanc'::VARCHAR`
6. **Dates** : `(CURRENT_DATE + INTERVAL '7 days')::DATE`
7. **Radius** : `30::INTEGER`

## 📝 Exemple de correction

**AVANT (incorrect)** :
```sql
SELECT create_test_user(
    'uuid'::UUID,
    'freeride_expert',  -- ❌ Manque ::VARCHAR
    'expert',           -- ❌ Manque ::user_level
    ARRAY[...]::ride_style[],
    ARRAY[...]::language_code[],
    ARRAY[...],         -- ❌ Manque ::TEXT[]
    'bio texte',        -- ❌ Manque ::TEXT
    '1985-03-15'::DATE,
    'Chamonix',         -- ❌ Manque ::VARCHAR
    CURRENT_DATE + INTERVAL '7 days',  -- ❌ Manque ::DATE
    CURRENT_DATE + INTERVAL '14 days', -- ❌ Manque ::DATE
    30                  -- ❌ Manque ::INTEGER
);
```

**APRÈS (correct)** :
```sql
SELECT create_test_user(
    'uuid'::UUID,
    'freeride_expert'::VARCHAR,  -- ✅
    'expert'::user_level,        -- ✅
    ARRAY[...]::ride_style[],
    ARRAY[...]::language_code[],
    ARRAY[...]::TEXT[],          -- ✅
    'bio texte'::TEXT,            -- ✅
    '1985-03-15'::DATE,
    'Chamonix'::VARCHAR,          -- ✅
    (CURRENT_DATE + INTERVAL '7 days')::DATE,    -- ✅
    (CURRENT_DATE + INTERVAL '14 days')::DATE,   -- ✅
    30::INTEGER                   -- ✅
);
```

## 🚀 Solution rapide

**Option 1 : Utiliser le fichier déjà corrigé**

J'ai corrigé les 2 premiers appels dans le fichier. Vous pouvez :
1. Copier le pattern des 2 premiers appels corrigés
2. Appliquer le même pattern aux 20 autres appels

**Option 2 : Exécuter par petits groupes**

Exécutez le script par petits groupes (2-3 utilisateurs à la fois) pour identifier plus facilement les erreurs restantes.

**Option 3 : Utiliser le Dashboard SQL Editor**

1. Copiez les 2-3 premiers appels corrigés
2. Exécutez-les
3. Si ça fonctionne, continuez avec les suivants

## ✅ Vérification

Après correction, testez avec un seul appel :

```sql
SELECT create_test_user(
    '4cab82c6-5828-406f-b047-5c58c076ec30'::UUID,
    'freeride_expert'::VARCHAR,
    'expert'::user_level,
    ARRAY['freeride', 'powder', 'touring']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY['explorer', 'partager']::TEXT[],
    'Bio test'::TEXT,
    '1985-03-15'::DATE,
    'Chamonix-Mont-Blanc'::VARCHAR,
    (CURRENT_DATE + INTERVAL '7 days')::DATE,
    (CURRENT_DATE + INTERVAL '14 days')::DATE,
    30::INTEGER
);
```

Si cet appel fonctionne, le pattern est correct ! ✅

