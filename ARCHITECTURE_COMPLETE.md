# 🏗️ Architecture Complète - CrewSnow

## 📋 Vue d'ensemble

**CrewSnow** est une application de rencontres pour skieurs et snowboarders, construite avec :
- **Frontend** : Flutter (iOS/Android)
- **Backend** : Supabase (PostgreSQL + PostGIS, Edge Functions, Realtime)
- **Architecture** : Feature-based avec Riverpod (state management)

**État actuel** : ✅ 99% complété, prêt pour bêta

---

## 🎯 Stack Technologique

### Frontend (Flutter)
- **Framework** : Flutter 3.13+
- **Language** : Dart 3.1+
- **State Management** : Riverpod 2.4+
- **Navigation** : GoRouter 13.2+
- **Architecture** : Feature-based (features/), avec séparation controllers/services/models

### Backend (Supabase)
- **Base de données** : PostgreSQL 17 avec PostGIS
- **Edge Functions** : Deno (TypeScript)
- **Authentification** : Supabase Auth
- **Storage** : Supabase Storage (photos de profil)
- **Realtime** : Supabase Realtime (messages, matches)
- **RLS** : Row Level Security activé sur toutes les tables

### Services Externes
- **Paiements** : Stripe (subscriptions, boosts)
- **Analytics** : PostHog
- **Crash Reporting** : Firebase Crashlytics
- **Notifications Push** : Firebase Cloud Messaging
- **Modération** : n8n workflows (webhooks)

---

## 📁 Structure du Projet

```
crewsnow/
├── frontend/                    # Application Flutter
│   ├── lib/
│   │   ├── features/            # Features organisées par domaine
│   │   │   ├── auth/           # Authentification
│   │   │   ├── onboarding/     # Onboarding utilisateur
│   │   │   ├── feed/           # Swipe/matching
│   │   │   ├── chat/           # Messagerie
│   │   │   ├── profile/        # Profil utilisateur
│   │   │   ├── premium/        # Abonnements Stripe
│   │   │   ├── tracking/       # GPS & statistiques
│   │   │   ├── privacy/        # GDPR, consentements
│   │   │   └── safety/         # Modération, signalement
│   │   ├── services/           # Services partagés
│   │   ├── models/             # Modèles de données
│   │   ├── router/             # Navigation (GoRouter)
│   │   ├── theme/              # Thème & design
│   │   └── utils/              # Utilitaires
│   ├── android/                # Configuration Android
│   ├── ios/                    # Configuration iOS
│   └── pubspec.yaml           # Dépendances Flutter
│
├── supabase/                    # Backend Supabase
│   ├── migrations/             # Migrations SQL (ordre chronologique)
│   │   ├── 20241113_*.sql     # Semaine 1-2 : Schéma de base
│   │   ├── 20241114_*.sql     # Semaine 3-4 : Fonctions utilitaires
│   │   ├── 20241115_*.sql     # Semaine 3-4 : Seed data
│   │   ├── 20241116_*.sql     # Semaine 3-4 : RLS & indexes
│   │   ├── 20241117-23_*.sql  # Semaine 3-4 : RLS finitions
│   │   ├── 20250110_*.sql     # Semaine 5-10 : Features avancées
│   │   └── 20250114-17_*.sql  # Corrections & ajouts
│   ├── functions/              # Edge Functions Deno
│   │   ├── match-candidates/  # Matching optimisé
│   │   ├── swipe/              # Swipe (like/dislike)
│   │   ├── swipe-enhanced/    # Swipe avec quotas
│   │   ├── gatekeeper/         # Vérification quotas
│   │   ├── send-message-enhanced/ # Messagerie
│   │   ├── stripe-webhook/    # Webhooks Stripe
│   │   ├── create-stripe-customer/ # Création client Stripe
│   │   ├── manage-consent/    # Gestion consentements GDPR
│   │   ├── export-user-data/   # Export données utilisateur
│   │   ├── delete-user-account/ # Suppression compte
│   │   ├── analytics-posthog/  # Analytics PostHog
│   │   └── webhook-n8n/        # Webhooks modération
│   ├── seed/                   # Données de test
│   │   ├── 01_seed_stations.sql
│   │   ├── 02_seed_test_users.sql
│   │   └── create_many_test_users.sql
│   ├── test/                   # Tests SQL
│   └── config.toml            # Configuration Supabase
│
├── scripts/                    # Scripts utilitaires
│   ├── deploy-all-functions.sh
│   ├── fix-all-issues.sh
│   └── ...
│
├── n8n/                        # Workflows n8n (modération)
│   ├── photo-moderation-workflow.json
│   └── message-moderation-workflow.json
│
└── docs/                       # Documentation
    ├── architecture.md
    ├── api-contracts.md
    └── ...
```

