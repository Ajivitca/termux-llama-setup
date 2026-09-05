#!/data/data/com.termux/files/usr/bin/bash
set -e

LLAMA_SERVER="$HOME/llama.cpp/build/bin/llama-server"
MODEL="$HOME/models/gemma4-e4b/google_gemma-4-E4B-it-Q4_K_M.gguf"

if [ ! -x "$LLAMA_SERVER" ]; then
  echo "llama-server was not found: $LLAMA_SERVER"
  echo "Run: bash ~/termux-llama-setup/scripts/build-llama.sh"
  exit 1
fi

if [ ! -f "$MODEL" ]; then
  echo "Model was not found: $MODEL"
  echo "Run: bash ~/termux-llama-setup/scripts/download-model.sh"
  exit 1
fi

exec "$LLAMA_SERVER" \
  -m "$MODEL" \
  -c 2048 \
  -t 6 \
  -ngl 99 \
  --host 127.0.0.1 \
  --port 8080 \
  --alias gemma4-e4b-phone \
  --reasoning off \
  --reasoning-budget 0
