# 🔧 Corriger les erreurs de l'app Flutter

## ❌ Erreurs identifiées

1. **Fonction SQL manquante** : `get_optimized_candidates` n'existe pas
2. **Profil utilisateur manquant** : Votre compte n'a pas de profil dans `public.users`
3. **Edge Functions** : Problèmes avec `gatekeeper` et `manage-consent`
4. **Assets Flutter** : Erreur `AssetManifest.json` (moins critique)

---

## ✅ Solution 1 : Exécuter la migration manquante

La fonction `get_optimized_candidates` est définie dans une migration qui n'a peut-être pas été exécutée.

### Étape 1 : Vérifier si la fonction existe

Dans **Supabase Dashboard > SQL Editor**, exécutez :

```sql
SELECT EXISTS(
    SELECT 1 FROM pg_proc 
    WHERE proname = 'get_optimized_candidates'
) as function_exists;
```

Si `function_exists` = `false`, continuez.

### Étape 2 : Exécuter la migration

Dans **Supabase Dashboard > SQL Editor**, exécutez le fichier :
```
supabase/migrations/20250110_candidate_scoring_views.sql
```

**OU** copiez-collez tout le contenu de ce fichier dans SQL Editor et exécutez.

---

## ✅ Solution 2 : Créer votre profil utilisateur

Votre compte (`8671c159-6689-4cf2-8387-ef491a4fdb42`) existe dans `auth.users` mais pas dans `public.users`.

### Option A : Via l'app (Recommandé)

1. **Connectez-vous à l'app**
2. **Complétez l'onboarding** :
   - Sélectionnez une station
   - Définissez vos dates de séjour
   - Configurez votre profil

Cela créera automatiquement votre profil dans `public.users`.

### Option B : Via SQL (Si l'onboarding ne fonctionne pas)

Dans **Supabase Dashboard > SQL Editor**, exécutez :

```sql
-- Récupérer votre email depuis auth.users
SELECT email FROM auth.users WHERE id = '8671c159-6689-4cf2-8387-ef491a4fdb42';

-- Créer votre profil (remplacez 'votre_email@example.com' par votre email)
INSERT INTO public.users (
    id,
    username,
    email,
    level,
    ride_styles,
    languages,
    objectives,
    is_active,
    created_at,
    updated_at,
    last_active_at
) VALUES (
    '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID,
    'votre_username',  -- Remplacez par votre username
    'votre_email@example.com',  -- Remplacez par votre email
    'intermediate'::user_level,
    ARRAY['alpine']::ride_style[],
    ARRAY['fr', 'en']::language_code[],
    ARRAY[]::TEXT[],
    true,
    NOW(),
    NOW(),
    NOW()
)
ON CONFLICT (id) DO NOTHING;

-- Ajouter une station (remplacez 'Chamonix-Mont-Blanc' par la station de votre choix)
INSERT INTO public.user_station_status (
    user_id,
    station_id,
    date_from,
    date_to,
    radius_km,
    is_active
)
SELECT 
    '8671c159-6689-4cf2-8387-ef491a4fdb42'::UUID,
    s.id,
    CURRENT_DATE,
    CURRENT_DATE + INTERVAL '7 days',
    25,
    true
FROM public.stations s
WHERE s.name = 'Chamonix-Mont-Blanc'  -- Remplacez par votre station
    AND s.is_active = true
LIMIT 1;
```

---

## ✅ Solution 3 : Vérifier les Edge Functions

### Vérifier que les Edge Functions sont déployées

Dans **Supabase Dashboard > Edge Functions**, vérifiez que ces fonctions sont déployées :
- ✅ `match-candidates`
- ✅ `gatekeeper`
- ✅ `manage-consent`

Si elles ne sont pas déployées, déployez-les :

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
supabase functions deploy match-candidates
supabase functions deploy gatekeeper
supabase functions deploy manage-consent
```

---

## ✅ Solution 4 : Corriger l'erreur AssetManifest.json (Flutter)

Cette erreur est liée aux polices Google Fonts. Pour la corriger :

### Option A : Nettoyer et reconstruire

```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

### Option B : Vérifier pubspec.yaml

Assurez-vous que `google_fonts` est bien dans `pubspec.yaml` :

```yaml
dependencies:
  google_fonts: ^6.1.0  # ou la version que vous utilisez
```

Puis :

```bash
cd frontend
flutter pub get
flutter run
```

---

## 🧪 Vérification finale

### 1. Vérifier que la fonction existe

```sql
SELECT proname, pronargs 
FROM pg_proc 
WHERE proname = 'get_optimized_candidates';
```

Vous devriez voir la fonction avec 3 paramètres.

### 2. Vérifier votre profil

```sql
SELECT id, username, email, level, is_active
FROM public.users 
WHERE id = '8671c159-6689-4cf2-8387-ef491a4fdb42';
```

Vous devriez voir votre profil.

### 3. Vérifier votre station

```sql
SELECT 
    u.username,
    s.name as station,
    uss.date_from,
    uss.date_to
FROM public.users u
JOIN public.user_station_status uss ON u.id = uss.user_id
JOIN public.stations s ON uss.station_id = s.id
WHERE u.id = '8671c159-6689-4cf2-8387-ef491a4fdb42'
    AND uss.is_active = true;
```

Vous devriez voir votre station configurée.

---

## 🚀 Ordre d'exécution recommandé

1. ✅ **Exécuter la migration** `20250110_candidate_scoring_views.sql`
2. ✅ **Créer votre profil** (via l'app ou SQL)
3. ✅ **Vérifier les Edge Functions** sont déployées
4. ✅ **Nettoyer Flutter** (`flutter clean && flutter pub get`)
5. ✅ **Relancer l'app** (`flutter run`)

---

## 📝 Notes

- L'erreur `AssetManifest.json` est souvent non-bloquante et peut être ignorée si l'app fonctionne
- L'erreur principale est la fonction SQL manquante et le profil utilisateur manquant
- Une fois ces deux problèmes résolus, l'app devrait fonctionner correctement

---

## 🔍 Dépannage supplémentaire

Si les erreurs persistent :

1. **Vérifiez les logs Edge Functions** dans Supabase Dashboard
2. **Vérifiez les RLS policies** pour s'assurer que vous pouvez lire `public.users`
3. **Vérifiez que votre token d'authentification est valide**

