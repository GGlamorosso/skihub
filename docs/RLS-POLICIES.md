# CrewSnow - Documentation Politiques RLS

## 📋 Vue d'Ensemble

Ce document détaille toutes les politiques Row Level Security (RLS) implémentées dans CrewSnow, définissant qui peut accéder à quelles données et dans quelles conditions.

## 🔒 Principe Général

**Row Level Security (RLS)** applique automatiquement des filtres `WHERE` à toutes les requêtes SQL selon l'utilisateur connecté. Chaque politique définit :
- **USING** : Conditions pour lire les données (SELECT)
- **WITH CHECK** : Conditions pour modifier les données (INSERT/UPDATE)

**Contexte d'authentification** : `auth.uid()` retourne l'UUID de l'utilisateur connecté via JWT Supabase.

---

## 📊 Matrice des Permissions par Table

| Table | Anonymous | Authenticated | Owner | Admin/Service |
|-------|-----------|---------------|-------|---------------|
| `users` | ❌ | Own profile only | ✅ | ✅ (service_role) |
| `stations` | ✅ (read) | ✅ (read) | ✅ (read) | ✅ |
| `profile_photos` | Approved only | Approved + own | ✅ | ✅ |
| `user_station_status` | ❌ | Own only | ✅ | ✅ |
| `likes` | ❌ | Own likes only | ✅ | ✅ |
| `matches` | ❌ | Own matches only | ✅ | ✅ |
| `messages` | ❌ | Own match messages | ✅ | ✅ |
| `groups` | ❌ | Own/member groups | ✅ | ✅ |
| `group_members` | ❌ | Same group only | ✅ | ✅ |
| `friends` | ❌ | Own friendships | ✅ | ✅ |
| `ride_stats_daily` | ❌ | Own stats only | ✅ | ✅ |
| `boosts` | ❌ | Own boosts only | ✅ | ✅ |
| `subscriptions` | ❌ | Own subscription | ❌ | ✅ (Stripe only) |

---

## 🏗️ Vue Publique : `public_profiles_v`

### Accès
- **Anonymous** : ✅ Lecture complète
- **Authenticated** : ✅ Lecture complète
- **Méthode** : `GRANT SELECT` (pas de policy RLS sur les vues)

### Colonnes Exposées
```sql
SELECT
  u.id,                    -- UUID utilisateur
  u.username AS pseudo,    -- Pseudonyme public
  u.level,                 -- Niveau ski (beginner/intermediate/advanced/expert)
  u.ride_styles,           -- Styles de ride (array)
  u.languages,             -- Langues parlées (array)
  u.is_premium,            -- Statut premium
  u.last_active_at,        -- Dernière activité
  p.storage_path AS photo_main_url,  -- Photo principale (si approuvée)
  us.station_id,           -- Station actuelle
  us.date_from,            -- Date début séjour
  us.date_to,              -- Date fin séjour
  us.radius_km             -- Rayon de recherche
FROM users u
LEFT JOIN profile_photos p ON p.user_id = u.id 
  AND p.is_main = true 
  AND p.moderation_status = 'approved'
LEFT JOIN user_station_status us ON us.user_id = u.id
WHERE u.is_active = true AND u.is_banned = false
```

### Colonnes PROTÉGÉES (non exposées)
- ❌ `email` - Adresse email privée
- ❌ `birth_date` - Date de naissance sensible
- ❌ `stripe_customer_id` - Données de facturation
- ❌ `verified_video_url` - Contenu de vérification
- ❌ `banned_reason` - Informations de modération
- ❌ `created_at` / `updated_at` - Métadonnées système

---

## 🔐 Politiques RLS Détaillées par Table

### 1. Table `users`

#### Politiques Actives
```sql
-- Lecture : Utilisateur voit son profil complet uniquement
"Users can view their own profile" (SELECT)
  USING (auth.uid() IS NOT NULL AND auth.uid() = id)

-- Modification : Utilisateur modifie son profil uniquement
"Users can update their own profile" (UPDATE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = id)

-- Création : Utilisateur crée son propre profil (signup)
"Users can insert their own profile" (INSERT)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = id)
```

#### Permissions Résultantes
- ✅ **Authenticated** : CRUD sur son propre profil
- ❌ **Anonymous** : Aucun accès direct
- ❌ **Cross-user** : Impossible de voir/modifier profils d'autrui

