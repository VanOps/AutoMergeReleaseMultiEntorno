#!/bin/bash
# create-release-branch.sh - Crea una rama de release desde develop

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Release Branch Creator${NC}"
echo ""

# Verificar que gh CLI está instalado
if ! command -v gh &> /dev/null; then
    echo -e "${YELLOW}⚠️  Warning: gh CLI no está instalado${NC}"
    echo "Algunas funcionalidades estarán limitadas"
fi

# Pedir versión
echo -e "${GREEN}📝 Ingresa la versión del release (ej: v2.0, v1.5.1):${NC}"
read -p "Version: " VERSION

if [ -z "$VERSION" ]; then
    echo -e "${RED}❌ Error: Debes ingresar una versión${NC}"
    exit 1
fi

# Limpiar versión (agregar 'v' si no lo tiene)
if [[ ! $VERSION == v* ]]; then
    VERSION="v$VERSION"
fi

RELEASE_BRANCH="release/$VERSION"

# Verificar si la rama ya existe
if git show-ref --verify --quiet refs/heads/$RELEASE_BRANCH; then
    echo -e "${RED}❌ Error: La rama $RELEASE_BRANCH ya existe${NC}"
    exit 1
fi

# Asegurarse de estar en develop y actualizado
echo -e "${BLUE}📥 Actualizando rama develop...${NC}"
git checkout develop
git pull origin develop

# Crear rama de release
echo -e "${GREEN}🌿 Creando rama $RELEASE_BRANCH...${NC}"
git checkout -b $RELEASE_BRANCH

# Opcional: actualizar version en package.json si existe
if [ -f "src/app/package.json" ]; then
    echo -e "${BLUE}📝 ¿Actualizar version en package.json? (y/n)${NC}"
    read -p "Update: " UPDATE_PACKAGE
    
    if [ "$UPDATE_PACKAGE" = "y" ]; then
        cd src/app
        npm version ${VERSION#v} --no-git-tag-version
        cd ../..
        git add src/app/package.json
        git commit -m "chore: Bump version to $VERSION"
    fi
fi

# Push de la rama
echo -e "${GREEN}📤 Pushing rama $RELEASE_BRANCH...${NC}"
git push -u origin $RELEASE_BRANCH

echo ""
echo -e "${GREEN}✅ Rama de release creada exitosamente!${NC}"
echo ""
echo -e "${BLUE}📊 Información del release:${NC}"
echo -e "  Rama: ${YELLOW}$RELEASE_BRANCH${NC}"
echo -e "  Versión: ${YELLOW}$VERSION${NC}"
echo ""
echo -e "${BLUE}🔄 Próximos pasos:${NC}"
echo "  1. El pipeline de CI se ejecutará automáticamente"
echo "  2. Se desplegará a QA automáticamente"
echo "  3. Aprobar manualmente para Staging"
echo "  4. Aprobar manualmente para Production"
echo ""
echo -e "${BLUE}📝 Para ver el progreso:${NC}"
echo "  gh run list --branch $RELEASE_BRANCH"
echo ""
echo -e "${BLUE}🌐 Ver en GitHub:${NC}"
if command -v gh &> /dev/null; then
    REPO_URL=$(gh repo view --json url --jq .url)
    echo "  $REPO_URL/tree/$RELEASE_BRANCH"
fi
