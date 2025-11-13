# 🤖 CrewSnow n8n Photo Moderation - Guide de Configuration

## 📋 Vue d'Ensemble

Ce guide vous aide à configurer n8n pour recevoir les webhooks Supabase et effectuer la modération automatique des photos de profil CrewSnow.

## 🚀 Installation et Configuration n8n

### ✅ **1. Installation n8n**

```bash
# Option 1: Docker (Recommandé)
docker run -it --rm \
  --name n8n \
  -p 5678:5678 \
  -e WEBHOOK_URL=https://your-domain.com \
  -e N8N_SECURE_COOKIE=false \
  -v ~/.n8n:/home/node/.n8n \
  n8nio/n8n

# Option 2: npm
npm install -g n8n
n8n start

# Option 3: Cloud n8n
# Créer un compte sur https://n8n.cloud
```

### ✅ **2. Variables d'Environnement n8n**

**Configuration dans n8n → Settings → Variables :**

```env
# ✅ CrewSnow Configuration
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key-here
N8N_WEBHOOK_SECRET=your-secure-secret-key-here

# ✅ AWS Rekognition (ou autre service)
AWS_ACCESS_KEY_ID=your-aws-access-key
AWS_SECRET_ACCESS_KEY=your-aws-secret-key  
AWS_REGION=us-east-1

# ✅ Alternative: Google Cloud Vision
GOOGLE_CLOUD_PROJECT_ID=your-gcp-project
GOOGLE_CLOUD_SERVICE_ACCOUNT=your-service-account-json

# ✅ Alternative: Hugging Face
HF_API_TOKEN=your-hugging-face-token
```

## 📡 3. Configuration Webhook Endpoint n8n

### ✅ **Créer le Workflow**

1. **Importer le workflow** : 
   - Aller dans n8n → Import workflow
   - Charger `photo-moderation-workflow.json`

2. **Configurer le Webhook Trigger** :
   ```
   URL: https://your-n8n.domain.com/webhook/photo-moderation  
   Method: POST
   Authentication: None (sécurité par signature)
   Response: Enabled
   ```

3. **Récupérer l'URL webhook** :
   ```
   URL Webhook n8n : https://your-n8n.domain.com/webhook-test/crewsnow-photo-moderation
   ```

### ✅ **Configuration Sécurité**

**Node "Validate Webhook Security" :**

```javascript
// Vérification HMAC signature pour sécurité
const crypto = require('crypto');

const payload = JSON.stringify($input.first().json.record);
const receivedSignature = $input.first().json.headers['x-crewsnow-signature'];
const secret = $vars.N8N_WEBHOOK_SECRET;

if (!secret) {
  throw new Error('N8N_WEBHOOK_SECRET not configured');
}

if (!receivedSignature) {
  throw new Error('Missing webhook signature');  
}

// Générer signature attendue
const expectedSignature = 'sha256=' + crypto
  .createHmac('sha256', secret)
  .update(payload)
  .digest('hex');

// Vérifier signature
if (receivedSignature !== expectedSignature) {
  throw new Error('Invalid webhook signature');
}

console.log('✅ Webhook signature verified');
return { verified: true, photo: $input.first().json.record };
```

## 🔍 4. Configuration Modération AWS Rekognition

### ✅ **Credentials AWS**

**Dans n8n → Credentials → Add Credential → AWS :**

```
Name: CrewSnow AWS Credentials
Access Key ID: your-aws-access-key  
Secret Access Key: your-aws-secret-key
Region: us-east-1 (ou votre région)
```

### ✅ **Node AWS Rekognition**

**Configuration :**
```
Resource: image
Operation: detectModerationLabels
Max Labels: 20
Min Confidence: 75%

Input: Image from "Download Image from Storage" node
```

**Labels détectés (exemples) :**
- `Explicit Nudity` (Confidence: 95%)
- `Suggestive` (Confidence: 80%)  
- `Violence` (Confidence: 90%)
- `Visually Disturbing` (Confidence: 85%)
- `Rude Gestures` (Confidence: 75%)

