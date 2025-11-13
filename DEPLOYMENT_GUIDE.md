# 🚀 CrewSnow Swipe Function - Guide de Déploiement

## 📋 Prérequis

### 🛠️ Outils requis
- Supabase CLI installé et configuré
- Accès au projet Supabase (role Owner ou Editor)
- Deno runtime (pour les tests locaux)
- Accès aux secrets et variables d'environnement

### 🔍 Vérifications préliminaires
```bash
# Vérifier la version Supabase CLI
supabase --version

# Vérifier la connexion au projet
supabase status

# Vérifier les migrations appliquées
supabase db diff --check
```

## 🗄️ 1. Déploiement Base de Données

### Appliquer les migrations RLS
```bash
# Appliquer la migration des politiques RLS améliorées
supabase db push

# Ou appliquer manuellement la migration spécifique
supabase migration apply 20241123_enhanced_rls_policies
```

### Vérifier les politiques RLS
```sql
-- Exécuter dans l'interface SQL de Supabase
SELECT test_rls_policies();
```

## 🚀 2. Déploiement Edge Function

### Déployer la fonction
```bash
# Déployer la fonction swipe en production
supabase functions deploy swipe

# Vérifier le déploiement
supabase functions list
```

### Configuration des variables d'environnement
Dans le dashboard Supabase → Settings → Edge Functions :

```env
# ✅ Variables requises
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key-here
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here

# 🔒 Base de données (généré automatiquement)
SUPABASE_DB_URL=postgresql://postgres:[password]@db.your-project.supabase.co:5432/postgres

# 📊 Optionnel - Monitoring
SENTRY_DSN=your-sentry-dsn-if-using
LOG_LEVEL=info
```

### Permissions et sécurité
- ✅ Service Role Key configurée pour bypass RLS sur matches
- ✅ Variables d'environnement chiffrées
- ✅ Accès réseau configuré pour PostgreSQL

## 🧪 3. Tests de Déploiement

### Test local avant production
```bash
# 1. Démarrer les services locaux
supabase start

# 2. Servir la fonction localement
supabase functions serve swipe

# 3. Exécuter les tests d'intégration
deno run --allow-net --allow-env supabase/functions/swipe/integration-test.ts
```

### Test en production
```bash
# Test simple de santé
curl -X POST https://your-project.supabase.co/functions/v1/swipe \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "liker_id": "test-user-uuid",
    "liked_id": "another-user-uuid"
  }'
```

## 📊 4. Monitoring et Observabilité

### Dashboard Supabase
- 📈 **Functions** → `swipe` → Invocations, Errors, Duration
- 🗄️ **Database** → Performance, Connections, Queries
- 🔐 **Auth** → User sessions, JWT tokens

### Logs en temps réel
```bash
# Suivre les logs de la fonction
supabase functions logs swipe --follow

# Filtrer par niveau d'erreur
supabase functions logs swipe --level error
```

### Métriques clés à surveiller
- ⏱️ Temps de réponse moyen (< 500ms)
- ❌ Taux d'erreur (< 1%)
- 🔄 Throughput (requests/min)
- 💾 Utilisation mémoire
- 🔐 Erreurs d'authentification

## 🔧 5. Configuration Avancée

### Rate Limiting Production
Pour un rate limiting plus robuste, intégrer Redis :

```typescript
// Dans index.ts - configuration Redis (optionnel)
const redis = new Redis({
  url: Deno.env.get('REDIS_URL'),
  token: Deno.env.get('REDIS_TOKEN')
})

// Remplacer le Map en mémoire par Redis
async function checkRateLimit(userId: string): Promise<boolean> {
  const key = `rate_limit:${userId}`
  const current = await redis.get(key)
  
  if (current && parseInt(current) >= MAX_LIKES_PER_WINDOW) {
    return false
  }
  
  await redis.setex(key, RATE_LIMIT_WINDOW_MS / 1000, (parseInt(current || '0') + 1).toString())
  return true
}
```

### CORS Production
Configurer les origines autorisées :

```typescript
// Headers CORS restrictifs pour production
const corsHeaders = {
  'Access-Control-Allow-Origin': Deno.env.get('ALLOWED_ORIGINS') || 'https://your-app.com',
  'Access-Control-Allow-Methods': 'POST, OPTIONS',
  'Access-Control-Allow-Headers': 'authorization, content-type',
  'Access-Control-Max-Age': '3600'
}
```

## 📱 6. Documentation API pour les Équipes

### Endpoint
```
POST https://your-project.supabase.co/functions/v1/swipe
```

### Headers requis
```http
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

### Réponses

#### ✅ Succès - Premier like (200)
```json
{
  "matched": false,
  "already_liked": false
}
```

#### ✅ Succès - Match créé (200)
```json
{
  "matched": true,
  "match_id": "uuid-of-created-match"
}
```

#### ✅ Succès - Like déjà existant (200)
```json
{
  "matched": false,
  "already_liked": true
}
```

#### ❌ Erreurs
```json
// 400 - Données invalides
{
  "error": "Invalid UUID format for user IDs"
}

