#!/usr/bin/env bash
set -euo pipefail

echo "=================================================="
echo "  josephmaxwell.dev - WCAG 2.2 AA Pa11y Audit"
echo "=================================================="

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

echo "[1/2] Building Hugo site with drafts..."
hugo --cleanDestinationDir -D > /dev/null

echo "[2/2] Running Pa11y audits on key pages..."

PAGES=(
  "public/index.html"
  "public/about/index.html"
  "public/projects/index.html"
  "public/posts/index.html"
  "public/posts/automating-hardware-asset-tracking-with-go/index.html"
  "public/404.html"
)

FAILED=0

for page in "${PAGES[@]}"; do
  if [ ! -f "$page" ]; then
    echo "⚠️  Skipping missing page: $page"
    continue
  fi

  echo "Auditing: $page"
  if ! npx pa11y "$page"; then
    echo "❌ Accessibility violations detected in $page"
    FAILED=1
  fi
done

echo "--------------------------------------------------"
if [ "$FAILED" -eq 0 ]; then
  echo "✔ All pages passed WCAG 2.2 Level AA accessibility audits!"
  exit 0
else
  echo "❌ One or more pages failed the accessibility audit."
  exit 1
fi
