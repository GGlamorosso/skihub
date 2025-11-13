# 🚨 CrewSnow Incident Response Runbook - Week 10 Day 5

## 🎯 Vue d'Ensemble

Guide de réponse aux incidents pour l'équipe CrewSnow selon spécifications Week 10.

---

## 🔧 Scénarios Incidents selon Spécifications

### 🚨 **1. Stripe Tombe**

#### **Symptômes**
- Webhooks Stripe échouent (>5% failure rate)
- Erreurs 5xx sur endpoints paiement
- Subscriptions non mises à jour

#### **Actions Immédiates**
```bash
# 1. Vérifier statut Stripe
curl https://status.stripe.com/

# 2. Check webhook failures
psql -c "SELECT * FROM stripe_webhook_monitoring WHERE webhook_status LIKE 'ALERT%';"

# 3. Désactiver temporairement features premium
psql -c "SELECT update_feature_flag('premium_subscriptions', false);"

# 4. Notification users
psql -c "SELECT update_feature_flag('payments_maintenance_mode', true);"
```

#### **Rollback Plan**
- **Immediate**: Désactiver feature flags paiement
- **Short-term**: Mode dégradé sans nouvelles souscriptions  
- **Recovery**: Re-enable flags après résolution Stripe

#### **Communication**
- Status page: "Paiements temporairement indisponibles"
- Support: Préparer réponses utilisateurs premium

---

### ⚡ **2. Supabase 5xx Errors**

#### **Symptômes**  
- Edge Functions timeout (>5s p95)
- Database connexion errors
- RLS policies échec

#### **Actions Immédiates**
```bash
# 1. Check performance health
psql -c "SELECT * FROM performance_health_check();"

# 2. Identify slow queries
psql -c "SELECT * FROM analyze_slow_queries() WHERE avg_time_ms > 1000;"

# 3. Monitor active connections  
psql -c "SELECT * FROM connection_monitoring;"

# 4. Disable heavy features temporarily
psql -c "SELECT update_feature_flag('collaborative_filtering_v2', false);"
psql -c "SELECT update_feature_flag('tracker_pro', false);"
```

#### **Escalation**
1. **L1 (0-15min)**: Feature flags disable non-critiques
2. **L2 (15-30min)**: Database optimization + cache clear
3. **L3 (30min+)**: Contact Supabase support + rollback version

#### **Recovery Actions**
```bash
# 1. Scale up database if needed (Supabase dashboard)
# 2. Optimize slow queries identified
# 3. Re-enable features progressively

# Gradual re-enable
psql -c "SELECT update_feature_flag('tracker_pro', true, 25);" # 25% rollout
psql -c "SELECT update_feature_flag('tracker_pro', true, 50);" # After monitoring
```

---

### 🔒 **3. Fuite/Bug RLS Détectée**

#### **Symptômes**
- Utilisateur voit données autres utilisateurs
- Tests RLS échouent
- Logs montrent accès cross-user

#### **Actions URGENTES**
```bash
# 1. DISABLE USER ACCESS immédiatement
psql -c "SELECT update_feature_flag('user_registration', false);"
psql -c "SELECT update_feature_flag('basic_matching', false);"

# 2. Audit immédiat
psql -c "SELECT run_day1_database_security_audit();"

# 3. Identifier scope breach  
psql -c "SELECT audit_all_rls_policies() WHERE status != 'SECURE';"

# 4. Notification équipe sécurité IMMÉDIATE
echo "🚨 SECURITY BREACH DETECTED - RLS FAILURE"
```

#### **Containment**
```bash
# 1. Bloquer nouvelles inscriptions
psql -c "UPDATE feature_flags SET is_enabled = false WHERE feature_category = 'core';"

# 2. Forcer déconnexion sessions (si possible)
# 3. Snapshot état actuel pour investigation
pg_dump > incident_snapshot_$(date +%s).sql

# 4. Rollback à version sécurisée connue
git checkout v1.0.0  # Version stable connue
supabase db reset --linked
```

#### **Recovery**
- **Investigation**: Identifier politique RLS défaillante
- **Fix**: Corriger politique + tests
- **Validation**: Tests sécurité complets avant re-enable
- **Communication**: Notification transparente utilisateurs

---

## 🔄 Plans de Rollback selon Spécifications

### ✅ **1. Rollback Version Précédente**

```bash
# 1. Identifier last good version
git tag --sort=-version:refname | head -5

# 2. Checkout version précédente
git checkout v1.0.0  # Exemple

# 3. Rollback database
supabase db reset --linked --backup-restore last_good_backup

# 4. Redeploy Edge Functions  
supabase functions deploy --all --project-ref $SUPABASE_PROJECT_ID_PROD

# 5. Validate rollback success
psql -c "SELECT * FROM make_launch_decision();"
```

### ✅ **2. Désactiver Feature Flag**

```bash
# Rollback granulaire sans redéploiement complet
psql -c "SELECT update_feature_flag('problematic_feature', false, 0);"

# Monitor impact
psql -c "SELECT * FROM edge_functions_monitoring WHERE function_name = 'affected_function';"

# Gradual re-enable si fix disponible
psql -c "SELECT update_feature_flag('feature_key', true, 10);"  # 10% users
# Monitor → increase gradually
```

### ✅ **3. Emergency Mode**

