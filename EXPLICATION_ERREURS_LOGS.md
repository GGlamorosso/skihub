# 📋 Explication des erreurs dans les logs Flutter

## ✅ Réponse rapide : Oui, Flutter local peut se connecter à Supabase !

**Flutter en local se connecte parfaitement à Supabase** via :
- Les URLs Supabase configurées dans `.env`
- Les clés API (anon key, service role key)
- Les Edge Functions déployées

Le problème n'est **PAS** la connexion, mais des **fonctions SQL manquantes** dans votre base de données.

---

## 🔴 Erreur 1 : Fonction SQL manquante - `get_optimized_candidates`

### Message d'erreur :
```
Could not find the function public.get_optimized_candidates(p_limit, p_user_id, use_cache)
```

### Explication :
- L'Edge Function `match-candidates` essaie d'appeler une fonction SQL `get_optimized_candidates`
- Cette fonction n'existe pas dans votre base de données
- **Impact** : L'app ne peut pas charger les candidats de matching (écran de swipe vide)

### Solution :
Exécuter la migration dans **Supabase Dashboard > SQL Editor** :
```
supabase/migrations/20250110_candidate_scoring_views.sql
```

---

## 🔴 Erreur 2 : Fonction SQL manquante - `check_and_increment_usage`

### Message d'erreur :
```
Could not find the function public.check_and_increment_usage(p_count_message, p_count_swipe, p_limit_message, p_limit_swipe, p_user)
```

### Explication :
- L'Edge Function `gatekeeper` essaie d'appeler une fonction SQL pour vérifier les quotas
- Cette fonction n'existe pas ou a une signature différente
- **Impact** : L'app ne peut pas vérifier les limites de swipes/messages (quotas)

### Solution :
Exécuter la migration dans **Supabase Dashboard > SQL Editor** :
```
supabase/migrations/20250110_daily_usage_exact_specs.sql
```

**⚠️ Note** : Il y a peut-être un problème de signature (ordre des paramètres). Vérifiez comment l'Edge Function `gatekeeper` appelle cette fonction.

---

## 🟡 Erreur 3 : Type cast error - Profil utilisateur

### Message d'erreur :
```
Error fetching user profile: type 'Null' is not a subtype of type 'List<dynamic>' in type cast
```

### Explication :
- Le code Flutter s'attend à recevoir une **liste** (array) pour certains champs
- Mais la base de données retourne `NULL` au lieu d'un tableau vide `[]`
- Champs concernés : `ride_styles`, `languages`, `objectives`
- **Impact** : L'app plante lors du chargement du profil utilisateur

### Solution :
Mettre à jour votre profil dans la base pour que ces champs soient des tableaux vides au lieu de NULL :

```sql
UPDATE public.users 
SET 
    ride_styles = COALESCE(ride_styles, ARRAY[]::ride_style[]),
    languages = COALESCE(languages, ARRAY[]::language_code[]),
    objectives = COALESCE(objectives, ARRAY[]::TEXT[])
WHERE id = 'votre_user_id';
```

---

## 🟡 Erreur 4 : Invalid consent purpose

### Message d'erreur :
```
Invalid consent purpose, valid_purposes: [gps, ai_moderation, marketing, analytics, push_notifications, email_marketing, data_processing]
```

### Explication :
- L'app envoie un "purpose" de consentement qui n'est pas dans la liste valide
- L'Edge Function `manage-consent` rejette la requête
- **Impact** : Non-bloquant, mais le consentement GPS ne peut pas être vérifié

### Solution :
Vérifier le code Flutter qui appelle `manage-consent` et utiliser un purpose valide parmi :
- `gps`
- `ai_moderation`
- `marketing`
- `analytics`
- `push_notifications`
- `email_marketing`
- `data_processing`

---

## 🟢 Erreur 5 : AssetManifest.json (NON-BLOQUANT)

### Message d'erreur :
```
Unable to load asset: "AssetManifest.json"
```

### Explication :
- Problème avec le package `google_fonts` qui essaie de charger des assets
- C'est un problème Flutter local, pas lié à Supabase
- **Impact** : Les polices peuvent ne pas se charger, mais l'app fonctionne quand même

### Solution :
Peut être ignoré pour l'instant. Si ça vous dérange :
```bash
cd frontend
flutter clean
flutter pub get
flutter run
```

---

## 📊 Résumé des problèmes par priorité

| Priorité | Erreur | Impact | Solution |
|----------|--------|--------|----------|
| 🔴 **CRITIQUE** | `get_optimized_candidates` manquante | App ne charge pas les candidats | Exécuter migration `20250110_candidate_scoring_views.sql` |
| 🔴 **CRITIQUE** | `check_and_increment_usage` manquante | App ne vérifie pas les quotas | Exécuter migration `20250110_daily_usage_exact_specs.sql` |
| 🟡 **IMPORTANT** | Type cast error (NULL vs List) | App plante sur le profil | Mettre à jour les champs NULL en tableaux vides |
| 🟡 **MOYEN** | Invalid consent purpose | Consentement GPS ne fonctionne pas | Corriger le code Flutter |
| 🟢 **FAIBLE** | AssetManifest.json | Polices ne se chargent pas | Ignorer ou nettoyer Flutter |

---

## 🚀 Plan d'action recommandé

### Étape 1 : Exécuter les migrations SQL (CRITIQUE)

Dans **Supabase Dashboard > SQL Editor**, exécutez dans cet ordre :

1. `supabase/migrations/20250110_candidate_scoring_views.sql`
2. `supabase/migrations/20250110_daily_usage_exact_specs.sql`

### Étape 2 : Corriger les données NULL

```sql
-- Corriger votre profil utilisateur
UPDATE public.users 
SET 
    ride_styles = COALESCE(ride_styles, ARRAY[]::ride_style[]),
    languages = COALESCE(languages, ARRAY[]::language_code[]),
    objectives = COALESCE(objectives, ARRAY[]::TEXT[])
WHERE id = '8671c159-6689-4cf2-8387-ef491a4fdb42';
```

### Étape 3 : Vérifier que tout fonctionne

Relancez l'app :
```bash
cd frontend
flutter run
```

---

## ❓ Questions fréquentes

### Q: Pourquoi Flutter local peut-il se connecter à Supabase ?
**R:** Supabase est un service cloud accessible via HTTP/HTTPS. Flutter utilise les URLs et clés API pour se connecter, peu importe où l'app tourne (local, production, etc.).

### Q: Pourquoi les fonctions SQL sont-elles manquantes ?
**R:** Les migrations SQL doivent être exécutées manuellement dans Supabase Dashboard. Elles ne s'exécutent pas automatiquement.

### Q: Comment savoir quelles migrations ont été exécutées ?
**R:** Dans Supabase Dashboard > Database > Migrations, vous verrez l'historique des migrations appliquées.

### Q: L'erreur AssetManifest.json est-elle grave ?
**R:** Non, c'est juste un problème d'assets Flutter. L'app fonctionne quand même, seules les polices peuvent ne pas se charger correctement.

---

## 📝 Conclusion

**Le problème principal** : 2 fonctions SQL manquantes qui empêchent l'app de fonctionner correctement.

**La solution** : Exécuter les 2 migrations SQL dans Supabase Dashboard.

Une fois ces migrations exécutées, l'app devrait fonctionner ! 🎉

