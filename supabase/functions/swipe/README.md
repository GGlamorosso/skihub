# CrewSnow Swipe Edge Function

## 📝 Description

Cette Edge Function gère le système de swipe (like/match) de CrewSnow avec détection automatique des matches mutuels.

## 🚀 Fonctionnalités

### ✅ Authentification
- Vérification du token JWT dans l'header `Authorization`
- Validation de l'identité utilisateur via Supabase Auth
- Protection contre l'usurpation d'identité

### ✅ Validation des données
- Format UUID des identifiants utilisateur
- Vérification que `liker_id ≠ liked_id`
- Validation que l'utilisateur authentifié correspond à `liker_id`

### ✅ Gestion des blocages
- Vérification des relations bloquées via la table `friends`
- Empêche les interactions entre utilisateurs bloqués

### ✅ Transaction atomique
- Insertion idempotente des likes avec `ON CONFLICT DO NOTHING`
- Détection automatique des likes mutuels
- Création automatique des matches avec ordre canonique
- Rollback en cas d'erreur

### ✅ Rate Limiting
- Limitation à 1 like par seconde par utilisateur
- Stockage en mémoire avec nettoyage automatique
- Réponse HTTP 429 si limite dépassée

## 📡 API

### Endpoint
```
POST /functions/v1/swipe
```

### Headers requis
```
Authorization: Bearer <jwt_token>
Content-Type: application/json
```

### Request Body
```json
{
  "liker_id": "uuid-of-user-who-likes",
  "liked_id": "uuid-of-user-being-liked"
}
```

### Response Success (200)
```json
{
  "matched": true,
  "match_id": "uuid-of-created-match",
  "already_liked": false
}
```

### Response Déjà liké (200)
```json
{
  "matched": false,
  "already_liked": true
}
```

### Response Errors

#### 400 Bad Request
```json
{
  "error": "Invalid UUID format for user IDs"
}
```

#### 401 Unauthorized
```json
{
  "error": "Missing Authorization header"
}
```

#### 403 Forbidden
```json
{
  "error": "Action not allowed: user relationship blocked"
}
```

#### 429 Too Many Requests
```json
{
  "error": "Rate limit exceeded. Please wait before liking again."
}
```

#### 500 Internal Server Error
```json
{
  "error": "Database transaction failed",
  "detail": "Detailed error message"
}
```

## 🔧 Configuration

### Variables d'environnement requises
- `SUPABASE_URL`: URL de votre instance Supabase
- `SUPABASE_ANON_KEY`: Clé anonyme Supabase
- `SUPABASE_DB_URL` ou `DATABASE_URL`: URL de connexion PostgreSQL

### Dépendances
- `@supabase/supabase-js@2`: Client Supabase pour Deno
- `postgres@3.4.3`: Client PostgreSQL pour les transactions

## 📊 Logique métier

1. **Authentification** : Vérification JWT et extraction user ID
2. **Validation** : Format UUID et règles métier
3. **Blocage** : Vérification relations interdites
4. **Rate Limit** : Protection contre le spam
5. **Transaction** :
   - INSERT like avec idempotence
   - Vérification like mutuel
   - Création match si like mutuel détecté
6. **Réponse** : Statut match et détails

## 🔄 Idempotence

La fonction est complètement idempotente :
- Les likes multiples sont ignorés (`ON CONFLICT DO NOTHING`)
- Les matches multiples sont ignorés
- Réponse consistante même en cas de répétition

## ⚡ Performance

- Transaction PostgreSQL atomique
- Index utilisés pour toutes les requêtes
- Rate limiting pour éviter la surcharge
- Nettoyage automatique du cache mémoire

## 🧪 Tests

Exemple avec curl :
```bash
curl -X POST https://your-project.supabase.co/functions/v1/swipe \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "liker_id": "user-uuid-1",
    "liked_id": "user-uuid-2"
  }'
```

## 🚨 Sécurité

- 🔒 RLS appliqué via le client Supabase authentifié
- 🛡️ Protection contre l'usurpation d'identité
- 🚫 Vérification des blocages utilisateurs
- ⏱️ Rate limiting contre les abus
- 🔍 Validation stricte des entrées
