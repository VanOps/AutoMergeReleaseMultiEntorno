#!/bin/bash
# setup-environments.sh - Guía para configurar GitHub Environments

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🌍 GitHub Environments Setup Guide${NC}"
echo ""

# Verificar gh CLI
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: gh CLI no está instalado${NC}"
    echo "Instala desde: https://cli.github.com/"
    exit 1
fi

# Obtener info del repo
REPO=$(gh repo view --json nameWithOwner --jq .nameWithOwner)
echo -e "${GREEN}📦 Repositorio: ${YELLOW}$REPO${NC}"
echo ""

echo -e "${YELLOW}⚠️  IMPORTANTE:${NC}"
echo "Los GitHub Environments solo se pueden configurar completamente desde la UI web."
echo "Este script te guiará en el proceso."
echo ""

# Función para mostrar instrucciones de environment
show_env_instructions() {
    local ENV_NAME=$1
    local REVIEWERS=$2
    local WAIT_TIME=$3
    local BRANCH_POLICY=$4
    
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Environment: ${YELLOW}$ENV_NAME${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo "1. Ve a: Settings > Environments > New environment"
    echo "2. Name: $ENV_NAME"
    echo ""
    
    if [ "$REVIEWERS" != "none" ]; then
        echo "3. Configure environment:"
        echo "   ☑ Required reviewers: $REVIEWERS"
        echo "   ☑ Prevent administrators from bypassing: ON"
    fi
    
    if [ "$WAIT_TIME" != "0" ]; then
        echo "   ☑ Wait timer: $WAIT_TIME minutes"
    fi
    
    echo "   Deployment branches: $BRANCH_POLICY"
    echo ""
    echo "4. Environment secrets (opcional):"
    echo "   - ${ENV_NAME^^}_API_URL"
    echo "   - ${ENV_NAME^^}_DB_HOST"
    echo ""
    echo "5. Environment variables:"
    echo "   - ENV_NAME: $ENV_NAME"
    echo "   - LOG_LEVEL: debug/info/warn"
    echo ""
}

# QA Environment
show_env_instructions "qa" "none" "0" "Selected branches → release/*"

read -p "Presiona Enter cuando hayas configurado QA..."

# Staging Environment
show_env_instructions "staging" "1-2 reviewers" "0" "Selected branches → release/*"

read -p "Presiona Enter cuando hayas configurado Staging..."

# Production Environment
show_env_instructions "production" "2+ reviewers (senior team)" "5" "Only protected branches (main)"

read -p "Presiona Enter cuando hayas configurado Production..."

echo ""
echo -e "${GREEN}✅ Configuración de Environments completada!${NC}"
echo ""
echo -e "${BLUE}🔍 Verificar environments:${NC}"
echo "  gh api repos/$REPO/environments --jq '.environments[].name'"
echo ""
echo -e "${BLUE}📝 Próximos pasos:${NC}"
echo "  1. Configurar branch protection para main y release/*"
echo "  2. Crear una rama de release de prueba"
echo "  3. Observar el pipeline multi-entorno en acción"
echo ""

# Intentar listar environments
echo -e "${BLUE}🌍 Environments configurados:${NC}"
gh api repos/$REPO/environments --jq '.environments[] | "  - \(.name)"' 2>/dev/null || echo "  (No se pueden listar, verifica en GitHub UI)"