---

## 🗄️ Architecture Base de Données

### Tables Principales

#### 1. **users** (Profils utilisateurs)
```sql
- id (UUID, PK)
- username, email
- level (user_level ENUM: beginner/intermediate/advanced/expert)
- ride_styles (ride_style[]: alpine, freestyle, freeride, etc.)
- languages (language_code[]: fr, en, de, etc.)
- objectives (TEXT[]): objectifs de l'utilisateur
- bio, birth_date
- is_premium, premium_expires_at
- verified_video_status
- stripe_customer_id
- is_active, is_banned
```

#### 2. **stations** (Stations de ski)
```sql
- id (UUID, PK)
- name, country_code, region
- latitude, longitude
- geom (PostGIS POINT) -- Index GIST pour requêtes géospatiales
- elevation_m
- is_active
```

#### 3. **user_station_status** (Où et quand les utilisateurs skient)
```sql
- id (UUID, PK)
- user_id (FK → users)
- station_id (FK → stations)
- date_from, date_to (dates de séjour)
- radius_km (rayon de recherche)
- is_active
```

#### 4. **profile_photos** (Photos de profil)
```sql
- id (UUID, PK)
- user_id (FK → users)
- storage_path (chemin Supabase Storage)
- is_main, display_order
- moderation_status (pending/approved/rejected)
- moderation_reason
```

#### 5. **likes** (Actions de swipe)
```sql
- id (UUID, PK)
- liker_id, liked_id (FK → users)
- is_like (true = like, false = pass)
- created_at
- UNIQUE(liker_id, liked_id) -- Un seul swipe par paire
```

#### 6. **matches** (Matches mutuels)
```sql
- id (UUID, PK)
- user1_id, user2_id (FK → users, ordre canonique)
- matched_at_station_id (FK → stations)
- is_active
- last_message_at
- UNIQUE(user1_id, user2_id) -- Un seul match par paire
```

#### 7. **messages** (Chat entre utilisateurs matchés)
```sql
- id (UUID, PK)
- match_id (FK → matches)
- sender_id (FK → users)
- content (TEXT, max 2000 chars)
- message_type (text/image/system)
- moderation_status
- read_at
- created_at
- Index composite (match_id, created_at DESC) pour pagination
```

#### 8. **daily_usage** (Quotas quotidiens)
```sql
- id (UUID, PK)
- user_id (FK → users)
- date (DATE)
- swipe_count, message_count
- UNIQUE(user_id, date)
```

#### 9. **subscriptions** (Abonnements Stripe)
```sql
- id (UUID, PK)
- user_id (FK → users)
- stripe_subscription_id
- status (active/canceled/etc.)
- current_period_start, current_period_end
- amount_cents, currency
```

#### 10. **groups** & **group_members** (Mode Crew - groupes 2-8 personnes)
```sql
groups: id, name, description, max_members, created_by
group_members: group_id, user_id, role (owner/admin/member)
```

### Fonctions SQL Principales

