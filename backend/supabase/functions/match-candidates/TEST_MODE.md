# 🧪 Mode Test pour match-candidates

## ⚠️ Note importante

**L'erreur 401 depuis le Dashboard est NORMALE.** Les Edge Functions nécessitent un utilisateur authentifié.

## ✅ Comment tester correctement

### Depuis l'app Flutter (RECOMMANDÉ)

1. Lancez l'app : `flutter run`
2. Connectez-vous
3. Allez sur l'écran de swipe
4. Les profils devraient apparaître automatiquement

Le token d'authentification est envoyé automatiquement par Flutter Supabase SDK.

### Depuis le Dashboard (Optionnel - nécessite un token)

Si vous voulez tester depuis le Dashboard :

1. **Obtenez un token JWT** :
   - Depuis l'app Flutter (ajoutez un print temporaire)
   - Ou créez un token de test dans Supabase

2. **Dans Edge Functions > match-candidates > Invoke** :
   - **Headers** : Ajoutez `Authorization: Bearer VOTRE_TOKEN`
   - **Body** :
     ```json
     {
       "limit": 10,
       "latitude": 45.5,
       "longitude": 6.0
     }
     ```

## 🔍 Vérifier que ça fonctionne depuis l'app

Dans les logs Flutter, cherchez :
- `✅ Function called: match-candidates`
- `📍 GPS position sent: ...`
- Pas d'erreur 401

Si vous voyez une erreur, partagez-la moi !

---

**En résumé : Testez depuis l'app, pas depuis le Dashboard !** 🎯