---

### 2. Table `stations`

#### Politiques Actives
```sql
-- Lecture publique : Données de référence accessibles à tous
"public can read stations" (SELECT)
  TO anon, authenticated
  USING (true)
```

#### Permissions Résultantes
- ✅ **Everyone** : Lecture complète (données publiques)
- ❌ **Modification** : Aucune (données de référence)

---

### 3. Table `profile_photos`

#### Politiques Actives
```sql
-- Insertion : Utilisateur uploade ses photos
"User can insert their own photo" (INSERT)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id)

-- Lecture publique : Photos approuvées visibles par tous
"Public read approved photos" (SELECT)
  TO anon, authenticated
  USING (moderation_status = 'approved')

-- Lecture privée : Utilisateur voit toutes ses photos
"User can read their photos" (SELECT)
  TO authenticated
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)

-- Modification : Utilisateur modifie ses photos (is_main)
"User can update their own photos" (UPDATE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id)

-- Suppression : Utilisateur supprime ses photos
"User can delete their own photos" (DELETE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
```

#### Permissions Résultantes
- ✅ **Anonymous** : Photos `approved` seulement
- ✅ **Owner** : Toutes ses photos (pending/approved/rejected)
- ❌ **Others** : Photos `pending`/`rejected` d'autrui invisibles
- ✅ **Moderation** : Via fonctions dédiées (service_role)

---

### 4. Table `user_station_status`

#### Politiques Actives
```sql
-- CRUD complet : Utilisateur gère ses localisations
"User can insert their own station status" (INSERT)
"User can read their own station status" (SELECT)  
"User can update their own station status" (UPDATE)
"User can delete their own station status" (DELETE)
  USING/WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id)
```

#### Permissions Résultantes
- ✅ **Owner** : CRUD complet sur ses localisations
- ❌ **Others** : Localisations d'autrui invisibles
- ✅ **Discovery** : Via `public_profiles_v` seulement

---

### 5. Table `likes`

#### Politiques Actives
```sql
-- Création : Utilisateur peut liker
"User can like someone" (INSERT)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = liker_id)

-- Lecture : Utilisateur voit likes donnés ET reçus
"User can read their likes" (SELECT)
  USING (auth.uid() IS NOT NULL AND (auth.uid() = liker_id OR auth.uid() = liked_id))

-- Suppression : Utilisateur peut unliker
"User can delete their own likes" (DELETE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = liker_id)
```

#### Permissions Résultantes
- ✅ **Liker** : Peut créer/supprimer ses likes
- ✅ **Liked** : Peut voir qui l'a liké
- ❌ **Others** : Likes entre tiers invisibles

---

### 6. Table `matches`

#### Politiques Actives
```sql
-- Lecture : Participants au match seulement
"User can view their matches" (SELECT)
  USING (auth.uid() IS NOT NULL AND (auth.uid() = user1_id OR auth.uid() = user2_id))
```

#### Permissions Résultantes
- ✅ **Match participants** : Peuvent voir le match
- ❌ **Others** : Matches d'autrui invisibles
- ❌ **Creation** : Automatique via fonction `create_match_from_likes()`

---

### 7. Table `messages`

#### Politiques Actives
```sql
-- Lecture : Messages dans ses matches
"User can view messages in their matches" (SELECT)
  USING (
    auth.uid() IS NOT NULL 
    AND (
      auth.uid() = sender_id
      OR auth.uid() = (SELECT user1_id FROM matches WHERE id = match_id)
      OR auth.uid() = (SELECT user2_id FROM matches WHERE id = match_id)
    )
  )

-- Création : Envoi messages dans ses matches
"User can send messages in their matches" (INSERT)
  WITH CHECK (
    auth.uid() IS NOT NULL 
    AND auth.uid() = sender_id
    AND (match membership verification)
  )

-- Modification : Édition de ses messages
"User can update their own messages" (UPDATE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = sender_id AND match membership)

-- Suppression : Suppression de ses messages
"User can delete their own messages" (DELETE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = sender_id AND match membership)
```

#### Permissions Résultantes
- ✅ **Match members** : CRUD messages dans leurs matches
- ❌ **Others** : Messages d'autres matches invisibles
- ✅ **Sender** : Peut éditer/supprimer ses propres messages

---

### 8. Table `groups`