#### Matching
- `get_candidate_scores(p_user_id UUID)` : Calcule les scores de compatibilité
- `get_optimized_candidates(p_user_id, p_limit, use_cache)` : Retourne les candidats optimisés avec score_breakdown
- `get_potential_matches(target_user_id, limit_results)` : Matching basique (fallback)

#### Géospatial
- `find_users_at_station(station_id, radius_km, date_from, date_to)` : Utilisateurs dans un rayon
- `find_nearby_stations(latitude, longitude, radius_km)` : Stations proches d'un point

#### Quotas
- `check_and_increment_usage(p_user, p_limit_swipe, p_limit_message, p_count_swipe, p_count_message)` : Vérifie et incrémente les quotas

#### Statistiques
- `get_user_ride_stats_summary(user_id, days_back)` : Statistiques de ski

### Indexes Optimisés

```sql
-- PostGIS pour requêtes géospatiales
CREATE INDEX idx_stations_geom ON stations USING GIST(geom);

-- GIN pour arrays (filtrage rapide)
CREATE INDEX idx_users_ride_styles ON users USING GIN(ride_styles);
CREATE INDEX idx_users_languages ON users USING GIN(languages);

-- Composite pour pagination messages
CREATE INDEX idx_messages_match_created ON messages(match_id, created_at DESC);

-- Performance matching
CREATE INDEX idx_user_station_composite ON user_station_status(user_id, station_id) WHERE is_active = true;
```

### Row Level Security (RLS)

**Toutes les tables ont RLS activé** avec des policies spécifiques :
- **users** : Lecture publique limitée, modification uniquement par le propriétaire
- **messages** : Uniquement les participants du match
- **likes** : Uniquement le liker et le liked
- **matches** : Uniquement user1_id et user2_id
- **profile_photos** : Publique si `moderation_status = 'approved'`, propriétaire voit tout

---

## ⚡ Edge Functions (Deno/TypeScript)

### 1. **match-candidates** (Matching optimisé)
- **Endpoint** : `/match-candidates`
- **Méthode** : POST
- **Fonction** : Appelle `get_optimized_candidates()` avec pagination
- **Retourne** : Liste de candidats avec score_breakdown, pagination cursor

### 2. **swipe** / **swipe-enhanced** (Actions de swipe)
- **Endpoint** : `/swipe` ou `/swipe-enhanced`
- **Méthode** : POST
- **Fonction** : Enregistre like/pass, crée match si mutuel
- **Quotas** : Vérifie via `gatekeeper` (swipe-enhanced)

### 3. **gatekeeper** (Vérification quotas)
- **Endpoint** : `/gatekeeper`
- **Méthode** : POST
- **Fonction** : Vérifie quotas quotidiens (swipes/messages), appelle fonction cible si autorisé
- **Quotas** : 10 swipes/jour (free), 100 (premium) | 50 messages/jour (free), 500 (premium)

### 4. **send-message-enhanced** (Messagerie)
- **Endpoint** : `/send-message-enhanced`
- **Méthode** : POST
- **Fonction** : Envoie message avec modération, vérifie quotas

### 5. **stripe-webhook** / **stripe-webhook-enhanced** (Webhooks Stripe)
- **Endpoint** : `/stripe-webhook` ou `/stripe-webhook-enhanced`
- **Méthode** : POST
- **Fonction** : Traite événements Stripe (subscription.created, invoice.paid, etc.)
- **Idempotence** : Table `processed_events` pour éviter doublons

### 6. **create-stripe-customer** (Création client Stripe)
- **Endpoint** : `/create-stripe-customer`
- **Méthode** : POST
- **Fonction** : Crée un client Stripe et lie à l'utilisateur

### 7. **manage-consent** (GDPR - Consentements)
- **Endpoint** : `/manage-consent`
- **Méthode** : POST
- **Fonction** : Gère les consentements (gps, analytics, marketing, etc.)

### 8. **export-user-data** (GDPR - Export données)
- **Endpoint** : `/export-user-data`
- **Méthode** : POST
- **Fonction** : Exporte toutes les données d'un utilisateur (JSON)

