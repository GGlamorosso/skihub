# 👥 Guide : Créer les utilisateurs de test

## ❌ Problème actuel

L'erreur indique que l'UUID `4cab82c6-5828-406f-b047-5c58c076ec30` n'existe pas dans la table `users`.

## ✅ Solution : 2 options

### Option 1 : Utiliser les UUIDs existants (Recommandé)

Si vous avez déjà créé des utilisateurs dans Authentication > Users :

1. **Récupérer les UUIDs existants** :
   ```sql
   SELECT id, email, created_at 
   FROM auth.users 
   ORDER BY created_at DESC 
   LIMIT 22;
   ```

2. **Modifier le fichier SQL** :
   - Ouvrez `supabase/seed/create_many_test_users.sql`
   - Remplacez les UUIDs par ceux que vous avez récupérés
   - Exécutez le script

### Option 2 : Créer les utilisateurs automatiquement (Nouveau script)

J'ai créé un nouveau script `create_many_test_users_v2.sql` qui :
- ✅ Vérifie si l'utilisateur existe dans `auth.users`
- ✅ Crée automatiquement l'utilisateur dans `public.users` s'il n'existe pas
- ✅ Met à jour le profil si l'utilisateur existe déjà

**Étapes** :

1. **Créer les 22 comptes dans Authentication** :
   - Supabase Dashboard > Authentication > Users
   - Cliquez sur "Add User" 22 fois
   - Utilisez des emails différents (ex: `test1@crewsnow.test`, `test2@crewsnow.test`, etc.)

2. **Récupérer les UUIDs** :
   ```sql
   SELECT id, email 
   FROM auth.users 
   ORDER BY created_at DESC 
   LIMIT 22;
   ```

3. **Modifier le fichier** `create_many_test_users_v2.sql` :
   - Remplacez les UUIDs par ceux que vous avez récupérés

4. **Exécuter le script** dans SQL Editor

---

## 🔍 Vérification rapide

Pour voir quels utilisateurs existent déjà :

```sql
-- Voir tous les utilisateurs dans auth.users
SELECT id, email, created_at 
FROM auth.users 
ORDER BY created_at DESC;

-- Voir quels utilisateurs existent dans public.users
SELECT id, email, username 
FROM public.users;
```

---

## 💡 Astuce

Si vous avez déjà des utilisateurs créés, utilisez leurs UUIDs réels au lieu de créer 22 nouveaux comptes. Il vous suffit de modifier les UUIDs dans le fichier SQL.

---

**Le nouveau script `create_many_test_users_v2.sql` est plus robuste et créera automatiquement les utilisateurs dans `public.users` s'ils existent dans `auth.users` !** ✅

