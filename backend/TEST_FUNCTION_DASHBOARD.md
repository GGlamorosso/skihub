# 🧪 Tester les Edge Functions depuis le Dashboard

## ⚠️ Problème : Erreur 401 Unauthorized

Quand vous testez depuis le Dashboard, vous devez **passer un token d'authentification**.

## ✅ Solution : Obtenir un token depuis l'app Flutter

### Méthode 1 : Depuis l'app Flutter (Recommandé)

1. **Lancez l'app Flutter** :
   ```bash
   cd frontend
   flutter run
   ```

2. **Connectez-vous** dans l'app

3. **Dans les logs Flutter**, cherchez le token JWT ou ajoutez un debug :
   ```dart
   // Dans votre code Flutter, ajoutez temporairement :
   final token = await SupabaseService.instance.auth.currentSession?.accessToken;
   print('🔑 JWT Token: $token');
   ```

4. **Copiez le token** (il commence par `eyJ...`)

5. **Dans Supabase Dashboard > Edge Functions > match-candidates > Invoke** :
   - Dans l'onglet **Headers**, ajoutez :
     - Key: `Authorization`
     - Value: `Bearer VOTRE_TOKEN_ICI`
   - Dans l'onglet **Body**, ajoutez :
     ```json
     {
       "limit": 10,
       "latitude": 45.5,
       "longitude": 6.0
     }
     ```
   - Cliquez sur **Invoke**

### Méthode 2 : Créer un token de test (Avancé)

1. **Dans Supabase Dashboard > Authentication > Users**
2. **Sélectionnez votre utilisateur**
3. **Créez un token de test** (si disponible dans l'interface)
4. **Utilisez ce token** dans les headers

### Méthode 3 : Tester depuis l'app directement

**C'est la meilleure méthode !** Testez directement depuis l'app Flutter :

1. Lancez l'app
2. Connectez-vous
3. Allez sur l'écran de swipe
4. Les logs dans le terminal vous montreront si ça fonctionne

## 🔍 Vérifier que ça fonctionne depuis l'app

Dans le terminal où vous avez lancé `flutter run`, cherchez :

```
✅ Function called: match-candidates
📍 GPS position sent: 45.5, 6.0
```

Si vous voyez une erreur :
```
❌ Function call failed (match-candidates): ...
```

Partagez l'erreur complète pour que je puisse vous aider.

## 📝 Note importante

**Les Edge Functions nécessitent toujours un token d'authentification** car elles doivent savoir quel utilisateur fait la requête. C'est normal et sécurisé !

---

**Recommandation** : Testez directement depuis l'app Flutter plutôt que depuis le Dashboard. C'est plus simple et plus réaliste ! 🎯

