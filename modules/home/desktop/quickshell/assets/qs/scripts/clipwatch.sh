#!/usr/bin/env bash
set -e

CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/onix"
IMG_DIR="$CACHE_DIR/clipboard_images"
mkdir -p "$IMG_DIR"

types=$(wl-paste -l 2>/dev/null || true)
if [ -z "$types" ]; then
    exit 0
fi

# 1. Image Clipboard Handling
if echo "$types" | grep -q "^image/"; then
    mime=$(echo "$types" | grep "^image/" | head -n 1)
    tmp_file=$(mktemp "$IMG_DIR/tmp_XXXXXX")
    if wl-paste --type "$mime" > "$tmp_file" 2>/dev/null; then
        if [ -s "$tmp_file" ]; then
            hash=$(sha256sum "$tmp_file" | cut -d' ' -f1 | head -c 16)
            ext="png"
            if [[ "$mime" == *"jpeg"* ]] || [[ "$mime" == *"jpg"* ]]; then ext="jpg"; fi
            target="$IMG_DIR/${hash}.${ext}"
            mv -f "$tmp_file" "$target"
            size=$(stat -c%s "$target" 2>/dev/null || echo 0)

            # Auto-prune old image cache (keep last 50 files)
            (ls -t "$IMG_DIR"/*.png "$IMG_DIR"/*.jpg 2>/dev/null | tail -n +51 | xargs -r rm -f 2>/dev/null || true) &

            jq -c -n --arg type "image" --arg path "$target" --arg mime "$mime" --arg size "$size" \
               '{type: $type, filePath: $path, mime: $mime, size: ($size | tonumber)}'
            printf "\x1e"
        else
            rm -f "$tmp_file"
        fi
    else
        rm -f "$tmp_file"
    fi

# 2. Text Clipboard Handling
elif echo "$types" | grep -qE "(text/|STRING|TEXT)"; then
    raw=$(wl-paste 2>/dev/null || true)
    if [ -n "$raw" ]; then
        jq -c -n --arg type "text" --arg content "$raw" \
           '{type: $type, content: $content}'
        printf "\x1e"
    fi
fi
