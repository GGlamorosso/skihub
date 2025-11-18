#!/bin/bash

# ============================================================================
# Script pour exécuter un fichier SQL sur Supabase
# ============================================================================
# Usage: ./scripts/execute-sql-file.sh <fichier.sql>
# ============================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}❌ Erreur: Spécifiez un fichier SQL${NC}"
    echo "Usage: ./scripts/execute-sql-file.sh <fichier.sql>"
    exit 1
fi

SQL_FILE="$1"

if [ ! -f "$SQL_FILE" ]; then
    echo -e "${RED}❌ Erreur: Le fichier $SQL_FILE n'existe pas${NC}"
    exit 1
fi

echo -e "${BLUE}📄 Exécution du fichier SQL: $SQL_FILE${NC}"
echo ""

# Méthode 1: Via Supabase Dashboard (recommandé)
echo -e "${YELLOW}📋 MÉTHODE RECOMMANDÉE :${NC}"
echo "1. Allez sur https://app.supabase.com"
echo "2. Sélectionnez votre projet"
echo "3. Allez dans SQL Editor"
echo "4. Copiez-collez le contenu de: $SQL_FILE"
echo "5. Cliquez sur Run"
echo ""

# Méthode 2: Via psql (si vous avez la connection string)
echo -e "${YELLOW}📋 MÉTHODE ALTERNATIVE (psql) :${NC}"
echo "Si vous avez la connection string, vous pouvez utiliser:"
echo ""
echo "psql \"postgresql://postgres:[PASSWORD]@db.[PROJECT_REF].supabase.co:5432/postgres\" -f $SQL_FILE"
echo ""
echo "Pour obtenir la connection string:"
echo "1. Supabase Dashboard > Settings > Database"
echo "2. Copiez la connection string (URI)"
echo ""

# Afficher le contenu du fichier pour faciliter le copier-coller
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}📋 Contenu du fichier (à copier dans SQL Editor):${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
cat "$SQL_FILE"
echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

