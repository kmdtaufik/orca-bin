#!/usr/bin/env bash
set -euo pipefail

VERSIONS_FILE="${PWD}/versions.json"
if [[ ! -f "$VERSIONS_FILE" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  VERSIONS_FILE="$SCRIPT_DIR/versions.json"
fi

REPO="stablyai/orca"

FORCE=false
if [[ "${1:-}" == "--force" || "${1:-}" == "-f" ]]; then
  FORCE=true
fi

echo "==> Checking for latest release of $REPO..."

# Fetch latest release tag
LATEST_TAG=""
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  LATEST_TAG=$(curl -sSL -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$REPO/releases/latest" 2>/dev/null | grep -m1 '"tag_name":' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/' || true)
fi

if [[ -z "$LATEST_TAG" ]]; then
  LATEST_TAG=$(curl -ILs "https://github.com/$REPO/releases/latest" | grep -i '^location:' | sed -E 's|.*/tag/||' | tr -d '\r\n' || true)
fi

if [[ -z "$LATEST_TAG" ]]; then
  echo "Error: Failed to fetch latest release tag from GitHub" >&2
  exit 1
fi

LATEST_VERSION="${LATEST_TAG#v}"

CURRENT_VERSION="none"
if [[ -f "$VERSIONS_FILE" ]]; then
  CURRENT_VERSION=$(grep -m1 '"version":' "$VERSIONS_FILE" | sed -E 's/.*"version": *"([^"]+)".*/\1/' || true)
fi

echo "Current version: $CURRENT_VERSION"
echo "Latest version:  $LATEST_VERSION"

if [[ "$LATEST_VERSION" == "$CURRENT_VERSION" && "$FORCE" != "true" ]]; then
  echo "==> Already up to date."
  exit 0
fi

DOWNLOAD_URL="https://github.com/$REPO/releases/download/v${LATEST_VERSION}/orca-linux.AppImage"
echo "==> Prefetching hash for $DOWNLOAD_URL..."

RAW_HASH=$(nix-prefetch-url "$DOWNLOAD_URL")
SRI_HASH=$(nix-hash --to-sri --type sha256 "$RAW_HASH")

echo "==> Computed SRI hash: $SRI_HASH"

cat <<EOF > "$VERSIONS_FILE.tmp"
{
  "version": "$LATEST_VERSION",
  "hash": "$SRI_HASH"
}
EOF

mv "$VERSIONS_FILE.tmp" "$VERSIONS_FILE"
echo "==> Successfully updated $VERSIONS_FILE to version $LATEST_VERSION"
