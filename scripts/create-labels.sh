#!/bin/bash
# create-labels.sh - Crea labels necesarios para Release Multi-Environment

set -e

echo "🏷️  Creando labels para Release Multi-Environment Pipeline..."

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Verificar que gh CLI está instalado
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ Error: gh CLI no está instalado${NC}"
    echo "Instala desde: https://cli.github.com/"
    exit 1
fi

# Labels de release
echo -e "${GREEN}📝 Creando labels de release...${NC}"

gh label create "release" \
    --color "0e8a16" \
    --description "Release PR to production" \
    --force 2>/dev/null && echo "  ✅ release" || echo "  ⚠️  release (ya existe)"

gh label create "ready-to-merge" \
    --color "0e8a16" \
    --description "Ready for automatic merge" \
    --force 2>/dev/null && echo "  ✅ ready-to-merge" || echo "  ⚠️  ready-to-merge (ya existe)"

gh label create "do-not-merge" \
    --color "b60205" \
    --description "Block automatic merge" \
    --force 2>/dev/null && echo "  ✅ do-not-merge" || echo "  ⚠️  do-not-merge (ya existe)"

# Labels de deployment
echo -e "\n${GREEN}🚀 Creando labels de deployment...${NC}"

gh label create "deployed-qa" \
    --color "fdcb6e" \
    --description "Deployed to QA environment" \
    --force 2>/dev/null && echo "  ✅ deployed-qa" || echo "  ⚠️  deployed-qa (ya existe)"

gh label create "deployed-staging" \
    --color "74b9ff" \
    --description "Deployed to Staging environment" \
    --force 2>/dev/null && echo "  ✅ deployed-staging" || echo "  ⚠️  deployed-staging (ya existe)"

gh label create "deployed-production" \
    --color "00b894" \
    --description "Deployed to Production environment" \
    --force 2>/dev/null && echo "  ✅ deployed-production" || echo "  ⚠️  deployed-production (ya existe)"

# Labels de riesgo
echo -e "\n${GREEN}⚠️  Creando labels de riesgo...${NC}"

gh label create "breaking-change" \
    --color "d73a4a" \
    --description "Contains breaking changes" \
    --force 2>/dev/null && echo "  ✅ breaking-change" || echo "  ⚠️  breaking-change (ya existe)"

gh label create "needs-review" \
    --color "fbca04" \
    --description "Requires additional code review" \
    --force 2>/dev/null && echo "  ✅ needs-review" || echo "  ⚠️  needs-review (ya existe)"

gh label create "rollback" \
    --color "e17055" \
    --description "Rollback to previous version" \
    --force 2>/dev/null && echo "  ✅ rollback" || echo "  ⚠️  rollback (ya existe)"

echo -e "\n${GREEN}✅ Labels creados exitosamente!${NC}"
echo -e "\n${YELLOW}📚 Uso:${NC}"
echo "  - release: Se agrega automáticamente a PRs de release"
echo "  - ready-to-merge: Habilita auto-merge después de aprobaciones"
echo "  - do-not-merge: Previene merge automático"
echo "  - deployed-*: Tracking de deployments por environment"
echo "  - breaking-change: Indica cambios que rompen compatibilidad"
echo "  - needs-review: Requiere revisión adicional antes de producción"
echo "  - rollback: Para PRs de rollback de versiones"
