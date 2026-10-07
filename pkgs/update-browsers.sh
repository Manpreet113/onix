#!/usr/bin/env bash
# Bump pkgs/zen-browser and pkgs/helium-browser to their latest STABLE tags.
# Twilight/nightly builds are deliberately skipped: upstream re-uploads those
# artifacts, which breaks pinned hashes.
# Usage (from repo root): ./pkgs/update-browsers.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

latest_stable_tag() {
  local repo="$1" pattern="$2"
  curl -fsSL "https://api.github.com/repos/${repo}/releases?per_page=20" |
    jq -r --arg pat "$pattern" '.[] | select(.prerelease == false) | .tag_name | select(test($pat))' |
    head -n1
}

echo "== zen-browser (stable: <x.y[.z]b>) =="
ZEN_TAG="$(latest_stable_tag zen-browser/desktop '^[0-9.]+b$')"
ZEN_URL="https://github.com/zen-browser/desktop/releases/download/${ZEN_TAG}/zen.linux-x86_64.tar.xz"
echo "tag: $ZEN_TAG"
ZEN_JSON="$(nix store prefetch-file --json "$ZEN_URL")"
ZEN_HASH="$(echo "$ZEN_JSON" | jq -r .hash)"
ZEN_STORE="$(echo "$ZEN_JSON" | jq -r .storePath)"
ZEN_FF="$(tar -xOf "$ZEN_STORE" zen/platform.ini | grep '^Milestone=' | cut -d= -f2 | cut -d. -f1-2)"
jq -n --arg v "$ZEN_TAG" --arg ff "$ZEN_FF" --arg u "$ZEN_URL" --arg h "$ZEN_HASH" \
  '{version: $v, firefoxVersion: $ff, url: $u, hash: $h}' > "$ROOT/pkgs/zen-browser/sources.json"
echo "firefox base: $ZEN_FF"

echo "== helium-browser (stable: x.y.z.w) =="
HE_TAG="$(latest_stable_tag imputnet/helium-linux '^[0-9.]+$')"
HE_URL="https://github.com/imputnet/helium-linux/releases/download/${HE_TAG}/helium-${HE_TAG}-x86_64_linux.tar.xz"
echo "tag: $HE_TAG"
HE_HASH="$(nix store prefetch-file --json "$HE_URL" | jq -r .hash)"
jq -n --arg v "$HE_TAG" --arg u "$HE_URL" --arg h "$HE_HASH" \
  '{version: $v, url: $u, hash: $h}' > "$ROOT/pkgs/helium-browser/sources.json"

echo "done — review the diff, then: nh os switch"
