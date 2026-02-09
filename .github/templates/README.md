# PR Body Templates

Este directorio contiene plantillas para los cuerpos de Pull Requests creados automáticamente por el pipeline de release.

## 📄 Archivos

### `release_pr_body.md`
Plantilla para PRs de release a `main` branch (producción).

**Variables disponibles:**
- `${VERSION}` - Número de versión del release (ej: v1.0.0)
- `${DEPLOY_TIME}` - Timestamp del deployment

**Usado en:** Job `create-release-pr`

---

### `backmerge_pr_body.md`
Plantilla para PRs de back-merge de `main` a `develop` sin conflictos.

**Variables disponibles:**
- `${VERSION}` - Número de versión del release

**Usado en:** Job `back-merge` (cuando no hay conflictos)

---

### `backmerge_pr_body_conflicts.md`
Plantilla para PRs de back-merge de `main` a `develop` con conflictos detectados.

**Variables disponibles:**
- `${VERSION}` - Número de versión del release

**Usado en:** Job `back-merge` (cuando hay conflictos)

---

## 🔧 Cómo Editar

1. Edita el archivo `.md` correspondiente
2. Usa la sintaxis `${VARIABLE}` para valores dinámicos
3. El workflow reemplazará automáticamente las variables con `sed`
4. Soporta Markdown completo, incluyendo tablas, listas, y checkboxes

## 📝 Ejemplo de Uso en Workflow

```yaml
# Copiar template y reemplazar variables
cp .github/templates/release_pr_body.md release_notes.md
sed -i "s/\${VERSION}/$VERSION/g" release_notes.md
sed -i "s/\${DEPLOY_TIME}/$DEPLOY_TIME/g" release_notes.md

# Usar en gh pr create
gh pr create --body-file release_notes.md
```

## ✅ Beneficios

- ✅ Workflow más limpio y legible
- ✅ Fácil de editar sin tocar el YAML
- ✅ Separación de contenido y lógica
- ✅ Control de versiones del contenido
- ✅ Reutilizable en múltiples workflows
