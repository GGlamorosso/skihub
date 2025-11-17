# 🚀 Lancer la Beta - Plan d'Action Simple

## ✅ Ce qui est DÉJÀ fait dans le code

- ✅ Toutes les corrections Flutter sont appliquées
- ✅ Les Edge Functions sont corrigées dans les fichiers
- ✅ Le flux onboarding/profil est corrigé

## 📋 Ce qu'il reste à faire (3 étapes)

### ÉTAPE 1 : Créer toute la base de données (5 minutes)

Dans **Supabase Dashboard > SQL Editor**, copiez-collez et exécutez :

**Le contenu complet de** : `backend/supabase/migrations/20250117_complete_schema.sql`

Cette migration crée **TOUTES** les tables, index, fonctions et RLS policies nécessaires.

**Vérification** : Après exécution, vous devriez voir toutes les tables dans Table Editor.

---

### ÉTAPE 2 : Redéployer match-candidates (2 minutes)

Dans **Supabase Dashboard > Edge Functions > match-candidates** :

1. Cliquez sur la fonction pour l'éditer
2. Remplacez **TOUT** le code par le contenu de : `backend/supabase/functions/match-candidates/index.ts`
3. Cliquez sur **Deploy**

**Pourquoi** : La version déployée utilise encore `objectives` qui n'existe pas.

---

### ÉTAPE 3 : Créer votre profil (2 minutes)

Dans **SQL Editor**, exécutez (remplacez `VOTRE_USER_ID` par votre UUID) :

```sql
-- 1. Trouver votre USER_ID : Supabase Dashboard > Authentication > Users > Copier l'UUID

-- 2. Exécuter (remplacer VOTRE_USER_ID) :
UPDATE public.users 
SET 
  onboarding_completed = true,
  is_active = true,
  level = 'intermediate',
  ride_styles = ARRAY['alpine', 'snowboard']::ride_style[],
  languages = ARRAY['fr', 'en']::language_code[],
  bio = 'Passionné de ski !',
  last_active_at = NOW(),
  updated_at = NOW()
WHERE id = 'VOTRE_USER_ID';

-- 3. Vérifier :
SELECT id, email, username, onboarding_completed, level 
FROM public.users 
WHERE id = 'VOTRE_USER_ID';
```

---

### ÉTAPE 4 : Rebuild et lancer l'app (2 minutes)

```bash
cd frontend
flutter pub get
flutter run
```

---

## ✅ Checklist finale

Après ces 4 étapes, vérifiez dans les logs :

- ✅ Plus d'erreur `column users.objectives does not exist`
- ✅ Plus d'erreur `0 rows` pour le profil
- ✅ Plus d'erreur `Null is not a subtype` pour gatekeeper
- ✅ `✅ Function called: match-candidates` (sans erreur)
- ✅ Votre profil se charge dans l'onglet Profil
- ✅ Des profils apparaissent dans le feed (si d'autres utilisateurs existent)

---

## 🎯 Résumé ultra-simple

1. **SQL Editor** → Exécuter `20250117_complete_schema.sql` (crée tout)
2. **Edge Functions** → Redéployer `match-candidates` (code corrigé)
3. **SQL Editor** → Créer votre profil (UPDATE avec votre UUID)
4. **Terminal** → `flutter pub get && flutter run`

**C'est tout !** 🚀

---

## ⚠️ Si vous n'avez pas d'autres utilisateurs dans le feed

C'est normal ! Le feed affiche d'autres utilisateurs. Pour tester :

1. Créez 2-3 comptes de test dans Supabase Auth
2. Créez leurs profils avec le même UPDATE SQL
3. Vous verrez leurs profils dans le feed

Ou testez avec un autre appareil/compte.

---

**Après ces 4 étapes, votre app devrait fonctionner pour la beta !** ✅

