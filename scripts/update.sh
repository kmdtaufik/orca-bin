#!/usr/bin/env bash
set -euo pipefail

VERSIONS_FILE="${PWD}/pkgs/orca-ide/versions.json"
if [[ ! -f "$VERSIONS_FILE" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  REPO_ROOT="$(cd "$SCRIPT_DIR/.." 2>/dev/null && pwd)"
  if [[ -f "${REPO_ROOT}/pkgs/orca-ide/versions.json" ]]; then
    VERSIONS_FILE="${REPO_ROOT}/pkgs/orca-ide/versions.json"
  fi
fi

if [[ ! -f "$VERSIONS_FILE" ]]; then
  echo "Error: versions file not found at $VERSIONS_FILE" >&2
  exit 1
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

URL_X86="https://github.com/$REPO/releases/download/v${LATEST_VERSION}/orca-linux.AppImage"
URL_ARM="https://github.com/$REPO/releases/download/v${LATEST_VERSION}/orca-linux-arm64.AppImage"

echo "==> Prefetching x86_64-linux hash for $URL_X86..."
RAW_HASH_X86=$(nix-prefetch-url "$URL_X86")
SRI_HASH_X86=$(nix-hash --to-sri --type sha256 "$RAW_HASH_X86")
echo "==> Computed x86_64 SRI hash: $SRI_HASH_X86"

echo "==> Prefetching aarch64-linux hash for $URL_ARM..."
RAW_HASH_ARM=$(nix-prefetch-url "$URL_ARM")
SRI_HASH_ARM=$(nix-hash --to-sri --type sha256 "$RAW_HASH_ARM")
echo "==> Computed aarch64 SRI hash: $SRI_HASH_ARM"

cat <<EOF > "$VERSIONS_FILE.tmp"
{
  "version": "$LATEST_VERSION",
  "x86_64-linux": "$SRI_HASH_X86",
  "aarch64-linux": "$SRI_HASH_ARM"
}
EOF

mv "$VERSIONS_FILE.tmp" "$VERSIONS_FILE"
echo "==> Successfully updated $VERSIONS_FILE to version $LATEST_VERSION"
