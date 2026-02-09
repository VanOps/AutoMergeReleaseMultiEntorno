#!/bin/bash
# check-repo-config.sh - Release Multi-Environment Auto-Merge Configuration Checker

REPO="$1"
if [ -z "$REPO" ]; then
  REPO=$(gh repo view --json nameWithOwner -q .nameWithOwner)
fi

echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Release Multi-Environment Auto-Merge Configuration Check ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📁 Repository: $REPO"
echo ""

# Verificar si estamos en el directorio correcto
if [ ! -d ".github/workflows" ]; then
  echo "⚠️  WARNING: Not in repository root or .github/workflows not found"
  echo ""
fi

echo "🌿 Required Branches:"
REQUIRED_BRANCHES=("main" "develop")
MISSING_BRANCHES=0
for branch in "${REQUIRED_BRANCHES[@]}"; do
  if gh api repos/$REPO/branches/$branch >/dev/null 2>&1; then
    echo "  ✅ $branch exists"
  else
    echo "  ❌ $branch missing"
    MISSING_BRANCHES=$((MISSING_BRANCHES + 1))
  fi
done

echo ""
echo "📋 Workflow Files:"
WORKFLOW_FOUND=0
if [ -f ".github/workflows/release-pipeline.yml" ]; then
  echo "  ✅ release-pipeline.yml exists"
  WORKFLOW_FOUND=$((WORKFLOW_FOUND + 1))
else
  echo "  ❌ release-pipeline.yml missing"
fi

echo ""
echo "🌍 GitHub Environments:"
ENVIRONMENTS=("qa" "staging" "production")
ENV_CHECK=()
for env in "${ENVIRONMENTS[@]}"; do
  ENV_INFO=$(gh api repos/$REPO/environments/$env 2>/dev/null)
  if [ $? -eq 0 ]; then
    echo "  ✅ Environment '$env' exists"
    
    # Verificar deployment branches
    DEPLOYMENT_BRANCH_POLICY=$(echo "$ENV_INFO" | jq -r '.deployment_branch_policy.protected_branches // false')
    CUSTOM_BRANCHES=$(echo "$ENV_INFO" | jq -r '.deployment_branch_policy.custom_branch_policies // false')
    
    # Verificar protection rules
    REVIEWERS=$(echo "$ENV_INFO" | jq -r '[.protection_rules[]? | select(.type == "required_reviewers")] | length')
    WAIT_TIMER=$(echo "$ENV_INFO" | jq -r '[.protection_rules[]? | select(.type == "wait_timer")] | length')
    
    echo "    Reviewers required: $([ "$REVIEWERS" -gt 0 ] && echo "Yes ($REVIEWERS rule(s))" || echo "No")"
    echo "    Wait timer: $([ "$WAIT_TIMER" -gt 0 ] && echo "Yes" || echo "No")"
    echo "    Deployment branches: $([ "$DEPLOYMENT_BRANCH_POLICY" == "true" ] && echo "Protected branches only" || echo "Custom policy")"
    
    # Guardar para validación posterior
    ENV_CHECK[$env]="found"
  else
    echo "  ❌ Environment '$env' missing"
    ENV_CHECK[$env]="missing"
  fi
  echo ""
done

echo "🤖 GitHub Actions Permissions:"
ACTIONS_PERMS=$(gh api repos/$REPO/actions/permissions)
ACTIONS_ENABLED=$(echo "$ACTIONS_PERMS" | jq -r '.enabled')
CAN_APPROVE=$(echo "$ACTIONS_PERMS" | jq -r '.can_approve_pull_request_reviews')
DEFAULT_WORKFLOW_PERMS=$(echo "$ACTIONS_PERMS" | jq -r '.default_workflow_permissions')

# Detectar si los campos existen en la respuesta de la API
CAN_APPROVE_AVAILABLE=true
WORKFLOW_PERMS_AVAILABLE=true

if [ "$CAN_APPROVE" == "null" ] || [ -z "$CAN_APPROVE" ]; then
  CAN_APPROVE_AVAILABLE=false
  CAN_APPROVE="N/A"
fi

