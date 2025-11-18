# 📄 Comment exécuter un fichier SQL sur Supabase

## ✅ Méthode 1 : Via Supabase Dashboard (Recommandé - Le plus simple)

1. **Ouvrez** [Supabase Dashboard](https://app.supabase.com)
2. **Sélectionnez** votre projet (CrewSnow Dev)
3. **Allez dans** **SQL Editor** (menu de gauche)
4. **Cliquez sur** **New Query**
5. **Copiez-collez** tout le contenu de votre fichier :
   ```
   supabase/seed/create_many_test_users.sql
   ```
6. **Cliquez sur** **Run** (ou `Cmd+Enter` / `Ctrl+Enter`)

**C'est tout !** ✅

---

## 🔧 Méthode 2 : Via psql (Terminal)

Si vous préférez utiliser le terminal :

### Étape 1 : Obtenir la connection string

1. Allez dans **Supabase Dashboard** > **Settings** > **Database**
2. Trouvez **Connection string** > **URI**
3. Copiez la connection string (ex: `postgresql://postgres:[PASSWORD]@db.qzpinzxiqupetortbczh.supabase.co:5432/postgres`)

### Étape 2 : Exécuter avec psql

```bash
# Remplacez [PASSWORD] par votre mot de passe de base de données
psql "postgresql://postgres:[PASSWORD]@db.qzpinzxiqupetortbczh.supabase.co:5432/postgres" \
  -f supabase/seed/create_many_test_users.sql
```

**Note** : Vous devez avoir `psql` installé. Sur macOS :
```bash
brew install postgresql
```

---

## 🚀 Méthode 3 : Script automatique

J'ai créé un script qui affiche le contenu du fichier pour faciliter le copier-coller :

```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
./scripts/execute-sql-file.sh supabase/seed/create_many_test_users.sql
```

Ce script affiche le contenu du fichier que vous pouvez copier-coller dans le Dashboard.

---

## ⚠️ Important avant d'exécuter

Vérifiez que :
- ✅ Vous avez créé les 22 comptes dans **Authentication > Users**
- ✅ Vous avez remplacé tous les UUIDs dans le fichier SQL
- ✅ La colonne `objectives` existe dans la table `users` (exécutez la migration si nécessaire)

---

## 🧪 Vérification après exécution

Dans **SQL Editor**, exécutez :

```sql
SELECT 
    username,
    level,
    objectives,
    onboarding_completed,
    is_active
FROM public.users 
WHERE username IN (
    'freeride_expert', 'alpine_master', 'snowboard_pro', 'touring_enthusiast',
    'freestyle_king', 'alpine_lover', 'powder_seeker', 'snowboard_advanced',
    'ski_advanced', 'backcountry_lover', 'intermediate_skier', 'snowboard_intermediate',
    'weekend_skier', 'park_rider', 'alpine_intermediate', 'snowboard_weekend',
    'ski_intermediate', 'freestyle_intermediate', 'ski_newbie', 'snowboard_beginner',
    'beginner_skier', 'new_skier'
)
ORDER BY level DESC, username;
```

Vous devriez voir les 22 utilisateurs ! 🎉

---

**Recommandation** : Utilisez la **Méthode 1** (Dashboard) - c'est le plus simple et le plus fiable ! ✅