## ✅ 5. Configuration Alternative: Google Cloud Vision

### ✅ **Credentials GCP**

```json
// Service Account Key JSON
{
  "type": "service_account",
  "project_id": "your-project",
  "private_key_id": "key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...",
  "client_email": "service-account@project.iam.gserviceaccount.com",
  "client_id": "12345",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token"
}
```

### ✅ **Node Google Cloud Vision**

**Remplacer AWS Rekognition par :**
```
Service: Google Cloud Vision API
Operation: Safe Search Detection  
Configuration: {
  "features": [
    {
      "type": "SAFE_SEARCH_DETECTION",
      "maxResults": 1
    }
  ]
}
```

## ⚙️ 6. Workflow Logic Détaillé

### ✅ **Flow Complet n8n**

```mermaid
graph TD
    A[Webhook Trigger] -->|POST /webhook/photo-moderation| B[Verify Signature]
    B -->|Valid| C[Download Image]
    B -->|Invalid| D[Return Error]
    
    C -->|Signed URL| E[AWS Rekognition]
    E -->|Moderation Labels| F{Safe Content?}
    
    F -->|Safe| G[Approve Photo]
    F -->|Unsafe| H[Reject Photo]
    
    G -->|Update DB| I[Notify User Approved]
    H -->|Update DB + Reason| J[Notify User Rejected]
    
    I --> K[Respond Success]
    J --> K[Respond Success]
    
    style E fill:#fff2cc
    style G fill:#d4e1f5
    style H fill:#f8cecc
```

### ✅ **Node Decision Logic**

**"Check if Photo is Safe" :**
```javascript
// Si aucun label de modération détecté → Approuver
const moderationLabels = $input.first().json.ModerationLabels || [];

// Filtrer par confiance élevée
const highConfidenceLabels = moderationLabels.filter(
  label => label.Confidence >= 80
);

// Critères de rejet
const rejectLabels = ['Explicit Nudity', 'Violence', 'Visually Disturbing'];
const hasRejectableContent = highConfidenceLabels.some(
  label => rejectLabels.includes(label.Name)
);

console.log(`🔍 Moderation analysis:`, {
  totalLabels: moderationLabels.length,
  highConfidenceLabels: highConfidenceLabels.length, 
  hasRejectableContent,
  decision: hasRejectableContent ? 'REJECT' : 'APPROVE'
});

return { 
  safe: !hasRejectableContent,
  labels: highConfidenceLabels,
  decision: hasRejectableContent ? 'REJECT' : 'APPROVE'
};
```

## 🔐 7. Sécurité et Authentification

### ✅ **Variables Chiffrées n8n**

**Dans n8n → Settings → Variables (encrypted) :**

```
N8N_WEBHOOK_SECRET=your-256-bit-secret-key
SUPABASE_SERVICE_ROLE_KEY=eyJ...your-service-role-jwt
AWS_SECRET_ACCESS_KEY=your-aws-secret
```

### ✅ **IP Allowlist (si possible)**

**Configuration Supabase → Settings → API :**
```
IP Allowlist pour Edge Functions:
- IP n8n instance : xxx.xxx.xxx.xxx
- IP cloud n8n : (voir documentation n8n cloud)
```

### ✅ **Validation Signature**

**Supabase génère :**
```typescript
const signature = crypto.createHmac('sha256', secret)
  .update(JSON.stringify(payload))
  .digest('hex')

headers: { 'X-CrewSnow-Signature': `sha256=${signature}` }
```

**n8n valide :**
```javascript
const receivedSignature = $json.headers['x-crewsnow-signature'];
const expectedSignature = 'sha256=' + crypto.createHmac('sha256', secret)
  .update(payloadString).digest('hex');

if (receivedSignature !== expectedSignature) {
  throw new Error('Invalid signature');
}
```

## 📊 8. Monitoring et Debug

### ✅ **Dashboard Monitoring n8n**

