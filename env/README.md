# Configuration des Variables d'Environnement

## Structure

```
env/
├── dev/
│   ├── backend.env          # Variables pour le backend de développement
│   
│   ├── mobile.env           # Variables pour l'app mobile de développement
│  
└── prod/
    ├── backend.env          # Variables pour le backend de production
    
    ├── mobile.env           # Variables pour l'app mobile de production
   
```

## Sécurité

### ⚠️ IMPORTANT - Clés Supabase

- **`SUPABASE_ANON_KEY`** : Sécurisé pour le frontend/mobile (public)
- **`SUPABASE_SERVICE_ROLE_KEY`** : ⚠️ **JAMAIS côté mobile/web** - Serveur uniquement !

### Protection Git

Tous les fichiers `.env` sont automatiquement ignorés par Git via `.gitignore` :
```
.env
.env.*
```

## Variables Configurées

### Backend (`backend.env`)
- `SUPABASE_URL` : URL de votre projet Supabase
- `SUPABASE_SERVICE_ROLE_KEY` : Clé service (accès complet - serveur uniquement)
- `SUPABASE_PROJECT_ID` : ID du projet Supabase
- `DATABASE_PASSWORD` : Mot de passe de la base de données

### Mobile (`mobile.env`)
- `SUPABASE_URL` : URL de votre projet Supabase
- `SUPABASE_ANON_KEY` : Clé anonyme (sécurisé pour le client)
- `SUPABASE_PROJECT_ID` : ID du projet Supabase

## Utilisation

1. **Développement** : Utilisez les fichiers dans `env/dev/`
2. **Production** : Utilisez les fichiers dans `env/prod/`
3. **Nouveaux développeurs** : Copiez les fichiers `.example` et remplissez avec vos propres clés

## Projet Supabase - CrewSnow

- **Organisation** : CrewSnow
- **Project name** : CrewSnow
- **Project URL** : https://gtikfxytorvotisvebwg.supabase.co/
- **Project ID** : gtikfxytorvotisvebwg

