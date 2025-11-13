# 🚀 CrewSnow Deployment Procedure - Week 10

## 📋 Comment Déployer une Version selon Spécifications

### ✅ **Development Deployment (Branche main)**

```bash
# 1. Développement local
git checkout main  
git pull origin main

# 2. Tests locaux
supabase start
supabase db reset
supabase db push
./scripts/test-week9-gdpr-compliance.sh

# 3. Push vers main → déclenche pipeline automatique
git add .
git commit -m "feat: nouvelle fonctionnalité"  
git push origin main

# 4. Monitoring pipeline GitHub Actions
# ✅ Frontend tests (Flutter lint + tests)
# ✅ Backend tests (migrations + security audit)
# ✅ Deployment to dev environment
# ✅ Smoke tests dev
```

### ✅ **Production Deployment (Tag vX.Y.Z)**

```bash
# 1. Préparation release  
git checkout main
git pull origin main

# 2. Validation finale tous tests
./scripts/test-week8-launch-ready.sh
psql -c "SELECT * FROM make_go_no_go_decision();"

# 3. Créer tag version selon spécifications
git tag v1.0.0
git push origin v1.0.0

# 4. Pipeline production automatique se déclenche
# ✅ Pre-production validation (tests complets)
# ✅ Production backup (sécurité)  
# ✅ Migrations application
# ✅ Edge Functions deployment
# ✅ Mobile app build
# ✅ Post-deployment validation
# ✅ GitHub Release création
```

### ✅ **Rollback Procedure**

```bash
# 1. Rollback immédiat si problème
git checkout v1.0.0  # Version stable précédente

# 2. Rollback database (si nécessaire)
supabase db reset --linked --restore-from-backup

# 3. Redéploy version stable
supabase db push --linked
supabase functions deploy --all

# 4. Validation rollback
psql -c "SELECT * FROM performance_health_check();"

# 5. Feature flags emergency (alternative)
psql -c "SELECT update_feature_flag('problematic_feature', false);"
```

---

## 🔐 Gestion Secrets selon Spécifications

### ✅ **Structure Secrets**

**GitHub Secrets :**
```env
# Supabase
SUPABASE_ACCESS_TOKEN=sbp_...
SUPABASE_PROJECT_ID_DEV=project-dev-ref
SUPABASE_PROJECT_ID_PROD=project-prod-ref  
SUPABASE_URL_PROD=https://project.supabase.co
SUPABASE_ANON_KEY_PROD=eyJ...

# Stripe  
STRIPE_SECRET_KEY_PROD=sk_live_...
STRIPE_WEBHOOK_SECRET_PROD=whsec_...

# Analytics
POSTHOG_API_KEY=phc_...
```

**Supabase Dashboard Variables :**
```env
# Edge Functions environment
STRIPE_SECRET_KEY=sk_live_...
STRIPE_WEBHOOK_SECRET=whsec_...
N8N_WEBHOOK_URL=https://n8n.crewsnow.com/webhook/photo
N8N_WEBHOOK_SECRET=256-bit-secret
POSTHOG_API_KEY=phc_...
```

### ✅ **Environnements**

**.env.dev :**
```env
SUPABASE_URL=https://dev-project.supabase.co
SUPABASE_ANON_KEY=dev_anon_key
STRIPE_PUBLISHABLE_KEY=pk_test_...
ENVIRONMENT=development
```

**.env.prod :**
```env  
SUPABASE_URL=https://prod-project.supabase.co
SUPABASE_ANON_KEY=prod_anon_key
STRIPE_PUBLISHABLE_KEY=pk_live_...
ENVIRONMENT=production
```

**Sécurité :**
- ❌ **Jamais dans repo** : Clés secrètes, tokens, passwords
- ✅ **GitHub Secrets** : Variables CI/CD sécurisées
- ✅ **Supabase Dashboard** : Edge Functions variables chiffrées
- ✅ **Local uniquement** : .env.local pour développement

---

## 📊 Monitoring Post-Déploiement

### ✅ **Métriques Critiques**

```sql
-- Dashboard post-deployment immédiat
SELECT * FROM get_realtime_kpis();

-- Performance health
SELECT * FROM performance_health_check();

-- Error monitoring  
SELECT * FROM error_rate_monitoring WHERE error_status != 'OK';

-- Feature flags status
SELECT flag_key, is_enabled, rollout_percentage 
FROM feature_flags 
WHERE feature_category = 'core'
ORDER BY flag_key;
```

### ✅ **Smoke Test Production**

```bash
# 1. Test registration flow
curl -X POST https://prod.crewsnow.com/auth/signup \
  -d '{"email":"test@smoke.com","password":"test123"}'

# 2. Test matching API
curl -X POST https://prod.supabase.co/functions/v1/match-candidates \
  -H "Authorization: Bearer jwt" \
  -d '{}'

# 3. Test Stripe webhook
stripe events resend evt_test --webhook-endpoint https://prod.supabase.co/functions/v1/stripe-webhook-enhanced

# 4. Test GDPR functions
curl -X GET https://prod.supabase.co/functions/v1/manage-consent \
  -H "Authorization: Bearer jwt"
```

### ✅ **Alertes Configuration**

**Seuils production :**
- 🚨 **P95 latency > 2s** : Alert immediate
- 🚨 **Error rate > 5%** : Feature flag disable  
- 🚨 **Webhook failure > 5%** : Escalation L2
- 🚨 **Security test fail** : Emergency mode

---

## 🎯 Checklist Déploiement

### ✅ **Pré-Déploiement**
- [ ] Tous tests passent localement
- [ ] Security audit clean
- [ ] Performance benchmarks OK
- [ ] Feature flags configured  
- [ ] Backup strategy confirmed

### ✅ **Déploiement**
- [ ] Pipeline CI/CD succeeded
- [ ] Migrations applied successfully
- [ ] Edge Functions deployed
- [ ] Mobile app built
- [ ] Smoke tests passed

### ✅ **Post-Déploiement**
- [ ] Real-time metrics monitoring
- [ ] User registration flow tested
- [ ] Payment processing verified  
- [ ] GDPR functions operational
- [ ] Support team briefed

### ✅ **Validation 24h**
- [ ] No critical alerts triggered
- [ ] User engagement metrics stable
- [ ] Revenue pipeline functional
- [ ] Performance within targets
- [ ] Security posture maintained

---

## 📞 Support Contacts

**Engineering Team :**
- **On-call Dev**: +33 X XX XX XX XX
- **Tech Lead**: engineering@crewsnow.com
- **DevOps**: devops@crewsnow.com

**Vendor Escalation :**
- **Supabase**: support@supabase.com
- **Stripe**: https://support.stripe.com/
- **PostHog**: support@posthog.com

**Internal Escalation :**
- **Engineering Manager**: CTO access
- **Legal/GDPR**: privacy@crewsnow.com
- **Business**: CEO notification for outages >1h

---

## ✅ Version Control

**Branching Strategy :**
```
main → continuous development deployment
tags → production releases (v1.0.0, v1.1.0, etc.)
hotfix/* → emergency production fixes
feature/* → development branches
```

**Release Notes Template :**
```markdown
## CrewSnow v1.0.0

### ✨ New Features
- Feature description
- User impact

### 🔧 Improvements  
- Performance optimizations
- Security enhancements

### 🐛 Bug Fixes
- Issue resolution  
- User experience improvements

### 🔒 Security
- GDPR compliance
- Data protection measures

### ⚙️ Technical
- Database migrations
- Infrastructure updates
```

**DEPLOYMENT PROCEDURE COMPLETE - READY FOR PRODUCTION RELEASES** 🚀📋✅
