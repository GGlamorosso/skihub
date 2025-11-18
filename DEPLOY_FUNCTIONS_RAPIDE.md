# 🚀 Déployer les Edge Functions - Guide Rapide

**Temps estimé** : 5-10 minutes  
**3 fonctions critiques** pour la bêta

---

## 🎯 Méthode 1 : Script Automatique (Recommandé) ⚡

### Prérequis
1. Installer Supabase CLI :
```bash
# macOS
brew install supabase/tap/supabase

# ou via npm
npm install -g supabase
```

2. Se connecter :
```bash
supabase login
```

3. Lier votre projet (si pas déjà fait) :
```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
supabase link --project-ref qzpinzxiqupetortbczh
```

### Déployer les 3 fonctions critiques
```bash
cd /Users/user/Desktop/SKIAPP/crewsnow
./scripts/deploy-all-functions.sh --critical-only
```

**C'est tout !** Le script déploie automatiquement :
- ✅ `match-candidates`
- ✅ `gatekeeper`
- ✅ `manage-consent`

### Déployer TOUTES les fonctions (optionnel)
```bash
./scripts/deploy-all-functions.sh
```

---

## 🖥️ Méthode 2 : Via Supabase Dashboard (Manuel)

Si vous préférez faire manuellement ou si la CLI ne fonctionne pas :

### Étape 1 : Ouvrir Supabase Dashboard
1. Allez sur [https://app.supabase.com](https://app.supabase.com)
2. Sélectionnez votre projet

### Étape 2 : Déployer chaque fonction

#### Fonction 1 : `match-candidates`
1. **Edge Functions** > **Create a new function**
2. **Nom** : `match-candidates`
3. **Code** : Copier tout le contenu de :
   ```
   supabase/functions/match-candidates/index.ts
   ```
4. **Deploy**

#### Fonction 2 : `gatekeeper`
1. **Create a new function**
2. **Nom** : `gatekeeper`
3. **Code** : Copier le contenu de :
   ```
   supabase/functions/gatekeeper/index.ts
   ```
4. **Deploy**

#### Fonction 3 : `manage-consent`
1. **Create a new function**
2. **Nom** : `manage-consent`
3. **Code** : Copier le contenu de :
   ```
   supabase/functions/manage-consent/index.ts
   ```
4. **Deploy**

### Vérification
Vous devriez voir les 3 fonctions dans la liste avec le statut **Active** ✅

---

## 🧪 Tester après déploiement

### Tester `match-candidates`
1. Dans **Edge Functions**, cliquez sur `match-candidates`
2. Cliquez sur **Invoke**
3. Body :
```json
{
  "limit": 10
}
```
4. Cliquez sur **Invoke**

**Résultat attendu** :
```json
{
  "candidates": [...],
  "has_more": false,
  "next_cursor": null
}
```

---

## ⚠️ Erreurs courantes

### "Function not found"
**Solution** : Vérifiez que vous avez bien créé la fonction dans le Dashboard

### "Cannot find module"
**Solution** : Assurez-vous d'avoir copié TOUT le contenu du fichier `index.ts`

### "Permission denied" (CLI)
**Solution** : Vérifiez que vous êtes connecté : `supabase login`

### "Project not linked" (CLI)
**Solution** : Liez le projet : `supabase link --project-ref qzpinzxiqupetortbczh`

---

## 📋 Liste complète des fonctions (optionnel)

Si vous voulez déployer toutes les fonctions plus tard :

**Critiques (pour bêta)** :
- ✅ `match-candidates` - Matching des profils
- ✅ `gatekeeper` - Système de quotas
- ✅ `manage-consent` - Gestion GDPR

**Importantes (pour production)** :
- `swipe` ou `swipe-enhanced` - Système de swipe
- `send-message-enhanced` - Envoi de messages
- `stripe-webhook-enhanced` - Webhooks Stripe
- `create-stripe-customer` - Création clients Stripe

**Optionnelles** :
- `analytics-posthog` - Analytics
- `export-user-data` - Export GDPR
- `delete-user-account` - Suppression compte
- `webhook-n8n` - Modération photos

---

## ✅ Checklist

- [ ] 3 fonctions critiques déployées
- [ ] Fonctions testées via Dashboard
- [ ] Pas d'erreurs dans les logs
- [ ] App Flutter peut appeler les fonctions

---

**Une fois les 3 fonctions déployées, votre app est prête pour la bêta !** 🚀