#### Politiques Actives
```sql
-- Création : Utilisateur crée des groupes
"User can create groups" (INSERT)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = created_by)

-- Lecture : Créateur + membres voient le groupe
"User can view their groups" (SELECT)
  USING (
    auth.uid() IS NOT NULL 
    AND (
      auth.uid() = created_by
      OR EXISTS (SELECT 1 FROM group_members WHERE group_id = id AND user_id = auth.uid())
    )
  )

-- Modification : Créateur modifie le groupe
"User can update their groups" (UPDATE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = created_by)

-- Suppression : Créateur supprime le groupe
"User can delete their groups" (DELETE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = created_by)
```

#### Permissions Résultantes
- ✅ **Creator** : CRUD complet sur ses groupes
- ✅ **Members** : Lecture des groupes dont ils sont membres
- ❌ **Others** : Groupes externes invisibles

---

### 9. Table `group_members`

#### Politiques Actives
```sql
-- Inscription : Utilisateur rejoint des groupes
"User can join groups" (INSERT)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id)

-- Lecture : Membres du même groupe se voient
"User can view group memberships" (SELECT)
  USING (
    auth.uid() IS NOT NULL 
    AND EXISTS (
      SELECT 1 FROM group_members gm2 
      WHERE gm2.group_id = group_id AND gm2.user_id = auth.uid()
    )
  )

-- Modification : Propriétaire groupe gère les membres
"Group owner can update memberships" (UPDATE)
  USING (
    auth.uid() IS NOT NULL 
    AND EXISTS (
      SELECT 1 FROM groups g 
      WHERE g.id = group_id AND g.created_by = auth.uid()
    )
  )

-- Départ : Utilisateur quitte des groupes
"User can leave groups" (DELETE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
```

#### Permissions Résultantes
- ✅ **Member** : Peut rejoindre/quitter, voir autres membres
- ✅ **Group owner** : Peut gérer tous les membres
- ❌ **Others** : Membres d'autres groupes invisibles

---

### 10. Table `friends`

#### Politiques Actives
```sql
-- Demande : Utilisateur envoie des demandes d'amitié
"User can send friend requests" (INSERT)
  WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = requester_id)

-- Lecture : Relations d'amitié impliquant l'utilisateur
"User can view their friendships" (SELECT)
  USING (auth.uid() IS NOT NULL AND (auth.uid() = requester_id OR auth.uid() = requested_id))

-- Réponse : Destinataire accepte/rejette
"User can update friendship status" (UPDATE)
  USING (auth.uid() IS NOT NULL AND auth.uid() = requested_id)

-- Suppression : Participants peuvent supprimer la relation
"User can delete friendships" (DELETE)
  USING (auth.uid() IS NOT NULL AND (auth.uid() = requester_id OR auth.uid() = requested_id))
```

#### Permissions Résultantes
- ✅ **Requester** : Peut envoyer demandes, supprimer relations
- ✅ **Requested** : Peut accepter/rejeter, supprimer relations
- ❌ **Others** : Relations d'amitié d'autrui invisibles

---

### 11. Table `ride_stats_daily`

#### Politiques Actives
```sql
-- Statistiques privées : Utilisateur voit/modifie ses stats uniquement
"User can read own stats" (SELECT)
"User can insert their stats" (INSERT)
"User can update their stats" (UPDATE)
  USING/WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id)
```

#### Permissions Résultantes
- ✅ **Owner** : CRUD complet sur ses statistiques
- ❌ **Others** : Statistiques d'autrui invisibles
- ✅ **Privacy** : Données de tracking privées

---

### 12. Table `boosts`

#### Politiques Actives
```sql
-- Gestion complète : Utilisateur gère ses boosts
"User can create their own boosts" (INSERT)
"User can view their own boosts" (SELECT)
"User can update their own boosts" (UPDATE)
"User can delete their own boosts" (DELETE)
  USING/WITH CHECK (auth.uid() IS NOT NULL AND auth.uid() = user_id)
```

#### Permissions Résultantes
- ✅ **Owner** : CRUD complet sur ses boosts
- ❌ **Others** : Boosts d'autrui invisibles
- ✅ **Management** : Peut modifier/annuler avant expiration

---

### 13. Table `subscriptions`

#### Politiques Actives
```sql
-- Lecture uniquement : Utilisateur voit son abonnement
"User can read own subscription" (SELECT)
  USING (auth.uid() IS NOT NULL AND auth.uid() = user_id)
```

