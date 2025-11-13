# 💳 CrewSnow Stripe & Quotas Backend - Week 7 Documentation

## 📋 Vue d'Ensemble

Documentation backend complète pour l'intégration Stripe et le système de quotas selon spécifications Week 7.

## 🚀 Création et Gestion Produits Stripe

### ✅ **Setup Automatique**

```bash
# Exécuter script de configuration
cd stripe && node products-setup.js

# Génère automatiquement :
# - Produits : Premium, Boosts, Swipe Packs  
# - Prix : Mensuel/saisonnier/one-time
# - Configuration : stripe-config.json
```

### ✅ **Produits Créés**

| Produit | Prix | Type | Usage |
|---------|------|------|-------|
| **CrewSnow Premium** | €9.99/mois, €29.99/saison | Recurring | Accès illimité |
| **Daily Boost** | €2.99/24h | One-time | Visibilité station |
| **Weekly Boost** | €9.99/7j | One-time | Visibilité étendue |
| **Multi-Station Boost** | €19.99/72h | One-time | Multi-stations |
| **Extra Swipes Pack** | €1.99-€4.99 | One-time | 20-100 swipes |

### ✅ **Configuration Client**

```typescript
// Utiliser price IDs générés
const PRICE_IDS = {
  premium_monthly: 'price_xxx',
  premium_seasonal: 'price_yyy', 
  daily_boost: 'price_zzz',
  // ... (générés par script)
}

// Checkout session
const session = await stripe.checkout.sessions.create({
  line_items: [{
    price: PRICE_IDS.premium_monthly,
    quantity: 1,
  }],
  mode: 'subscription',
  customer: customer_id, // Lié à user
  metadata: {
    user_id: userData.user.id,
    plan_type: 'premium_monthly'
  },
  success_url: 'https://app.crewsnow.com/success',
  cancel_url: 'https://app.crewsnow.com/pricing',
})
```

## 👤 Connexion Utilisateur (Customer)

### ✅ **Edge Function create-stripe-customer**

```typescript
// Appel lors première interaction paiement
const { data } = await supabase.functions.invoke('create-stripe-customer', {
  body: {
    user_id: currentUserId,
    email: userEmail,
    name: userName
  }
})

// Retourne: { customer_id, user_linked, message }
// Stocke automatiquement dans users.stripe_customer_id
```

### ✅ **Processus Automatique**

1. **User signup** → Profile créé sans Stripe
2. **Premier paiement** → create-stripe-customer appelé  
3. **Customer Stripe** → ID conservé users.stripe_customer_id
4. **Checkout** → price_id + customer_id + metadata user_id
5. **Webhook** → Traitement automatique subscription/boost

## 🔄 Edge Webhook Sécurisé

### ✅ **Configuration Stripe Dashboard**

```
Webhook URL: https://your-project.supabase.co/functions/v1/stripe-webhook-enhanced

Événements surveillés :
✅ checkout.session.completed
✅ invoice.paid
✅ invoice.payment_failed  
✅ customer.subscription.created
✅ customer.subscription.updated
✅ customer.subscription.deleted
```

### ✅ **Sécurité**

- 🔐 **Signature verification** : `stripe.webhooks.constructEvent(body, sig, secret)`
- 🗝️ **Variables chiffrées** : `STRIPE_SECRET_KEY`, `STRIPE_WEBHOOK_SECRET`  
- 📊 **Idempotence** : Table `processed_events` avec `event.id`
- 🛡️ **Service role** : Bypass RLS pour updates automatiques

### ✅ **Lifecycle Events**

```typescript
// checkout.session.completed → Premium activation
user.is_premium = true
subscription.status = 'active'

// invoice.paid → Renewal
subscription.current_period_end = updated
user.premium_expires_at = updated

// customer.subscription.deleted → Revocation  
user.is_premium = false
user.premium_expires_at = null
subscription.status = 'canceled'
```

## ⏱️ Fonction Gatekeeper et daily_usage

### ✅ **Table daily_usage Structure Exacte**

```sql
-- Selon spécifications Week 7
CREATE TABLE daily_usage (
  user_id UUID NOT NULL REFERENCES users(id),
  date DATE NOT NULL,
  swipe_count INT NOT NULL DEFAULT 0,
  message_count INT NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, date)
);
```

### ✅ **Fonction check_and_increment_usage()**

```sql
-- Spécifications exactes avec advisory lock
CREATE OR REPLACE FUNCTION check_and_increment_usage(
    p_user UUID, 
    p_limit_swipe INT, 
    p_limit_message INT, 
    p_count_swipe INT, 
    p_count_message INT
) RETURNS BOOLEAN
```

**Fonctionnalités :**
- 🔒 **Advisory lock** : `pg_advisory_xact_lock()` évite courses critiques
- ⚡ **INSERT ... ON CONFLICT** : Création/mise à jour atomique
- ⏱️ **Window reset** : Logique daily avec CASE WHEN pattern
- ✅ **Return boolean** : true si quota OK, false si dépassé

