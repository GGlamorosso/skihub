# CrewSnow Data Model

Un modèle de données complet et optimisé pour une application de rencontres entre skieurs/snowboarders, conçu avec PostgreSQL et Supabase.

## 🎯 Vue d'ensemble

Ce modèle de données implémente toutes les fonctionnalités nécessaires pour CrewSnow :
- **Profils utilisateurs** avec préférences de ski/snowboard
- **Géolocalisation** avec PostGIS pour le matching par stations
- **Système de swipe/match** avec détection automatique des matches
- **Chat** entre utilisateurs matchés
- **Tracking d'activités** pour gamification
- **Fonctionnalités premium** avec monétisation
- **Groupes/crews** pour activités collectives

## 📁 Structure des fichiers

```
supabase/
├── migrations/
│   ├── 20241113_create_core_data_model.sql    # Modèle principal
│   └── 20241113_utility_functions.sql          # Fonctions utilitaires
└── seed/
    ├── 01_seed_stations.sql                    # Stations de ski européennes
    ├── 02_seed_test_users.sql                  # Utilisateurs de test
    └── 03_test_queries.sql                     # Tests et exemples
```

## 🚀 Installation

### 1. Exécuter les migrations

```bash
# Dans votre projet Supabase
supabase db reset

# Ou appliquer manuellement
psql -d your_database < migrations/20241113_create_core_data_model.sql
psql -d your_database < migrations/20241113_utility_functions.sql
```

### 2. Charger les données de test

```bash
psql -d your_database < seed/01_seed_stations.sql
psql -d your_database < seed/02_seed_test_users.sql
```

### 3. Tester le modèle

```bash
psql -d your_database < seed/03_test_queries.sql
```

## 📋 Tables principales

### 👤 Users
Table centrale des profils utilisateurs.

**Champs clés :**
- `level`: Niveau de ski (beginner, intermediate, advanced, expert)
- `ride_styles[]`: Styles préférés (alpine, freestyle, freeride, etc.)
- `languages[]`: Langues parlées pour matching international
- `is_premium`: Accès aux fonctionnalités premium

**Index optimisés :**
- Recherche par pseudonyme
- Filtrage par arrays (langues, styles)
- Segmentation premium

### 🏔️ Stations
Référentiel des stations de ski avec données géospatiales.

**Fonctionnalités :**
- Support PostGIS avec géométries Point(4326)
- Index spatial GIST pour recherches par rayon
- Stations européennes pré-chargées

### 📍 User_station_status
Indique où et quand les utilisateurs skient.

**Logique métier :**
- Matching par proximité géographique et temporelle
- Rayon configurable par utilisateur
- Contraintes sur les dates (cohérence temporelle)

### 💕 Likes & Matches
Système de swipe avec détection automatique des matches.

**Fonctionnalités :**
- Trigger automatique de création de match sur like mutuel
- Contrainte d'unicité pour éviter les doublons
- Ordre canonique des utilisateurs dans les matches

### 💬 Messages
Chat entre utilisateurs matchés.

**Performance :**
- Index composite (match_id, created_at DESC) pour pagination
- Contraintes sur la taille des messages
- Support de différents types de messages

### 📊 Ride_stats_daily
Tracking quotidien des activités.

**Métriques :**
- Distance, vitesse max, dénivelé, temps de ski, nombre de descentes
- Support multi-sources (GPS, Strava, manuel)
- Contraintes réalistes sur les valeurs

## 🔧 Fonctions utilitaires

### Matching et géolocalisation

```sql
-- Trouver des utilisateurs potentiels
SELECT * FROM get_potential_matches('user-uuid', 20);

-- Chercher dans un rayon géographique
SELECT * FROM find_users_at_station('station-uuid', 50);

-- Stations proches d'un point
SELECT * FROM find_nearby_stations(45.2979, 6.5799, 100);
```

### Statistiques utilisateur

```sql
-- Résumé des statistiques de ski
SELECT * FROM get_user_ride_stats_summary('user-uuid', 30);

-- Vérifier le premium actif
SELECT user_has_active_premium('user-uuid');
```

### Nettoyage automatique

```sql
-- Nettoyer les données expirées
SELECT cleanup_expired_data();
```

## 🔍 Vues prédéfinies

### active_users_with_location
Utilisateurs actifs avec leur localisation actuelle.

### recent_matches_with_users
Matches récents avec informations utilisateurs et dernier message.

## ⚡ Optimisations de performance

### Index stratégiques
- **PostGIS GIST** : Requêtes géospatiales en O(log n)
- **GIN sur arrays** : Filtrage multi-tags rapide
- **Composites** : Pagination et tri optimisés

### Contraintes strictes
- Validation des données à la source
- Prévention des états incohérents
- Types énumérés pour éviter les erreurs

