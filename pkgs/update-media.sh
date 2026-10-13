#!/usr/bin/env bash
# Bump pkgs/nuvio + pkgs/bitchord to their latest releases.
# Both are perpetual alphas, so (unlike browsers) prereleases count:
# latest non-draft release wins. BitChord tags carry a `v` prefix that the
# asset filenames omit.
# Usage (from repo root): ./pkgs/update-media.sh
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

latest_tag() {
  local repo="$1"
  curl -fsSL "https://api.github.com/repos/${repo}/releases?per_page=10" |
    jq -r '.[] | select(.draft == false) | .tag_name' |
    head -n1
}

echo "== nuvio =="
NUVIO_TAG="$(latest_tag NuvioMedia/NuvioDesktop)"
NUVIO_FILE="Nuvio-Linux-x86_64-${NUVIO_TAG}.AppImage"
NUVIO_URL="https://github.com/NuvioMedia/NuvioDesktop/releases/download/${NUVIO_TAG}/${NUVIO_FILE}"
echo "tag: $NUVIO_TAG"
NUVIO_HASH="$(nix store prefetch-file --json "$NUVIO_URL" | jq -r .hash)"
jq -n --arg v "$NUVIO_TAG" --arg u "$NUVIO_URL" --arg h "$NUVIO_HASH" \
  '{version: $v, url: $u, hash: $h}' > "$ROOT/pkgs/nuvio/sources.json"

echo "== bitchord =="
BITCHORD_TAG="$(latest_tag kushagrasinghx/BitChord)"
BITCHORD_VER="${BITCHORD_TAG#v}"
BITCHORD_FILE="BitChord-${BITCHORD_VER}-linux-x86_64.AppImage"
BITCHORD_URL="https://github.com/kushagrasinghx/BitChord/releases/download/${BITCHORD_TAG}/${BITCHORD_FILE}"
echo "tag: $BITCHORD_TAG"
BITCHORD_HASH="$(nix store prefetch-file --json "$BITCHORD_URL" | jq -r .hash)"
jq -n --arg v "$BITCHORD_VER" --arg u "$BITCHORD_URL" --arg h "$BITCHORD_HASH" \
  '{version: $v, url: $u, hash: $h}' > "$ROOT/pkgs/bitchord/sources.json"

echo "done — review the diff, then: nh os switch"
