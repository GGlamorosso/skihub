# 🧪 Tester match-candidates depuis le Dashboard

## ⚠️ Pourquoi l'erreur 401 ?

**C'est normal !** Le Dashboard Supabase n'envoie pas automatiquement de token d'authentification. Les Edge Functions nécessitent un utilisateur authentifié.

## ✅ Solution : Tester depuis l'app Flutter (RECOMMANDÉ)

**C'est la meilleure méthode !** Depuis l'app Flutter, le token est envoyé automatiquement.

1. **Lancez l'app** :
   ```bash
   cd frontend
   flutter run
   ```

2. **Connectez-vous** dans l'app

3. **Allez sur l'écran de swipe** (feed)

4. **Vérifiez les logs** dans le terminal :
   - ✅ `✅ Function called: match-candidates`
   - ✅ `📍 GPS position sent: ...`
   - ✅ `✅ Supabase initialized successfully`

5. **Si vous voyez des profils** → ✅ Ça fonctionne !
6. **Si vous voyez une erreur** → Partagez-la moi

## 🔧 Tester depuis le Dashboard (Optionnel)

Si vous voulez vraiment tester depuis le Dashboard, vous devez obtenir un token :

### Étape 1 : Obtenir un token JWT

**Option A : Depuis l'app Flutter (temporaire)**
Ajoutez ce code temporairement dans `main.dart` ou dans un écran :

```dart
// Temporaire pour obtenir le token
final session = await SupabaseService.instance.auth.currentSession;
if (session != null) {
  print('🔑 JWT Token: ${session.accessToken}');
  // Copiez ce token
}
```

**Option B : Depuis Supabase Dashboard**
1. Allez dans **Authentication > Users**
2. Sélectionnez votre utilisateur
3. Dans les détails, vous devriez voir un token (si disponible)

### Étape 2 : Utiliser le token dans le Dashboard

1. **Edge Functions > match-candidates > Invoke**
2. **Dans l'onglet Headers**, ajoutez :
   - **Key** : `Authorization`
   - **Value** : `Bearer VOTRE_TOKEN_ICI`
3. **Dans l'onglet Body**, ajoutez :
   ```json
   {
     "limit": 10,
     "latitude": 45.5,
     "longitude": 6.0
   }
   ```
4. **Cliquez sur Invoke**

## 🎯 Recommandation

**Ne testez PAS depuis le Dashboard pour l'instant.** Testez directement depuis l'app Flutter :

1. Relancez l'app
2. Connectez-vous
3. Allez sur le feed
4. Vérifiez si des profils apparaissent

Si ça ne fonctionne pas depuis l'app, partagez les logs du terminal et je vous aiderai à diagnostiquer le problème.

---

**La fonction est correctement configurée. Le problème vient juste du fait que le Dashboard n'envoie pas de token par défaut.** 🎯

