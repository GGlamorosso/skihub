#!/usr/bin/env bash
# Script pour charger les variables d'environnement
# Usage: bash scripts/use-env.sh dev mobile
# Usage: bash scripts/use-env.sh prod backend

set -euo pipefail

ENV_NAME="${1:-dev}"      # dev | prod
ROLE="${2:-mobile}"       # mobile | backend

FILE="env/${ENV_NAME}/${ROLE}.env"

# Vérifier que le fichier existe
if [ ! -f "$FILE" ]; then
    echo "❌ Fichier manquant: $FILE"
    echo "💡 Fichiers disponibles:"
    find env/ -name "*.env" -type f 2>/dev/null || echo "   Aucun fichier .env trouvé"
    exit 1
fi

# Charger les variables et les exporter
set -a
source "$FILE"
set +a

echo "✅ Variables chargées depuis: $FILE"
echo "🌍 Environnement: $ENV_NAME"
echo "🔧 Rôle: $ROLE"

# Afficher quelques infos (sans secrets)
if [ -n "${SUPABASE_URL:-}" ]; then
    echo "🔗 Supabase URL: ${SUPABASE_URL}"
fi

if [ -n "${ENV:-}" ]; then
    echo "🏷️  ENV: ${ENV}"
fi

# Avertissement pour les secrets
if [ "$ROLE" = "backend" ]; then
    echo "⚠️  MODE BACKEND: Secrets chargés (ne pas exposer côté client)"
else
    echo "✅ MODE CLIENT: Variables publiques uniquement"
fi