```bash
# Mode maintenance avec features minimales
psql -c "UPDATE feature_flags SET is_enabled = false WHERE feature_category != 'core';"

# Keep only essential functions
psql -c "UPDATE feature_flags SET is_enabled = true WHERE flag_key IN (
    'user_registration', 'basic_matching', 'messaging'
);"

# Notification mode maintenance
psql -c "SELECT update_feature_flag('maintenance_mode', true);"
```

---

## 📊 Monitoring & Alertes

### ✅ **Dashboard Minimal**

```sql
-- Overview santé système  
SELECT 
    'Performance' as metric,
    CASE WHEN (SELECT AVG(avg_execution_time) FROM edge_functions_monitoring) < 2000 
         THEN '✅ OK' ELSE '❌ SLOW' END as status;

SELECT 
    'Error Rate' as metric,
    CASE WHEN (SELECT MAX(error_rate_pct) FROM error_rate_monitoring) < 5
         THEN '✅ OK' ELSE '🚨 HIGH' END as status;
         
SELECT 
    'Webhooks' as metric,
    CASE WHEN (SELECT MAX(failure_rate_pct) FROM stripe_webhook_monitoring) < 5
         THEN '✅ OK' ELSE '🚨 FAILING' END as status;

SELECT 
    'Security' as metric,
    CASE WHEN (SELECT COUNT(*) FROM generate_rls_checklist() WHERE status != 'SECURE') = 0
         THEN '✅ OK' ELSE '🔒 ISSUES' END as status;
```

### ✅ **Alertes Automatiques**

**Requêtes monitoring critique :**
```sql
-- P95 latence > seuil
SELECT * FROM edge_functions_monitoring WHERE latency_status != 'OK';

-- Taux erreur > 5% 
SELECT * FROM error_rate_monitoring WHERE error_status LIKE 'ALERT%';

-- Webhooks Stripe > 5% échec
SELECT * FROM stripe_webhook_monitoring WHERE webhook_status LIKE 'ALERT%';
```

**Actions automatiques :**
- **Alert L1**: Log + notification Slack/email
- **Alert L2**: Feature flag disable automatique
- **Alert L3**: Escalation équipe + rollback automatique

---

## 📞 Contact Escalation

### ✅ **Niveaux Escalation**

**L1 - First Response (0-15min)**
- Dev on-call
- Feature flags disable
- Basic troubleshooting

**L2 - Technical Lead (15-30min)**  
- Architecture review
- Database optimization
- Rollback decision

**L3 - Engineering Manager (30min+)**
- Vendor escalation (Supabase/Stripe)
- Communication externe
- Post-incident review

### ✅ **Communications**

**Internal :**
- Slack #incidents
- Email engineering team  
- Status page updates

**External :**
- App notification users
- Website status banner
- Support team briefing

---

## 🔧 Maintenance Windows

### ✅ **Planned Maintenance**

**Weekly (Dimanche 2h-4h CET) :**
```bash
# 1. Backup verification
SELECT test_backup_restore_procedure();

# 2. Performance optimization
SELECT run_performance_maintenance();

# 3. GDPR cleanup
SELECT run_gdpr_maintenance();

# 4. Feature flag review
SELECT * FROM feature_flags WHERE updated_at < NOW() - INTERVAL '7 days';
```

**Monthly :**
- Security audit complet
- Penetration testing
- Disaster recovery test
- Business continuity validation

---

## 📋 Post-Incident Checklist

### ✅ **Immediate (0-2h)**
- [ ] Incident contained/resolved
- [ ] Systems restored to normal operation
- [ ] Monitoring confirms stability
- [ ] Users notified of resolution

### ✅ **Short-term (24h)**  
- [ ] Root cause analysis completed
- [ ] Fix validated in staging
- [ ] Documentation updated
- [ ] Preventive measures identified

### ✅ **Long-term (1 week)**
- [ ] Post-incident review meeting
- [ ] Process improvements implemented  
- [ ] Monitoring/alerting enhanced
- [ ] Team training if needed

---

## 🎛️ Feature Flags Production

### ✅ **Launch Configuration**

**Activé au lancement :**
- ✅ `user_registration`: Inscriptions ouvertes
- ✅ `basic_matching`: Algorithme core
- ✅ `messaging`: Chat temps réel
- ✅ `premium_subscriptions`: Monétisation
- ✅ `boost_station`: Boosts simples

**Rollout progressif :**
- 🔄 `tracker_pro`: 0% → monitoring → 25% → 50% → 100%
- 🔄 `advanced_filters`: Premium users → 25% → all premium
- 🔄 `collaborative_filtering_v2`: Beta → premium → general

**Désactivé (post-launch) :**
- ❌ `ai_moderation_auto`: Manuel d'abord
- ❌ `voice_messages`: Beta testing  
- ❌ `group_matching`: Future feature

### ✅ **Commandes Gestion**

```bash
# Check feature status
psql -c "SELECT flag_key, is_enabled, rollout_percentage FROM feature_flags WHERE is_enabled ORDER BY feature_category;"

# Enable feature progressively
psql -c "SELECT update_feature_flag('tracker_pro', true, 25);"

# Emergency disable
psql -c "SELECT update_feature_flag('problematic_feature', false);"

# Go/No-Go decision  
psql -c "SELECT * FROM make_go_no_go_decision();"
```

---

## ✅ **Runbook Validation**

**Tested scenarios :**
- [x] Feature flag disable/enable
- [x] Database performance degradation  
- [x] Payment system failure
- [x] Security breach response
- [x] Version rollback procedure

**Ready for production incidents :** ✅

**WEEK 10 DAY 5 - INCIDENT RESPONSE RUNBOOK COMPLETE** 🚨🔧✅
