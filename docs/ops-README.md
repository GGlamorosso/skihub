# 🛠️ CrewSnow - Operations Guide

Guide opérationnel pour la gestion de la base de données et des déploiements.

## 🔄 Database Reset & Seeds

### Commande db-reset (Recommandée)

```bash
# Reset complet : migrations + seeds automatiques
supabase db reset

# Avec confirmation
supabase db reset --debug
```

**Cette commande** :
1. Supprime et recrée la base locale
2. Applique toutes les migrations dans l'ordre
3. Charge automatiquement les seeds (si configurés)
4. Met à jour les fonctions et triggers
5. Régénère les types TypeScript

### Reset Manuel (si problèmes)

```bash
# 1. Reset base seulement
supabase db reset --no-seed

# 2. Charger seeds manuellement
supabase db run --file supabase/seed/01_seed_stations.sql
supabase db run --file supabase/seed/02_seed_test_users.sql

# 3. Vérifier le résultat
supabase db run --file supabase/verification_complete.sql
```

### Gestion RLS avec Seeds

Si RLS bloque les seeds en développement :

```bash
# Option 1: Reset avec service role
SUPABASE_AUTH_ADMIN_EMAIL=admin@example.com supabase db reset

# Option 2: Désactiver temporairement RLS
supabase db run --file - <<'EOF'
-- Désactiver RLS pour seeds
ALTER TABLE users DISABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos DISABLE ROW LEVEL SECURITY;
ALTER TABLE likes DISABLE ROW LEVEL SECURITY;
ALTER TABLE matches DISABLE ROW LEVEL SECURITY;
ALTER TABLE messages DISABLE ROW LEVEL SECURITY;
-- ... autres tables si nécessaire
EOF

# Charger seeds
supabase db run --file supabase/seed/01_seed_stations.sql
supabase db run --file supabase/seed/02_seed_test_users.sql

# Réactiver RLS
supabase db run --file - <<'EOF'
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE profile_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE matches ENABLE ROW LEVEL SECURITY;
ALTER TABLE messages ENABLE ROW LEVEL SECURITY;
-- ... autres tables
EOF
```

### Seeds avec Service Role

Pour éviter les problèmes RLS, utilisez le service role dans les scripts :

```sql
-- En début de seed file
SET LOCAL role TO service_role;

-- Vos données de seed
INSERT INTO users (...) VALUES (...);

-- En fin de seed file  
SET LOCAL role TO authenticated;
```

## 🔐 Point In Time Recovery (PITR)

### Status PITR

| Environnement | Status | Retention | Notes |
|---------------|--------|-----------|-------|
| **Production** | ✅ **Activé** | 7 jours | Supabase Pro automatique |
| **Development** | ❌ Non activé | N/A | Données de test seulement |

### Vérification PITR Production

```bash
# Via Supabase CLI (si connecté à PROD)
supabase inspect db --project-ref <prod-project-id>

# Via Dashboard
# Settings → Database → Point-in-time recovery
```

### Utilisation PITR

#### Restore via Dashboard
1. **Database** → **Backups**
2. Sélectionner timestamp de restauration
3. Créer nouveau projet ou écraser (attention!)

#### Restore via CLI (si disponible)
```bash
# Créer restore à un point dans le temps
supabase db restore --project-ref <project> --timestamp "2024-11-13T10:00:00Z"

# Vérifier status restore
supabase projects list
```

### Backup Strategy

#### Automatique (Supabase Pro)
- **PITR** : 7 jours de retention
- **Snapshots** : Hebdomadaires (gardés 30 jours)
- **Réplication** : Multi-région si configuré

#### Manuel (recommandé avant gros changements)
```bash
# Export schema
pg_dump --schema-only --no-owner --no-acl $DATABASE_URL > backup_schema.sql

# Export data critique
pg_dump --data-only --table=users --table=matches $DATABASE_URL > backup_data.sql

# Backup complet (petit dataset)
pg_dump --clean --no-owner --no-acl $DATABASE_URL > backup_full.sql
```

## 🚀 Déploiements

### Stratégie de Déploiement

#### Development (Auto)
- **Trigger** : Push sur `main`
- **Actions** : `supabase db push`
- **Validations** : Tests automatiques
- **Rollback** : `git revert` puis redéploiement

