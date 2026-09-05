#!/data/data/com.termux/files/usr/bin/bash
set -e

MODEL_DIR="$HOME/models/gemma4-e4b"
MODEL_FILE="google_gemma-4-E4B-it-Q4_K_M.gguf"
MODEL_URL="https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/$MODEL_FILE?download=true"

mkdir -p "$MODEL_DIR"

if [ -f "$MODEL_DIR/$MODEL_FILE" ]; then
  echo "Model already exists: $MODEL_DIR/$MODEL_FILE"
  exit 0
fi

echo "Downloading model. This file is large; keep Termux open."
curl -L --fail --continue-at - \
  -o "$MODEL_DIR/$MODEL_FILE" \
  "$MODEL_URL"

echo "Saved: $MODEL_DIR/$MODEL_FILE"
