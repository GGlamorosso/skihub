# 🚀 Déployer les Edge Functions - Guide Simple

## ✅ Méthode Recommandée : Via Supabase Dashboard

### Étape 1 : Ouvrir Supabase Dashboard
1. Allez sur [https://app.supabase.com](https://app.supabase.com)
2. Connectez-vous
3. Sélectionnez votre projet **crewsnow-33b1f**

### Étape 2 : Créer la fonction `match-candidates`

1. Dans le menu de gauche, cliquez sur **Edge Functions**
2. Cliquez sur le bouton **Create a new function** (ou **New Function**)
3. **Nom de la fonction** : `match-candidates`
4. **Code** : Copiez-collez tout le contenu du fichier :
   ```
   backend/supabase/functions/match-candidates/index.ts
   ```
5. Cliquez sur **Deploy** (ou **Save**)

### Étape 3 : Créer la fonction `gatekeeper`

1. Cliquez sur **Create a new function**
2. **Nom** : `gatekeeper`
3. **Code** : Copiez-collez le contenu de :
   ```
   backend/supabase/functions/gatekeeper/index.ts
   ```
4. Cliquez sur **Deploy**

### Étape 4 : Créer la fonction `manage-consent`

1. Cliquez sur **Create a new function**
2. **Nom** : `manage-consent`
3. **Code** : Copiez-collez le contenu de :
   ```
   backend/supabase/functions/manage-consent/index.ts
   ```
4. Cliquez sur **Deploy**

### Étape 5 : Vérifier

Vous devriez voir les 3 fonctions dans la liste :
- ✅ `match-candidates` - Status: Active
- ✅ `gatekeeper` - Status: Active
- ✅ `manage-consent` - Status: Active

## 📋 Contenu des fichiers à copier

### 1. match-candidates/index.ts
Ouvrez le fichier et copiez tout son contenu :
```
/Users/user/Desktop/SKIAPP/crewsnow/backend/supabase/functions/match-candidates/index.ts
```

### 2. gatekeeper/index.ts
Ouvrez le fichier et copiez tout son contenu :
```
/Users/user/Desktop/SKIAPP/crewsnow/backend/supabase/functions/gatekeeper/index.ts
```

### 3. manage-consent/index.ts
Ouvrez le fichier et copiez tout son contenu :
```
/Users/user/Desktop/SKIAPP/crewsnow/backend/supabase/functions/manage-consent/index.ts
```

## 🧪 Tester après déploiement

### Tester `match-candidates`

1. Dans Edge Functions, cliquez sur `match-candidates`
2. Cliquez sur **Invoke** (ou **Test**)
3. Dans le body, collez :
```json
{
  "limit": 10,
  "latitude": 45.5,
  "longitude": 6.0
}
```
4. Cliquez sur **Invoke**

**Résultat attendu** :
```json
{
  "candidates": [...],
  "nextCursor": "..."
}
```

## ⚠️ Si vous préférez utiliser la CLI

### Installer Supabase CLI

```bash
# Option 1 : Via Homebrew (macOS)
brew install supabase/tap/supabase

# Option 2 : Via npm
npm install -g supabase
```

### Déployer

```bash
# Se connecter
supabase login

# Lier le projet (remplacez par votre project ref)
cd /Users/user/Desktop/SKIAPP/crewsnow/backend
supabase link --project-ref crewsnow-33b1f

# Déployer
supabase functions deploy match-candidates
supabase functions deploy gatekeeper
supabase functions deploy manage-consent
```

**Mais la méthode Dashboard est plus simple !** 🎯

---

**Une fois les fonctions déployées, relancez l'app et vous devriez voir des profils !** 🚀