**Executions → CrewSnow Photo Moderation :**
- ✅ **Success rate** : Pourcentage réussites
- ⏱️ **Avg execution time** : Temps moyen workflow
- 📈 **Volume** : Nombre photos traitées/jour
- ❌ **Errors** : Logs des échecs

### ✅ **Logs Supabase**

```sql
-- Vérifier santé webhook  
SELECT * FROM check_webhook_health();

-- Voir logs récents
SELECT * FROM webhook_logs ORDER BY timestamp DESC LIMIT 20;

-- Retry webhooks échoués
SELECT retry_failed_webhooks(5, 24);
```

### ✅ **Debug Workflow n8n**

**Logs à surveiller :**
```javascript
// Dans chaque node n8n
console.log('📊 Node execution:', {
  node: 'NodeName',
  input: $input.all(),
  timestamp: new Date().toISOString()
});

// Erreurs courantes
console.error('❌ Node failed:', {
  error: error.message,
  photo_id: $('Validate Webhook Security').first().json.photo.id
});
```

## 🧪 9. Tests

### ✅ **Test Manuel**

**1. Insérer photo test :**
```sql
INSERT INTO profile_photos (
    user_id,
    storage_path, 
    file_size_bytes,
    mime_type,
    moderation_status
) VALUES (
    '00000000-0000-0000-0000-000000000001',
    'test-user/test-photo.jpg',
    1024000,
    'image/jpeg', 
    'pending'
);
```

**2. Vérifier logs :**
```sql
SELECT * FROM webhook_logs WHERE table_name = 'profile_photos' ORDER BY timestamp DESC LIMIT 5;
```

**3. Vérifier n8n execution :**
- Aller dans n8n → Executions
- Vérifier que le workflow s'est exécuté
- Analyser chaque node pour débugger

### ✅ **Test Automatisé**

```bash
# Script de test complet
curl -X POST "https://your-project.supabase.co/functions/v1/webhook-n8n" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer your-service-role-key" \
  -d '{
    "record": {
      "id": "test-photo-id",
      "user_id": "test-user-id", 
      "storage_path": "test-user/test.jpg",
      "file_size_bytes": 1024000,
      "mime_type": "image/jpeg",
      "moderation_status": "pending",
      "created_at": "2025-01-10T12:00:00Z"
    }
  }'
```

## 🔧 10. Configuration Production

### ✅ **Variables d'Environnement Supabase**

**Dashboard Supabase → Settings → Edge Functions :**
```env
# ✅ n8n Configuration
N8N_WEBHOOK_URL=https://your-n8n.domain.com/webhook-test/crewsnow-photo-moderation
N8N_WEBHOOK_SECRET=your-256-bit-secret-key

# ✅ Service Role for storage access  
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# ✅ Optional: Retry configuration
WEBHOOK_RETRY_ATTEMPTS=3
WEBHOOK_TIMEOUT_MS=30000
```

### ✅ **Déploiement**

```bash
# 1. Déployer Edge Function  
supabase functions deploy webhook-n8n

# 2. Appliquer migration webhook
supabase migration apply 20250110_photo_moderation_webhook

# 3. Configurer variables n8n
# (Voir section variables d'environnement)

# 4. Importer workflow n8n
# Utiliser photo-moderation-workflow.json

# 5. Activer workflow n8n
# Aller dans n8n → Activate workflow
```

## ✅ 11. Troubleshooting

### ❌ **Problèmes Fréquents**

**Webhook non reçu dans n8n :**
```bash
# Vérifier URL webhook
echo $N8N_WEBHOOK_URL

# Tester connectivité
curl -X POST $N8N_WEBHOOK_URL -d '{"test": true}'

# Vérifier logs Supabase
supabase functions logs webhook-n8n --follow
```

**Signature invalide :**
```javascript
// Vérifier secret n8n
console.log('Secret configured:', !!$vars.N8N_WEBHOOK_SECRET);

// Vérifier format signature
console.log('Received signature:', $json.headers['x-crewsnow-signature']);
console.log('Expected format:', 'sha256=...');
```