### ✅ **Edge Function Gatekeeper**

```typescript
// Usage gatekeeper pour intercepter actions
const { data } = await supabase.functions.invoke('gatekeeper', {
  body: {
    action: 'swipe', // ou 'message'
    target_function: 'swipe', // fonction à appeler si quota OK
    payload: { liker_id: '...', liked_id: '...' },
    count: 1
  }
})

// Response si quota OK (200) :
{
  "allowed": true,
  "quota_status": {
    "current_count": 8,
    "daily_limit": 10,
    "is_premium": false, 
    "remaining": 2
  },
  "target_response": { /* réponse fonction swipe */ }
}

// Response si quota dépassé (429) :
{
  "allowed": false,
  "quota_status": {
    "current_count": 10,
    "daily_limit": 10,
    "is_premium": false,
    "remaining": 0
  },
  "reason": "Quota dépassé - swipe daily limit reached"
}
```

### ✅ **Limites par Défaut Ajustables**

| Tier | Swipes/jour | Messages/jour | Premium Check |
|------|-------------|---------------|---------------|
| **Gratuit** | 10 | 50 | `users.is_premium = false` |
| **Premium** | 100 | 500 | `users.is_premium = true + expires_at > NOW()` |

**Ajustement via table ou variables :**
```sql
-- Via table user_plan_limits (extensible)
UPDATE usage_limits_config 
SET daily_likes_limit = 15 
WHERE tier = 'free';

-- Ou via variables environnement
FREE_TIER_DAILY_SWIPES=15
PREMIUM_TIER_DAILY_SWIPES=150
```

## 🚀 Gestion des Boosts

### ✅ **Table boosts Complétée**

```sql
-- Ajout selon spécifications
ALTER TABLE boosts ADD COLUMN stripe_checkout_session_id VARCHAR(255);

-- Usage
SELECT create_boost_from_checkout(
    user_id, 
    station_id, 
    session_id,
    7, -- duration days
    amount_cents,
    'EUR'
);
```

### ✅ **Logique Matching avec Boosts**

```sql
-- Mise en avant utilisateurs boostés
SELECT * FROM get_boosted_users_at_station(station_id);

-- Filtrage dans matching algorithm
WHERE NOW() BETWEEN starts_at AND ends_at -- Boost actif
ORDER BY boost_multiplier DESC -- Priority boostés
```

### ✅ **RLS Boosts**

- ✅ **Propres boosts** : Utilisateur voit ses boosts uniquement
- ✅ **Exploration publique** : Filtre boosts actifs pour matching
- ✅ **Service role** : Gestion via webhook Stripe

## 🧪 Tests et Validation

### ✅ **Tests Unitaires Selon Spécifications**

```sql
-- Master test suite
SELECT run_week7_complete_tests();

-- Tests individuels
SELECT test_checkout_session_completed(); -- ✅ Premium activation
SELECT test_subscription_deleted();       -- ✅ Premium revocation  
SELECT test_rate_limit_function();        -- ✅ Quota enforcement
SELECT test_stripe_idempotence();         -- ✅ Double event handling
SELECT test_gatekeeper_flow();            -- ✅ 429 responses
```

### ✅ **Tests Intégration**

```bash
# Test complet système  
./scripts/test-week7-stripe-quotas.sh

# Test gatekeeper avec quota
curl -X POST .../functions/v1/gatekeeper \
  -H "Authorization: Bearer jwt" \
  -d '{
    "action": "swipe",
    "target_function": "swipe",
    "payload": {"liker_id":"...","liked_id":"..."}
  }'
```

### ✅ **Validation Idempotence**

```bash
# Envoyer même événement Stripe 2x
stripe events resend evt_xxx --webhook-endpoint https://...

# Vérifier : traité 1 seule fois
SELECT * FROM processed_events WHERE event_id = 'evt_xxx';
```

## 📊 Déploiement Production

### ✅ **Commandes**

```bash
# 1. Migrations
supabase migration apply 20250110_daily_usage_exact_specs

# 2. Edge Functions
supabase functions deploy create-stripe-customer
supabase functions deploy stripe-webhook-enhanced  
supabase functions deploy gatekeeper

# 3. Stripe setup
cd stripe && node products-setup.js

# 4. Tests validation
psql -c "SELECT run_week7_complete_tests();"
```

### ✅ **Variables Configuration**

```env
# Stripe (selon environnement dev/prod)  
STRIPE_SECRET_KEY=sk_...
STRIPE_WEBHOOK_SECRET=whsec_...
STRIPE_PUBLISHABLE_KEY=pk_...

# Prix IDs (générés par script)
STRIPE_PRICE_PREMIUM_MONTHLY=price_...
STRIPE_PRICE_DAILY_BOOST=price_...

# Quotas (ajustables)
FREE_TIER_DAILY_SWIPES=10
PREMIUM_TIER_DAILY_SWIPES=100
```

---

**✅ WEEK 7 STRIPE & QUOTAS BACKEND DOCUMENTATION COMPLÈTE** 💳📚
