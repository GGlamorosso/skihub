# 🚀 Guide de Déploiement des Edge Functions

## Option 1 : Via Supabase Dashboard (RECOMMANDÉ - Plus simple)

### Étapes :

1. **Ouvrir Supabase Dashboard**
   - Allez sur [https://app.supabase.com](https://app.supabase.com)
   - Connectez-vous et sélectionnez votre projet `crewsnow-33b1f`

2. **Créer la fonction `match-candidates`**
   - Allez dans **Edge Functions** (menu de gauche)
   - Cliquez sur **Create a new function**
   - Nom : `match-candidates`
   - Copiez-collez le contenu de `backend/supabase/functions/match-candidates/index.ts`
   - Cliquez sur **Deploy**

3. **Créer la fonction `gatekeeper`**
   - Cliquez sur **Create a new function**
   - Nom : `gatekeeper`
   - Copiez-collez le contenu de `backend/supabase/functions/gatekeeper/index.ts`
   - Cliquez sur **Deploy**

4. **Créer la fonction `manage-consent`**
   - Cliquez sur **Create a new function**
   - Nom : `manage-consent`
   - Copiez-collez le contenu de `backend/supabase/functions/manage-consent/index.ts`
   - Cliquez sur **Deploy**

5. **Vérifier le déploiement**
   - Vous devriez voir les 3 fonctions dans la liste
   - Le statut doit être "Active"

## Option 2 : Via Supabase CLI (Si vous préférez)

### Installation de Supabase CLI

```bash
# Installer via Homebrew (macOS)
brew install supabase/tap/supabase

# OU installer via npm
npm install -g supabase
```

### Déploiement

```bash
# Se connecter à Supabase
supabase login

# Lier votre projet (remplacez PROJECT_REF par votre project ref)
cd /Users/user/Desktop/SKIAPP/crewsnow/backend
supabase link --project-ref votre-project-ref

# Déployer les fonctions
supabase functions deploy match-candidates
supabase functions deploy gatekeeper
supabase functions deploy manage-consent
```

### Trouver votre Project Ref

1. Allez sur [Supabase Dashboard](https://app.supabase.com)
2. Sélectionnez votre projet
3. Allez dans **Settings > General**
4. Copiez le **Reference ID** (ex: `crewsnow-33b1f`)

## 📋 Checklist de Vérification

Après le déploiement, vérifiez :

- [ ] Les 3 fonctions sont listées dans Edge Functions
- [ ] Le statut est "Active" pour toutes
- [ ] Vous pouvez tester chaque fonction via "Invoke"

## 🧪 Tester les fonctions

### Tester `match-candidates`

Dans Supabase Dashboard > Edge Functions > match-candidates > Invoke :

```json
{
  "limit": 10,
  "latitude": 45.5,
  "longitude": 6.0
}
```

**Résultat attendu** :
```json
{
  "candidates": [...],
  "nextCursor": "..."
}
```

### Tester `manage-consent`

```json
{
  "action": "check",
  "purpose": "gps_tracking"
}
```

**Résultat attendu** :
```json
{
  "granted": false,
  "version": 0
}
```

## ⚠️ Si vous avez des erreurs

### Erreur : "Function not found"
- Vérifiez que la fonction est bien déployée
- Vérifiez le nom exact (sensible à la casse)

### Erreur : "Unauthorized"
- Vérifiez que vous êtes bien authentifié dans l'app
- Vérifiez que le token JWT est valide

### Erreur : "Table not found"
- Vérifiez que la vue `public_profiles_v` existe
- Vérifiez les permissions RLS

---

**Recommandation** : Utilisez l'Option 1 (Dashboard) si vous n'avez pas Supabase CLI installé. C'est plus simple et plus rapide ! 🎯