// 401 - Non authentifié
{
  "error": "Missing Authorization header"
}

// 403 - Non autorisé
{
  "error": "Unauthorized: can only like as authenticated user"
}

// 429 - Rate limit
{
  "error": "Rate limit exceeded. Please wait before liking again."
}

// 500 - Erreur serveur
{
  "error": "Database transaction failed",
  "detail": "Connection timeout"
}
```

### Codes de statut
| Code | Signification | Action recommandée |
|------|---------------|-------------------|
| 200 | Succès | Traiter la réponse |
| 400 | Données invalides | Vérifier les paramètres |
| 401 | Token invalide | Reconnecter l'utilisateur |
| 403 | Action interdite | Vérifier l'autorisation |
| 429 | Trop de requêtes | Implémenter retry avec backoff |
| 500 | Erreur serveur | Retry et alerter support |

## 🔄 7. Intégration Frontend/Mobile

### JavaScript/TypeScript
```typescript
interface SwipeService {
  async swipe(likerId: string, likedId: string): Promise<SwipeResponse>
}

class SupabaseSwipeService implements SwipeService {
  async swipe(likerId: string, likedId: string): Promise<SwipeResponse> {
    const { data, error } = await supabase.functions.invoke('swipe', {
      body: { liker_id: likerId, liked_id: likedId }
    })
    
    if (error) throw new Error(error.message)
    return data
  }
}

// Utilisation avec gestion d'erreur
try {
  const result = await swipeService.swipe(currentUserId, targetUserId)
  
  if (result.matched) {
    // Afficher notification de match
    showMatchNotification(result.match_id)
    // Naviguer vers l'écran de chat
    navigateToChat(result.match_id)
  } else {
    // Continuer le swipe
    showNextProfile()
  }
} catch (error) {
  if (error.status === 429) {
    // Gérer le rate limiting
    showRateLimitMessage()
  } else {
    // Autres erreurs
    showErrorMessage(error.message)
  }
}
```

### React Native
```typescript
// Hook React pour swipe
function useSwipe() {
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  
  const swipe = useCallback(async (likerId: string, likedId: string) => {
    setIsLoading(true)
    setError(null)
    
    try {
      const result = await swipeService.swipe(likerId, likedId)
      return result
    } catch (err) {
      setError(err.message)
      throw err
    } finally {
      setIsLoading(false)
    }
  }, [])
  
  return { swipe, isLoading, error }
}
```

### Flutter
```dart
class SwipeService {
  final SupabaseClient supabase;
  
  SwipeService(this.supabase);
  
  Future<SwipeResponse> swipe(String likerId, String likedId) async {
    try {
      final response = await supabase.functions.invoke('swipe', body: {
        'liker_id': likerId,
        'liked_id': likedId,
      });
      
      return SwipeResponse.fromJson(response.data);
    } on FunctionException catch (error) {
      throw SwipeException(error.details);
    }
  }
}
```

## 🚨 8. Résolution de Problèmes

### Erreurs courantes

#### Function not found (404)
```bash
# Vérifier que la fonction est déployée
supabase functions list

# Redéployer si nécessaire
supabase functions deploy swipe
```

#### Database connection errors (500)
```bash
# Vérifier les variables d'environnement
supabase secrets list

# Tester la connexion DB
supabase db ping
```

#### RLS policy violations (403)
```sql
-- Vérifier les politiques appliquées
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename IN ('likes', 'matches', 'friends');
```

#### JWT token issues (401)
```typescript
// Vérifier la validité du token côté client
const { data: user, error } = await supabase.auth.getUser(token)
if (error) {
  // Token expiré ou invalide
  await supabase.auth.refreshSession()
}
```

### Logs de debug
```bash
# Activer les logs détaillés
supabase functions logs swipe --level debug

# Suivre en temps réel
supabase functions logs swipe --follow --json
```

## ✅ 9. Checklist de Déploiement

### Pré-déploiement
- [ ] Tests locaux passés (integration-test.ts)
- [ ] Migration RLS appliquée
- [ ] Variables d'environnement configurées
- [ ] Documentation API à jour

### Déploiement
- [ ] Fonction déployée avec `supabase functions deploy swipe`
- [ ] Variables production configurées dans dashboard
- [ ] Permissions service role validées
- [ ] CORS configuré pour domaines production

### Post-déploiement
- [ ] Test de santé réussi
- [ ] Monitoring configuré
- [ ] Logs accessibles
- [ ] Équipes frontend/mobile informées
- [ ] Documentation partagée

### Validation
- [ ] Création de likes fonctionnelle
- [ ] Création de matches automatique
- [ ] Idempotence vérifiée
- [ ] Rate limiting opérationnel
- [ ] Gestion d'erreurs correcte

---

## 📞 Support

- **Documentation**: `supabase/functions/swipe/README.md`
- **Tests**: `supabase/functions/swipe/integration-test.ts`  
- **Monitoring**: Dashboard Supabase → Functions
- **Logs**: `supabase functions logs swipe`

---

**✅ Déploiement prêt pour production avec monitoring complet !** 🚀