### Triggers intelligents
- Création automatique des matches
- Mise à jour des timestamps
- Logique métier au niveau base

## 🔐 Sécurité (RLS)

Policies Row Level Security configurées :
- Utilisateurs : accès à leurs propres données
- Messages : visibles aux participants du match
- Stations : lecture publique pour tous
- Matches : visibles aux participants uniquement

## 📈 Scalabilité

### Design choisi pour la croissance
- **UUID** partout : distribution, sécurité
- **Timestamps UTC** : cohérence mondiale
- **Arrays optimisés** : évitent les jointures coûteuses
- **Partitioning ready** : ride_stats_daily par date

### Métriques de performance attendues
- **Swipe** : < 200ms (index sur likes)
- **Chat pagination** : < 100ms (index composite)
- **Géo-matching** : < 300ms (GIST spatial)
- **Stats utilisateur** : < 150ms (index date DESC)

## 🧪 Données de test

### Utilisateurs pré-créés
- **alpine_alex** : Skieur avancé premium
- **powder_marie** : Monitrice experte
- **beginner_tom** : Débutant cherchant des conseils
- **park_rider_sam** : Freestyler park
- **touring_julie** : Passionnée de ski de rando

### Stations incluses
60+ stations européennes majeures :
- France : 3 Vallées, Espace Killy, Paradiski, Chamonix...
- Suisse : Zermatt, St. Moritz, Verbier, Davos...
- Autriche : St. Anton, Kitzbühel, Innsbruck...
- Italie : Cortina, Val Gardena, Cervinia...

## 📱 Intégration API

### Requêtes types pour l'app

```sql
-- 1. Profil utilisateur complet
SELECT u.*, s.name as current_station 
FROM users u 
LEFT JOIN user_station_status uss ON u.id = uss.user_id AND uss.is_active = true
LEFT JOIN stations s ON uss.station_id = s.id 
WHERE u.id = $1;

-- 2. Liste de swipe
SELECT * FROM get_potential_matches($1, 20);

-- 3. Matches avec dernier message
SELECT * FROM recent_matches_with_users 
WHERE user1_id = $1 OR user2_id = $1;

-- 4. Messages d'un match
SELECT msg.*, u.username 
FROM messages msg 
JOIN users u ON msg.sender_id = u.id 
WHERE msg.match_id = $1 
ORDER BY msg.created_at DESC 
LIMIT 50;
```

### Real-time subscriptions Supabase

```typescript
// Nouveaux matches
supabase
  .channel('matches')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'matches',
    filter: `user1_id=eq.${userId}`,
  }, handleNewMatch)
  .subscribe()

// Messages en temps réel
supabase
  .channel(`match:${matchId}`)
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'messages',
    filter: `match_id=eq.${matchId}`,
  }, handleNewMessage)
  .subscribe()
```

## 🔄 Maintenance

### Tâches recommandées

```sql
-- Quotidien : nettoyage automatique
SELECT cleanup_expired_data();

-- Hebdomadaire : stats et vacuum
ANALYZE users, matches, messages, user_station_status;
VACUUM ANALYZE ride_stats_daily;

-- Mensuel : archivage des anciennes données
DELETE FROM user_station_status 
WHERE date_to < CURRENT_DATE - INTERVAL '90 days' AND is_active = false;
```

### Monitoring

```sql
-- Performance des index
SELECT schemaname, tablename, indexname, idx_scan 
FROM pg_stat_user_indexes 
WHERE schemaname = 'public' 
ORDER BY idx_scan DESC;

-- Taille des tables
SELECT 
    tablename,
    pg_size_pretty(pg_total_relation_size(tablename)) as size
FROM pg_tables 
WHERE schemaname = 'public' 
ORDER BY pg_total_relation_size(tablename) DESC;
```

## 🏗️ Extensions futures

### Prêt pour l'évolution
- **Notifications push** : tables events/notifications
- **Modération avancée** : ML scoring, reports
- **Analytics** : vues matérialisées pour BI
- **Multi-tenant** : partition par région/pays
- **ML recommendations** : embedding vectors

### Migration vers pivot si nécessaire
Les arrays peuvent être remplacés par des tables pivot sans casser l'API :

```sql
-- user_languages (si stats fines nécessaires)
CREATE TABLE user_languages (
    user_id UUID REFERENCES users(id),
    language_code language_code,
    proficiency INTEGER DEFAULT 5,
    PRIMARY KEY (user_id, language_code)
);
```

---

## 📞 Support

Pour toute question sur l'implémentation :
1. Consulter les scripts de test
2. Vérifier les contraintes et triggers
3. Analyser les plans d'exécution avec EXPLAIN

Le modèle est conçu pour être **robuste**, **performant** et **évolutif** dès le premier utilisateur jusqu'à des millions d'utilisateurs. 🚀