#### Production (Manuel + Approval)
- **Trigger** : Tag `v*.*.*`
- **Actions** : Backup → Deploy → Verify
- **Validations** : Smoke tests production
- **Rollback** : PITR ou backup restore

### Pre-Deploy Checklist

#### Development
```bash
# 1. Tests locaux
supabase db reset
./scripts/verify-database.sh

# 2. Simulation migration
supabase db diff --use-migra

# 3. Push si OK
supabase db push
```

#### Production
```bash
# 1. Backup manuel (précaution)
pg_dump $PROD_DATABASE_URL > pre_deploy_backup.sql

# 2. Deploy via tag
git tag v0.1.1-db
git push origin v0.1.1-db

# 3. Monitorer GitHub Actions
# 4. Vérifier post-deploy via dashboard
```

## 🔧 Troubleshooting

### Erreurs Communes

#### Migration Failed
```bash
# Voir erreurs détaillées
supabase db diff --debug

# Reset et retry
supabase db reset
supabase db push
```

#### RLS Blocking Operations
```bash
# Check policies actives
SELECT schemaname, tablename, policyname, permissive, cmd 
FROM pg_policies 
WHERE schemaname = 'public';

# Bypass temporaire (DEV ONLY)
SET LOCAL role TO service_role;
-- Your operation
RESET role;
```

#### Performance Issues
```bash
# Analyser queries lentes
SELECT query, mean_exec_time, calls
FROM pg_stat_statements 
ORDER BY mean_exec_time DESC 
LIMIT 10;

# Recomputer stats
ANALYZE;

# Check index usage
SELECT schemaname, tablename, indexname, idx_scan
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;
```

### Rollback Procedures

#### Development
```bash
# 1. Identifier last known good state
git log --oneline --grep="db:"

# 2. Revert problematic commit
git revert <commit-hash>

# 3. Redeploy
git push origin main
```

#### Production
```bash
# Option 1: PITR (recommandé si < 7 jours)
# Via Supabase Dashboard → Database → Backups

# Option 2: Backup restore
psql $PROD_DATABASE_URL < backup_full.sql

# Option 3: Migration rollback (si supporté)
supabase migration down <migration-name>
```

## 📊 Monitoring

### Health Checks

#### Automatique (CI/CD)
- **Daily** : GitHub Actions health check (3 AM UTC)
- **Deploy** : Post-deployment verification
- **Alert** : Discord/Slack notifications si échec

#### Manuel
```bash
# Quick health check
supabase db run --file - <<< "SELECT 'Database OK' as status;"

# Comprehensive check
./scripts/verify-database.sh

# Performance metrics
supabase db run --file supabase/verification_complete.sql
```

### Métriques à Surveiller

#### Performance
- Query response times (< 300ms target)
- Connection pool usage (< 80%)
- Index hit ratio (> 95%)

#### Business
- New user registrations
- Match success rate
- Message activity
- Premium conversion

#### Infrastructure
- Database size growth
- Storage usage (photos)
- Edge Function invocations
- Realtime connections

## 🔒 Security

### Accès Production
- **Admin** : Supabase service role seulement
- **Deploy** : GitHub Actions avec secrets
- **Backup** : Automated + manual via service account

### Audit Trail
- Database changes via migrations (versioned)
- Deploy history via GitHub Actions
- User actions via event_log table (si implémenté)

### Security Checklist
- [ ] RLS activé sur toutes les tables
- [ ] Service role accès limité
- [ ] Secrets GitHub secure
- [ ] HTTPS only (Supabase default)
- [ ] API rate limiting configuré

---

## 📞 Support

### Escalation
1. **GitHub Issues** : Bugs et features
2. **Supabase Support** : Infrastructure issues
3. **On-call** : Production critical issues

### Resources
- [Supabase CLI Docs](https://supabase.com/docs/guides/cli)
- [PostgreSQL PITR](https://www.postgresql.org/docs/current/continuous-archiving.html)
- [CrewSnow DB Schema](../supabase/README_DATA_MODEL.md)

**Last Updated** : 2024-11-13  
**Version** : v0.1.0-db