**Rekognition échoue :**
```javascript
// Vérifier credentials AWS
console.log('AWS credentials configured:', {
  accessKey: !!$vars.AWS_ACCESS_KEY_ID,
  secretKey: !!$vars.AWS_SECRET_ACCESS_KEY,
  region: $vars.AWS_REGION
});

// Test avec image simple
const testImageUrl = 'https://example.com/safe-image.jpg';
```

### ✅ **Solutions**

| Problème | Solution |
|----------|----------|
| **Webhook timeout** | Augmenter WEBHOOK_TIMEOUT_MS |
| **Too many retries** | Vérifier n8n disponibilité |
| **Signature mismatch** | Vérifier N8N_WEBHOOK_SECRET identique |
| **Image download fails** | Vérifier signed URL expiration |
| **Rekognition errors** | Vérifier credentials AWS + quotas |
| **Database update fails** | Vérifier SUPABASE_SERVICE_ROLE_KEY |

## 📊 12. Monitoring Production

### ✅ **Métriques n8n**

**Dashboard n8n :**
- 📈 **Executions/day** : Volume modération
- ⏱️ **Avg execution time** : Performance workflow  
- ❌ **Error rate** : Pourcentage échecs
- 🔄 **Queue depth** : Files d'attente

### ✅ **Métriques Supabase**

```sql
-- Dashboard modération quotidien
SELECT 
    DATE(timestamp) as date,
    COUNT(*) as total_webhooks,
    COUNT(*) FILTER (WHERE success = true) as successful,
    COUNT(*) FILTER (WHERE success = false) as failed,
    ROUND((COUNT(*) FILTER (WHERE success = true)::DECIMAL / COUNT(*)) * 100, 2) as success_rate_pct
FROM webhook_logs 
WHERE webhook_type = 'n8n_moderation'
  AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY DATE(timestamp)
ORDER BY date DESC;
```

### ✅ **Alertes Recommandées**

```sql
-- Alertes à configurer
-- 1. Success rate < 90% sur 1h
-- 2. Aucun webhook réussi depuis 30min
-- 3. Plus de 100 photos pending depuis 2h
-- 4. Erreurs répétées même photo
```

## 🎯 13. Workflow Alternatifs

### ✅ **Option A : Modération Humaine**

```javascript
// Node "Human Review Required"
const requiresHumanReview = $json.ModerationLabels.some(
  label => label.Confidence >= 50 && label.Confidence < 80
);

if (requiresHumanReview) {
  // Envoyer à queue modération humaine
  return { action: 'human_review', labels: $json.ModerationLabels };
} else {
  // Modération automatique
  return { action: 'auto_moderate' };
}
```

### ✅ **Option B : Multiple Services**

```javascript
// Combiner AWS + Google + Hugging Face
const rekognitionResult = $('AWS Rekognition').first().json;
const visionResult = $('Google Vision').first().json;
const hfResult = $('Hugging Face').first().json;

// Consensus de modération
const consensusReject = [rekognitionResult, visionResult, hfResult]
  .filter(result => result.unsafe).length >= 2;

return { decision: consensusReject ? 'REJECT' : 'APPROVE' };
```

## 📚 Ressources et Documentation

### ✅ **Liens Utiles**

- 📖 **n8n Documentation** : https://docs.n8n.io/
- 🔍 **AWS Rekognition** : https://docs.aws.amazon.com/rekognition/
- 👁️ **Google Vision** : https://cloud.google.com/vision/docs  
- 🤗 **Hugging Face** : https://huggingface.co/docs/api-inference

### ✅ **Support CrewSnow**

- 📄 **Workflow n8n** : `photo-moderation-workflow.json`
- 🚀 **Edge Function** : `supabase/functions/webhook-n8n/`
- 📊 **Migration** : `20250110_photo_moderation_webhook.sql`
- 📋 **Tests** : `scripts/test-photo-moderation.sh`

---

**✅ Configuration n8n prête pour modération automatique CrewSnow !** 🤖📸
