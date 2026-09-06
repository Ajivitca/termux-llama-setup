#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

TAG="v1.0.0"
TITLE="Termux llama.cpp Vulkan installer"
NOTES_FILE="$HOME/termux-llama-setup/RELEASE_NOTES.md"

git add .
git commit -m "Release $TAG" || true

git tag -f -a "$TAG" -m "$TITLE"
git push origin "$TAG" -f

gh release create "$TAG" \
  --title "$TITLE" \
  --notes-file "$NOTES_FILE" \
  --verify-tag