if [ "$DEFAULT_WORKFLOW_PERMS" == "null" ] || [ -z "$DEFAULT_WORKFLOW_PERMS" ]; then
  WORKFLOW_PERMS_AVAILABLE=false
  DEFAULT_WORKFLOW_PERMS="N/A"
fi

echo "  Actions enabled: $ACTIONS_ENABLED"
echo "  Default permissions: $DEFAULT_WORKFLOW_PERMS"
echo "  Can create and approve PRs: $CAN_APPROVE"

echo ""
echo "🔀 Merge Settings:"
REPO_INFO=$(gh api repos/$REPO)
ALLOW_MERGE_COMMIT=$(echo "$REPO_INFO" | jq -r '.allow_merge_commit')
ALLOW_SQUASH_MERGE=$(echo "$REPO_INFO" | jq -r '.allow_squash_merge')
ALLOW_REBASE_MERGE=$(echo "$REPO_INFO" | jq -r '.allow_rebase_merge')
AUTO_MERGE=$(echo "$REPO_INFO" | jq -r '.allow_auto_merge')

echo "  Merge commit allowed: $ALLOW_MERGE_COMMIT"
echo "  Squash merge allowed: $ALLOW_SQUASH_MERGE"
echo "  Rebase merge allowed: $ALLOW_REBASE_MERGE"
echo "  Auto-merge enabled: $AUTO_MERGE"

echo ""
echo "🔒 Branch Protection Rules:"