### 9. **delete-user-account** (GDPR - Suppression compte)
- **Endpoint** : `/delete-user-account`
- **Méthode** : POST
- **Fonction** : Supprime toutes les données utilisateur (anonymisation)

### 10. **analytics-posthog** (Analytics)
- **Endpoint** : `/analytics-posthog`
- **Méthode** : POST
- **Fonction** : Envoie événements à PostHog

### 11. **webhook-n8n** (Modération)
- **Endpoint** : `/webhook-n8n`
- **Méthode** : POST
- **Fonction** : Reçoit résultats modération depuis n8n

---

## 📱 Architecture Flutter

### Pattern : Feature-Based Architecture

Chaque feature est organisée en :
```
features/
└── feature_name/
    ├── controllers/     # State management (Riverpod)
    ├── presentation/    # Écrans UI
    ├── services/        # Services spécifiques à la feature
    ├── models/          # Modèles de données
    └── widgets/         # Widgets réutilisables
```

### Features Principales

#### 1. **auth** (Authentification)
- **Controllers** : `auth_controller.dart` (gère login/signup/logout)
- **Écrans** : `auth_screen.dart`, `login_screen.dart`, `signup_screen.dart`
- **Service** : Utilise `SupabaseService.instance.auth`

#### 2. **onboarding** (Onboarding)
- **Controllers** : `onboarding_controller.dart` (gère le flow d'onboarding)
- **Écrans** : 
  - `splash_screen.dart` (vérifie auth)
  - `name_screen.dart`, `age_screen.dart`, `photo_screen.dart`
  - `level_style_screen.dart`, `objectives_screen.dart`, `languages_screen.dart`
  - `gps_tracker_screen.dart`, `station_dates_screen.dart`
  - `onboarding_complete_screen.dart`

#### 3. **feed** (Swipe/Matching)
- **Controllers** : `feed_controller.dart` (gère les candidats, swipe)
- **Écrans** : `swipe_screen.dart`, `candidate_details_screen.dart`, `match_modal.dart`
- **Services** : `match_service.dart`, `enhanced_match_service.dart`
- **Appels** : Edge Function `match-candidates`, `swipe-enhanced`

#### 4. **chat** (Messagerie)
- **Controllers** : `chat_controller.dart`, `matches_controller.dart`
- **Écrans** : `matches_screen.dart`, `chat_screen.dart`
- **Services** : `chat_service.dart`, `enhanced_message_service.dart`
- **Realtime** : Abonnement Supabase Realtime sur `messages` et `matches`

#### 5. **profile** (Profil utilisateur)
- **Controllers** : `profile_controller.dart`, `photos_controller.dart`
- **Écrans** : `profile_screen.dart`, `edit_profile_screen.dart`, `photo_gallery_screen.dart`
- **Services** : `user_service.dart`, `photo_repository.dart`

#### 6. **premium** (Abonnements)
- **Controllers** : `premium_controller.dart`
- **Écrans** : `premium_screen.dart`, `boost_screen.dart`, `quota_modal.dart`
- **Services** : `stripe_service.dart`, `premium_repository.dart`, `quota_service.dart`
- **Intégration** : Stripe SDK + Edge Functions

#### 7. **tracking** (GPS & Statistiques)
- **Controllers** : `tracking_controller.dart`, `stats_controller.dart`
- **Écrans** : `tracker_screen.dart`, `stats_screen.dart`
- **Services** : `tracking_service.dart` (GPS, background location)

#### 8. **privacy** (GDPR)
- **Services** : `privacy_service.dart`, `video_verification_service.dart`
- **Écrans** : `privacy_settings_screen.dart`, `video_verification_screen.dart`
- **Appels** : Edge Functions `manage-consent`, `export-user-data`, `delete-user-account`

#### 9. **safety** (Sécurité & Modération)
- **Services** : `content_moderation_service.dart`
- **Écrans** : `safety_center.dart`
- **Intégration** : n8n workflows via webhooks

### Services Partagés (`lib/services/`)

#### **supabase_service.dart**
- Singleton pour gérer la connexion Supabase
- Helpers : `auth`, `from()`, `rpc()`, `storage`, `functions`, `realtime`

#### **match_service.dart**
- Appelle Edge Function `match-candidates`
- Gère pagination, filtres

#### **chat_service.dart**
- Gère messages, abonnements Realtime
- Pagination messages

#### **user_service.dart**
- CRUD utilisateurs
- Récupération profil

#### **photo_repository.dart**
- Upload photos vers Supabase Storage
- Gestion modération photos

#### **stripe_service.dart**
- Intégration Stripe SDK
- Création payment intents, subscriptions

#### **tracking_service.dart**
- GPS tracking (foreground/background)
- Envoie position à Supabase

#### **firebase_service.dart**
- Initialisation Firebase
- Crashlytics, Cloud Messaging

#### **moderation_service.dart**
- Gère modération photos/messages
- Webhooks n8n

### Navigation (GoRouter)

**Fichier** : `lib/router/app_router.dart`

**Routes principales** :
- `/` : Splash (vérifie auth)
- `/auth`, `/login`, `/signup` : Authentification
- `/onboarding/*` : Flow onboarding
- `/feed` : Swipe (écran principal)
- `/matches` : Liste des matches
- `/chat/:matchId` : Chat avec un match
- `/profile` : Profil utilisateur
- `/tracker` : GPS tracking
- `/premium` : Abonnements

**Guard** : Vérifie si utilisateur est authentifié et a complété l'onboarding

### State Management (Riverpod)

**Pattern** : Providers pour chaque feature

**Exemples** :
- `authControllerProvider` : État authentification
- `feedControllerProvider` : État feed (candidats, filtres)
- `chatControllerProvider` : État chat (messages, matches)
- `profileControllerProvider` : État profil

**Code généré** : Utilise `riverpod_generator` pour générer les providers automatiquement

---

## 🔄 Flux de Données

### 1. Authentification
```
Flutter → SupabaseService.auth.signIn()
         ↓
Supabase Auth → Crée session JWT
         ↓
Flutter → Stocke token localement
         ↓
Toutes requêtes → Header Authorization: Bearer <token>
```

### 2. Matching (Swipe)
```
Flutter → Edge Function match-candidates
         ↓
Edge Function → Appelle get_optimized_candidates()
         ↓
PostgreSQL → Retourne candidats avec scores
         ↓
Edge Function → Retourne JSON à Flutter
         ↓
Flutter → Affiche candidats dans SwipeScreen
```

### 3. Swipe (Like/Pass)
```
Flutter → Edge Function swipe-enhanced
         ↓
Edge Function → Appelle gatekeeper (vérifie quota)
         ↓
gatekeeper → Vérifie daily_usage
         ↓
Si OK → swipe-enhanced → INSERT INTO likes
         ↓
Trigger SQL → Crée match si mutuel
         ↓
Realtime → Notifie les deux utilisateurs
```

### 4. Messagerie
```
Flutter → Edge Function send-message-enhanced
         ↓
Edge Function → Vérifie match existe, quotas
         ↓
INSERT INTO messages
         ↓
Realtime → Broadcast à participants du match
         ↓
Flutter → Reçoit message via subscription Realtime
```

### 5. Paiements Stripe
```
Flutter → Stripe SDK → Crée PaymentIntent
         ↓
Stripe → Webhook → Edge Function stripe-webhook-enhanced
         ↓
Edge Function → UPDATE users.is_premium, INSERT subscriptions
         ↓
Realtime → Notifie utilisateur
```

---

## 🔐 Sécurité

### Row Level Security (RLS)
- **Toutes les tables** ont RLS activé
- **Policies** : Basées sur `auth.uid()` (utilisateur connecté)
- **Isolation** : Chaque utilisateur ne voit que ses données + données publiques autorisées

### Authentification
- **JWT** : Tokens Supabase (expiration 1h, refresh rotation)
- **Storage** : Tokens stockés localement (SecureStorage)

### Edge Functions
- **Validation** : Vérification `Authorization` header sur toutes les fonctions
- **Quotas** : Vérification via `gatekeeper` avant actions coûteuses
- **Idempotence** : Table `processed_events` pour webhooks Stripe

### Modération
- **Photos** : Modération via n8n (webhook)
- **Messages** : Modération optionnelle (flag `message_moderation_enabled`)
- **Status** : `pending` → invisible publiquement, `approved` → visible

---

## 📊 Analytics & Monitoring

### PostHog
- **Edge Function** : `analytics-posthog`
- **Événements trackés** : `user_signed_up`, `profile_completed`, `swipe_like`, `match_created`, `message_sent`, etc.
- **Triggers SQL** : Automatiques sur INSERT/UPDATE dans certaines tables

### Firebase Crashlytics
- **Crash reporting** : Erreurs Flutter automatiquement envoyées
- **Logs** : Logger personnalisé avec niveaux (debug, info, warning, error)

### Performance
- **Table** : `matching_performance_logs` (temps d'exécution fonctions)
- **Slow queries** : Table `slow_query_log` (requêtes > 1s)

---

## 🚀 Déploiement

### Migrations SQL
```bash
# Appliquer toutes les migrations
supabase db push

# Reset complet (dev uniquement)
supabase db reset
```

### Edge Functions
```bash
# Déployer toutes les fonctions
./scripts/deploy-all-functions.sh

# Ou une par une
supabase functions deploy match-candidates
supabase functions deploy gatekeeper
# etc.
```

### Flutter
```bash
cd frontend
flutter clean
flutter pub get
flutter run  # Dev
flutter build ios     # Production iOS
flutter build apk     # Production Android
```

### Variables d'Environnement

**Supabase Dashboard > Edge Functions > Secrets** :
- `STRIPE_SECRET_KEY`
- `STRIPE_WEBHOOK_SECRET`
- `N8N_WEBHOOK_URL`
- `N8N_WEBHOOK_SECRET`
- `POSTHOG_API_KEY`
- `SUPABASE_SERVICE_ROLE_KEY`

**Flutter** (`.env.dev` / `.env.prod`) :
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `STRIPE_PUBLISHABLE_KEY`

---

## 🧪 Tests & Vérifications

### Tests SQL
```sql
-- Tests RLS
SELECT run_rls_comprehensive_audit();

-- Tests Matching
SELECT run_week6_matching_tests();

-- Tests Stripe
SELECT run_week7_stripe_tests();

-- Tests GDPR
SELECT run_week9_gdpr_security_tests();
```

### Scripts Bash
```bash
# Tests production readiness
./scripts/test-week10-production-ready.sh

# Tests E2E
./scripts/test-e2e-complete-scenario.sh
```

---

## 📝 Points d'Entrée pour un Nouveau Développeur

### 1. Comprendre le Flow Utilisateur
1. **Inscription** → `features/auth/presentation/signup_screen.dart`
2. **Onboarding** → `features/onboarding/` (8 écrans)
3. **Swipe** → `features/feed/presentation/swipe_screen.dart`
4. **Match** → `features/chat/presentation/matches_screen.dart`
5. **Chat** → `features/chat/presentation/chat_screen.dart`

### 2. Comprendre le Backend
1. **Schéma DB** → `supabase/migrations/20241113_create_core_data_model.sql`
2. **Fonctions SQL** → `supabase/migrations/20241113_utility_functions.sql`
3. **Edge Functions** → `supabase/functions/`
4. **RLS** → `supabase/migrations/20241116_rls_and_indexes.sql`

### 3. Comprendre les Services
1. **SupabaseService** → `frontend/lib/services/supabase_service.dart`
2. **MatchService** → `frontend/lib/services/match_service.dart`
3. **ChatService** → `frontend/lib/services/chat_service.dart`

### 4. Fichiers Clés à Lire
- `frontend/lib/main.dart` : Point d'entrée
- `frontend/lib/router/app_router.dart` : Navigation
- `supabase/migrations/20241113_create_core_data_model.sql` : Schéma complet
- `supabase/functions/match-candidates/index.ts` : Exemple Edge Function

---

## ⚠️ Points d'Attention

### 1. Migrations SQL
- **Ordre important** : Les migrations doivent être exécutées dans l'ordre chronologique
- **Dépendances** : Certaines migrations dépendent de précédentes
- **Ne pas modifier** : Ne jamais modifier une migration déjà appliquée, créer une nouvelle

### 2. Edge Functions
- **Déploiement** : Toujours déployer après modification
- **Variables** : Vérifier que les secrets sont configurés dans Supabase Dashboard
- **Logs** : Vérifier les logs dans Supabase Dashboard > Edge Functions > Logs

### 3. Flutter
- **State Management** : Utiliser Riverpod providers, pas de setState direct
- **Navigation** : Utiliser GoRouter, pas Navigator.push
- **Services** : Utiliser les services partagés, pas d'appels Supabase directs

### 4. Base de Données
- **RLS** : Toujours tester avec un utilisateur connecté (pas service_role)
- **Indexes** : Ne pas supprimer les indexes, ils sont critiques pour performance
- **Triggers** : Certains triggers créent automatiquement des matches, messages, etc.

---

## 🔧 Configuration Requise

### Prérequis
- **Node.js** 18+ (pour Supabase CLI)
- **Flutter** 3.13+
- **Dart** 3.1+
- **Supabase CLI** : `npm install -g supabase`
- **Compte Supabase** (projets Dev & Prod)

### Setup Initial
```bash
# 1. Cloner le repo
git clone <repo-url>
cd crewsnow

# 2. Lier Supabase
supabase link --project-ref <project-ref>

# 3. Appliquer migrations
supabase db push

# 4. Déployer Edge Functions
./scripts/deploy-all-functions.sh

# 5. Configurer Flutter
cd frontend
flutter pub get
cp ../env.example.txt .env.dev
# Éditer .env.dev avec vos clés

# 6. Lancer l'app
flutter run
```

---

## 📚 Documentation Complémentaire

- **Schéma DB** : `supabase/README_DATA_MODEL.md`
- **Messagerie** : `README_MESSAGING_SYSTEM.md`
- **RLS** : `docs/RLS-POLICIES.md`
- **API Contracts** : `docs/api-contracts.md`
- **Déploiement** : `DEPLOYMENT_PROCEDURE.md`
- **Runbook** : `INCIDENT_RUNBOOK.md`

---

## 🎯 Prochaines Étapes pour Finaliser

1. ✅ **Exécuter migrations manquantes** :
   - `20250110_candidate_scoring_views.sql` (fonction `get_optimized_candidates`)
   - `20250110_daily_usage_exact_specs.sql` (fonction `check_and_increment_usage`)

2. ✅ **Créer profil utilisateur** : Exécuter `supabase/seed/FIX_ALL_ISSUES.sql`

3. ✅ **Vérifier Edge Functions** : Toutes déployées dans Supabase Dashboard

4. ✅ **Tester l'app** : Vérifier que matching, swipe, chat fonctionnent

5. ✅ **Corriger erreurs Flutter** : AssetManifest.json (non-bloquant)

---

## 📞 Support

Pour toute question :
1. Vérifier la documentation dans `docs/`
2. Vérifier les rapports dans la racine (`RAPPORT_*.md`)
3. Vérifier les scripts de test dans `scripts/`

---

**🎿 CrewSnow - Architecture prête pour la production ! ⛷️**