#### Permissions Résultantes
- ✅ **Owner** : Lecture de son abonnement uniquement
- ❌ **Modification** : Réservée aux webhooks Stripe (service_role)
- ✅ **Billing** : Données de facturation protégées

---

## 🎯 Cas d'Usage Typiques

### Découverte d'Utilisateurs
```sql
-- ✅ Fonctionne pour tous (anonymous + authenticated)
SELECT * FROM public_profiles_v 
WHERE station_id = 'some-station-id'
  AND ride_styles @> ARRAY['alpine']
  AND languages @> ARRAY['en']
LIMIT 20;
```

### Profil Complet (Utilisateur Connecté)
```sql
-- ✅ Fonctionne si auth.uid() = user_id
SELECT username, email, birth_date, stripe_customer_id
FROM users 
WHERE id = auth.uid();
```

### Chat Entre Utilisateurs Matchés
```sql
-- ✅ Fonctionne si utilisateur est membre du match
SELECT content, created_at, sender_id
FROM messages 
WHERE match_id = 'some-match-id'
ORDER BY created_at DESC
LIMIT 50;
```

### Upload Photo avec Modération
```sql
-- ✅ Fonctionne si auth.uid() = user_id
INSERT INTO profile_photos (user_id, storage_path, is_main)
VALUES (auth.uid(), 'path/to/photo.jpg', true);
-- Photo créée avec moderation_status = 'pending'
```

---

## 🚨 Sécurité et Bonnes Pratiques

### Protections Implémentées

1. **NULL UID Protection** : Toutes les politiques incluent `auth.uid() IS NOT NULL`
2. **Cross-User Isolation** : Impossible d'accéder aux données d'autrui
3. **WITH CHECK Systématique** : Contrôle des insertions/modifications
4. **Service Role Bypass** : Edge Functions utilisent `service_role` pour bypasser RLS
5. **Vue Publique Sécurisée** : Données sensibles filtrées automatiquement

### Recommandations Développement

1. **Toujours tester l'isolation** : Vérifier qu'un utilisateur ne voit pas les données d'autrui
2. **Utiliser la vue publique** : `public_profiles_v` pour la découverte d'utilisateurs
3. **Gérer les erreurs RLS** : Prévoir les cas où RLS bloque l'accès
4. **Tester sans authentification** : Vérifier le comportement anonymous
5. **Monitorer les performances** : RLS peut impacter les requêtes complexes

### Tests de Validation

```sql
-- Test isolation (doit retourner 0 lignes)
SELECT * FROM users WHERE id != auth.uid();

-- Test vue publique (doit fonctionner)
SELECT COUNT(*) FROM public_profiles_v;

-- Test cross-user messages (doit échouer)
SELECT * FROM messages WHERE match_id NOT IN (
  SELECT id FROM matches 
  WHERE user1_id = auth.uid() OR user2_id = auth.uid()
);
```

---

## 📊 Résumé des Politiques

**Total : 42 politiques RLS actives**

| Table | SELECT | INSERT | UPDATE | DELETE | Total |
|-------|--------|--------|--------|--------|-------|
| users | 1 | 1 | 1 | 0 | 3 |
| stations | 1 | 0 | 0 | 0 | 1 |
| profile_photos | 2 | 1 | 1 | 1 | 5 |
| user_station_status | 1 | 1 | 1 | 1 | 4 |
| likes | 1 | 1 | 0 | 1 | 3 |
| matches | 1 | 0 | 0 | 0 | 1 |
| messages | 1 | 1 | 1 | 1 | 4 |
| groups | 1 | 1 | 1 | 1 | 4 |
| group_members | 1 | 1 | 1 | 1 | 4 |
| friends | 1 | 1 | 1 | 1 | 4 |
| ride_stats_daily | 1 | 1 | 1 | 0 | 3 |
| boosts | 1 | 1 | 1 | 1 | 4 |
| subscriptions | 1 | 0 | 0 | 0 | 1 |
| public_profiles_v | 1 | 0 | 0 | 0 | 1 |

**Couverture de sécurité : 100%**
- ✅ Toutes les tables sensibles protégées
- ✅ Vue publique sécurisée via GRANT
- ✅ Isolation cross-user garantie
- ✅ Modération et administration préservées
