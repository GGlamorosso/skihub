# 🚀 Instructions de Déploiement - Corrections Appliquées

## ✅ Corrections Flutter (Terminées)

### 1. Requête profil utilisateur - CORRIGÉ
- **Fichier** : `frontend/lib/services/user_service.dart`
- **Correction** : Utilisation de `profile_photos!profile_photos_user_id_fkey` au lieu de `profile_photos!inner`
- **Status** : ✅ Corrigé

### 2. RenderFlex overflow TrackerScreen - CORRIGÉ
- **Fichier** : `frontend/lib/features/tracking/presentation/tracker_screen.dart`
- **Correction** : Ajout de `SingleChildScrollView` avec `mainAxisSize: MainAxisSize.min` dans `_buildActiveTrackingSection` et `_buildReadyToTrackSection`
- **Status** : ✅ Corrigé

### 3. Google Fonts - CORRIGÉ
- **Fichier** : `frontend/lib/main.dart`
- **Correction** : Ajout de `GoogleFonts.config.allowRuntimeFetching = false` au démarrage
- **Status** : ✅ Corrigé

## 📦 Edge Functions Supabase (À déployer)

### Fonctions créées :
1. ✅ `match-candidates` - Retourne les candidats pour le matching
2. ✅ `gatekeeper` - Vérifie les permissions et quotas
3. ✅ `manage-consent` - Gère les consentements utilisateur

### Déploiement

#### Option 1 : Via Supabase CLI (Recommandé)
```bash
# Installer Supabase CLI si pas déjà fait
brew install supabase/tap/supabase

# Se connecter à votre projet
supabase login

# Lier votre projet
cd backend/supabase
supabase link --project-ref votre-project-ref

# Déployer les fonctions
supabase functions deploy match-candidates
supabase functions deploy gatekeeper
supabase functions deploy manage-consent
```

#### Option 2 : Via Supabase Dashboard
1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet
3. Allez dans **Edge Functions**
4. Cliquez sur **Create a new function**
5. Copiez-collez le contenu de chaque fonction :
   - `backend/supabase/functions/match-candidates/index.ts`
   - `backend/supabase/functions/gatekeeper/index.ts`
   - `backend/supabase/functions/manage-consent/index.ts`

## 🗄️ Migration SQL (À exécuter)

### Fichier : `backend/supabase/migrations/20250114_add_matches_last_message_at.sql`

**À exécuter dans Supabase SQL Editor :**

1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet
3. Allez dans **SQL Editor**
4. Créez une nouvelle requête
5. Copiez-collez le contenu de `backend/supabase/migrations/20250114_add_matches_last_message_at.sql`
6. Exécutez la requête

**Cette migration :**
- ✅ Ajoute `last_message_at` dans la table `matches`
- ✅ Crée un index pour la performance
- ✅ Crée la fonction `get_total_unread_count(p_user_id UUID)`
- ✅ Crée un trigger pour mettre à jour automatiquement `last_message_at`
- ✅ Met à jour les données existantes

## 👥 Données de Test (À créer)

### Fichier : `backend/supabase/seed/test_users.sql`

**Instructions :**

1. **Créer les utilisateurs dans Supabase Auth :**
   - Allez dans **Authentication > Users**
   - Créez 3 nouveaux utilisateurs avec les emails :
     - `test1@crewsnow.app`
     - `test2@crewsnow.app`
     - `test3@crewsnow.app`
   - Copiez les UUIDs générés

2. **Créer les profils :**
   - Ouvrez `backend/supabase/seed/test_users.sql`
   - Remplacez les `gen_random_uuid()` par les vrais UUIDs des utilisateurs créés
   - Remplacez `STATION_ID` par un ID de station existant dans votre base
   - Exécutez le script dans **SQL Editor**

3. **Créer des photos de profil (optionnel) :**
   - Pour chaque utilisateur test, créez au moins une photo de profil
   - Via l'app ou directement dans Supabase Storage

## 🔍 Vérification de la Connexion

### Vérifier que Supabase est bien connecté :

1. **Vérifier les variables d'environnement :**
   ```bash
   cd frontend
   cat lib/config/env_config.dart | grep supabase
   ```

2. **Tester la connexion dans l'app :**
   - Lancez l'app
   - Vérifiez les logs dans le terminal
   - Vous devriez voir : `✅ Supabase initialized successfully`

3. **Vérifier l'authentification :**
   - Connectez-vous avec votre compte
   - Vérifiez que vous pouvez charger votre profil

## 🐛 Diagnostic si aucun profil visible

### Checklist :

1. ✅ **Authentification** : Êtes-vous connecté ?
   - Vérifiez dans les logs : `✅ User signed in`

2. ✅ **Edge Function déployée** : `match-candidates` est-elle déployée ?
   - Testez dans Supabase Dashboard > Edge Functions

3. ✅ **Données** : Y a-t-il d'autres utilisateurs dans la base ?
   - Vérifiez dans Supabase Dashboard > Table Editor > users
   - Vérifiez que `onboarding_completed = true` et `is_active = true`

4. ✅ **Localisation GPS** : La position est-elle envoyée ?
   - Vérifiez dans les logs : `📍 GPS position sent: ...`

5. ✅ **Permissions** : Les permissions RLS sont-elles correctes ?
   - Vérifiez les policies dans Supabase Dashboard > Authentication > Policies

### Test rapide :

```sql
-- Dans Supabase SQL Editor, vérifiez les utilisateurs actifs
SELECT id, email, username, onboarding_completed, is_active 
FROM users 
WHERE onboarding_completed = true 
AND is_active = true;
```

## 📝 Prochaines étapes

1. **Déployer les Edge Functions** (voir ci-dessus)
2. **Exécuter la migration SQL** (voir ci-dessus)
3. **Créer les utilisateurs de test** (voir ci-dessus)
4. **Relancer l'app** : `flutter run`
5. **Tester le matching** : Vous devriez voir des profils à swiper

---

**Tous les fichiers ont été créés et sont prêts à être déployés !** 🎉

