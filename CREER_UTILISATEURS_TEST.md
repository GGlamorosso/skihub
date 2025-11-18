# 👥 Créer des utilisateurs de test - Guide Simple

**Temps estimé** : 5 minutes

---

## 📋 Étapes

### Étape 1 : Créer les comptes dans Supabase (2 min)

1. Allez sur [Supabase Dashboard](https://app.supabase.com) > **Authentication** > **Users**
2. Cliquez sur **Add User** (ou **Create User**)
3. Créez **4 comptes** avec des emails différents :
   - `test1@crewsnow.test`
   - `test2@crewsnow.test`
   - `test3@crewsnow.test`
   - `test4@crewsnow.test`
4. **Copiez les UUIDs** de chaque utilisateur (ex: `a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11`)

### Étape 2 : Modifier le fichier SQL (1 min)

1. Ouvrez le fichier : `supabase/seed/create_test_users_simple.sql`
2. Cherchez `REMPLACER_PAR_UUID_1`, `REMPLACER_PAR_UUID_2`, etc.
3. Remplacez par les vrais UUIDs que vous avez copiés

**Exemple** :
```sql
-- Avant
user_1_id UUID := 'REMPLACER_PAR_UUID_1';

-- Après
user_1_id UUID := 'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
```

### Étape 3 : Exécuter le script (1 min)

**Option A : Via le script automatique** (recommandé)
```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
./scripts/create-test-users.sh
```

**Option B : Via Supabase CLI directement**
```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
supabase db execute --file supabase/seed/create_test_users_simple.sql
```

**Option C : Via Supabase Dashboard**
1. Allez dans **SQL Editor**
2. Copiez-collez tout le contenu de `supabase/seed/create_test_users_simple.sql`
3. Cliquez sur **Run**

---

## ✅ Vérification

Après exécution, vous devriez voir :
- ✅ 4 utilisateurs avec des profils complets
- ✅ Usernames : `freeride_expert`, `ski_newbie`, `snowboard_pro`, `alpine_lover`
- ✅ Tous avec `onboarding_completed = true`
- ✅ Tous avec des stations assignées

---

## 🧪 Tester dans l'app

1. Lancez l'app Flutter
2. Connectez-vous avec votre compte principal
3. Allez dans le **Feed**
4. Vous devriez voir les 4 profils de test !

---

## 📝 Utilisateurs créés

| Username | Niveau | Styles | Objectifs |
|---------|--------|--------|-----------|
| `freeride_expert` | Expert | Freeride, Powder, Touring | Explorer, Partager, Partenaires |
| `ski_newbie` | Débutant | Alpine | Apprendre, Rencontrer, Découvrir |
| `snowboard_pro` | Avancé | Snowboard, Freestyle, Park | Progresser, Rider, Découvrir |
| `alpine_lover` | Intermédiaire | Alpine, Racing | Améliorer, Profiter, Rencontrer |

---

## ⚠️ Erreurs courantes

### "column users.objectives does not exist"
**Solution** : Exécutez d'abord la migration :
```bash
supabase db execute --file supabase/migrations/20250117_add_objectives_column.sql
```

### "relation public.stations does not exist"
**Solution** : Créez d'abord des stations ou modifiez le script pour ne pas utiliser de stations.

### "UUID invalide"
**Solution** : Vérifiez que vous avez bien copié les UUIDs depuis Authentication > Users.

---

**Une fois les utilisateurs créés, votre feed sera rempli et vous pourrez tester le swipe !** 🚀