# Verificar main
echo "  main:"
MAIN_PROTECTION=$(gh api repos/$REPO/branches/main/protection 2>/dev/null)
if [ $? -eq 0 ]; then
  REQUIRE_PR=$(echo "$MAIN_PROTECTION" | jq -r '.required_pull_request_reviews != null')
  APPROVALS=$(echo "$MAIN_PROTECTION" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
  REQUIRE_CHECKS=$(echo "$MAIN_PROTECTION" | jq -r '.required_status_checks != null')
  REQUIRED_CHECKS=$(echo "$MAIN_PROTECTION" | jq -r '.required_status_checks.checks // [] | length')
  ALLOW_AUTO_MERGE=$(echo "$MAIN_PROTECTION" | jq -r '.allow_auto_merge.enabled // false')
  
  echo "    ✅ Protected"
  echo "    Require PRs: $REQUIRE_PR"
  echo "    Required approvals: $APPROVALS"
  echo "    Require status checks: $REQUIRE_CHECKS ($REQUIRED_CHECKS checks)"
  echo "    Allow auto-merge: $ALLOW_AUTO_MERGE"
else
  echo "    ❌ No protection rules configured"
fi

# Verificar develop
echo ""
echo "  develop:"
DEVELOP_PROTECTION=$(gh api repos/$REPO/branches/develop/protection 2>/dev/null)
if [ $? -eq 0 ]; then
  REQUIRE_PR=$(echo "$DEVELOP_PROTECTION" | jq -r '.required_pull_request_reviews != null')
  APPROVALS=$(echo "$DEVELOP_PROTECTION" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
  
  echo "    ✅ Protected"
  echo "    Require PRs: $REQUIRE_PR"
  echo "    Required approvals: $APPROVALS"
else
  echo "    ❌ No protection rules configured"
fi

# Verificar release/* (si existe alguna rama de release)
echo ""
echo "  release/* pattern:"
RELEASE_PROTECTION=$(gh api repos/$REPO/branches 2>/dev/null | jq -r '.[] | select(.name | startswith("release/")) | .name' | head -n 1)
if [ ! -z "$RELEASE_PROTECTION" ]; then
  RELEASE_BRANCH_PROTECTION=$(gh api repos/$REPO/branches/$RELEASE_PROTECTION/protection 2>/dev/null)
  if [ $? -eq 0 ]; then
    REQUIRE_PR=$(echo "$RELEASE_BRANCH_PROTECTION" | jq -r '.required_pull_request_reviews != null')
    APPROVALS=$(echo "$RELEASE_BRANCH_PROTECTION" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
    
    echo "    ✅ Protected (checked: $RELEASE_PROTECTION)"
    echo "    Require PRs: $REQUIRE_PR"
    echo "    Required approvals: $APPROVALS"
  else
    echo "    ⚠️  No protection rules (checked: $RELEASE_PROTECTION)"
  fi
else
  echo "    ℹ️  No release branches found to check pattern protection"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║              Configuration Issues Found                    ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Check critical settings for Release Multi-Environment
ISSUES_FOUND=0
WARNINGS=0

# 1. Verificar ramas requeridas
if [ $MISSING_BRANCHES -gt 0 ]; then
  echo "❌ CRITICAL: Missing $MISSING_BRANCHES required branch(es)"
  echo "   Required branches: main, develop"
  echo "   Fix: Create the missing branches"
  echo "   git checkout -b develop && git push -u origin develop"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 2. Verificar workflow
if [ $WORKFLOW_FOUND -eq 0 ]; then
  echo "❌ CRITICAL: release-pipeline.yml workflow not found"
  echo "   Fix: Create .github/workflows/release-pipeline.yml"
  echo "   See: AutoMergeReleaseMultiEntorno/README.md for complete workflow template"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 3. Verificar environments
MISSING_ENVS=()
for env in "${ENVIRONMENTS[@]}"; do
  if [ "${ENV_CHECK[$env]}" != "found" ]; then
    MISSING_ENVS+=("$env")
  fi
done

if [ ${#MISSING_ENVS[@]} -gt 0 ]; then
  echo "❌ CRITICAL: Missing GitHub Environments: ${MISSING_ENVS[*]}"
  echo "   Fix: Settings → Environments → New environment"
  echo "   Required environments:"
  echo "   - qa: No reviewers, auto-deploy, release/* branches"
  echo "   - staging: 1-2 reviewers, release/* branches"
  echo "   - production: 2+ reviewers, 5 min wait timer, main branch only"
  echo "   See: AutoMergeReleaseMultiEntorno/README.md - Section 'Configurar GitHub Environments'"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 4. Verificar permisos de Actions
if [ "$CAN_APPROVE_AVAILABLE" == "false" ]; then
  echo "ℹ️  INFO: Cannot verify PR approval permissions via GitHub API"
  echo "   This is normal for some repository types"
  echo "   Please manually verify in GitHub Settings → Actions → General:"
  echo "   1. Workflow permissions: 'Read and write permissions' (should be selected)"
  echo "   2. Check: '☑ Allow GitHub Actions to create and approve pull requests'"
  echo ""
  echo "   The release pipeline REQUIRES these settings to work properly"
elif [ "$CAN_APPROVE" == "false" ]; then
  echo "❌ CRITICAL: Actions cannot create and approve pull requests"
  echo "   Fix: Settings → Actions → General → Workflow permissions:"
  echo "   ✓ Read and write permissions"
  echo "   ✓ Allow GitHub Actions to create and approve pull requests"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 5. Verificar al menos un método de merge habilitado
if [ "$ALLOW_MERGE_COMMIT" != "true" ] && [ "$ALLOW_SQUASH_MERGE" != "true" ] && [ "$ALLOW_REBASE_MERGE" != "true" ]; then
  echo "❌ CRITICAL: No merge method is enabled"
  echo "   Fix: Settings → General → Pull Requests:"
  echo "   Enable at least one: Merge commits, Squash, or Rebase"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 6. Verificar Actions habilitado
if [ "$ACTIONS_ENABLED" != "true" ]; then
  echo "❌ CRITICAL: GitHub Actions is disabled"
  echo "   Fix: Settings → Actions → General:"
  echo "   ✓ Enable GitHub Actions for this repository"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 7. Verificar auto-merge habilitado en el repositorio
if [ "$AUTO_MERGE" != "true" ]; then
  echo "❌ CRITICAL: Auto-merge is not enabled in repository settings"
  echo "   Fix: Settings → General → Pull Requests:"
  echo "   ✓ Allow auto-merge"
  echo "   This is required for PRs to merge automatically after approvals"
  ISSUES_FOUND=$((ISSUES_FOUND + 1))
fi

# 8. Advertencias para branch protection
echo ""
echo "Branch Protection Recommendations:"

# Verificar main tiene protección adecuada
if [ $? -eq 0 ]; then
  MAIN_PROTECTION=$(gh api repos/$REPO/branches/main/protection 2>/dev/null)
  APPROVALS=$(echo "$MAIN_PROTECTION" | jq -r '.required_pull_request_reviews.required_approving_review_count // 0')
  
  if [ "$APPROVALS" -lt 2 ]; then
    echo "⚠️  WARNING: main branch should require at least 2 approvals"
    echo "   Recommended: Settings → Branches → main → Require approvals: 2"
    WARNINGS=$((WARNINGS + 1))
  fi
  
  REQUIRE_CHECKS=$(echo "$MAIN_PROTECTION" | jq -r '.required_status_checks != null')
  if [ "$REQUIRE_CHECKS" != "true" ]; then
    echo "⚠️  WARNING: main branch should require status checks"
    echo "   Recommended: Require '🏗️ Build Release Artifacts' to pass"
    WARNINGS=$((WARNINGS + 1))
  fi
  
  ALLOW_AUTO_MERGE=$(echo "$MAIN_PROTECTION" | jq -r '.allow_auto_merge.enabled // false')
  if [ "$ALLOW_AUTO_MERGE" != "true" ]; then
    echo "⚠️  WARNING: main branch should allow auto-merge"
    echo "   Recommended: Settings → Branches → main → Allow auto-merge"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

# Verificar develop tiene protección
DEVELOP_PROTECTION=$(gh api repos/$REPO/branches/develop/protection 2>/dev/null)
if [ $? -ne 0 ]; then
  echo "⚠️  WARNING: develop branch has no protection rules"
  echo "   Recommended: Configure protection with at least 1 approval"
  WARNINGS=$((WARNINGS + 1))
fi

# Verificar permisos de workflow
if [ "$WORKFLOW_PERMS_AVAILABLE" == "false" ]; then
  echo "ℹ️  INFO: Cannot determine default workflow permissions from GitHub API"
  echo "   Please verify manually: Settings → Actions → General → Workflow permissions"
  echo "   Should be set to: 'Read and write permissions'"
elif [ "$DEFAULT_WORKFLOW_PERMS" == "read" ]; then
  echo "⚠️  WARNING: Default workflow permissions is 'read'"
  echo "   Recommendation: Settings → Actions → General → Workflow permissions:"
  echo "   ✓ Select 'Read and write permissions'"
  WARNINGS=$((WARNINGS + 1))
fi

echo ""
if [ $ISSUES_FOUND -eq 0 ] && [ $WARNINGS -eq 0 ]; then
  echo "✅ All configurations are correct for Release Multi-Environment Pipeline!"
  echo ""
  echo "🚀 Next steps:"
  echo "   1. Create a release branch: ./scripts/create-release-branch.sh"
  echo "   2. Push the branch and watch the pipeline execute"
  echo "   3. QA deployment happens automatically"
  echo "   4. Approve Staging deployment in GitHub UI"
  echo "   5. Pipeline creates PR to main automatically"
  echo "   6. After merge, approve Production deployment"
  echo "   7. Back-merge to develop happens automatically"
elif [ $ISSUES_FOUND -eq 0 ]; then
  echo "✅ Critical configurations are correct!"
  echo "⚠️  Found $WARNINGS warning(s) - pipeline will work but should be optimized"
else
  echo "❌ Found $ISSUES_FOUND critical issue(s) that will prevent the pipeline from working"
  if [ $WARNINGS -gt 0 ]; then
    echo "⚠️  Also found $WARNINGS warning(s)"
  fi
  echo ""
  echo "📚 See documentation for detailed setup:"
  echo "   - AutoMergeReleaseMultiEntorno/README.md"
  echo "   - docs/ReleaseMultiEntorno.md"
fi

echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║                    Quick Reference                         ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "📖 Pipeline Flow:"
echo "   develop → release/vX.X → QA → Staging (approval) → PR to main → Production (approval) → back-merge to develop"
echo ""
echo "🔧 Available scripts:"
echo "   ./scripts/create-release-branch.sh     - Create new release branch"
echo "   ./scripts/setup-environments.sh        - Guide to configure environments"
echo "   ./scripts/check_repo_config.sh         - Run this health check"
echo ""
echo "🌍 Environment Configuration Summary:"
echo "   QA:         No approvals, auto-deploy, release/* branches"
echo "   Staging:    1-2 approvers, release/* branches"
echo "   Production: 2+ approvers, 5min wait timer, main branch only"
echo ""
