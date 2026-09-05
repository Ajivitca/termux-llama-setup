#!/data/data/com.termux/files/usr/bin/bash
set -e

ROOT="$HOME/termux-llama-setup"
BIN="$HOME/bin"
LLAMA="$HOME/llama.cpp"
MODEL_DIR="$HOME/models/gemma4-e4b"
MODEL="$MODEL_DIR/google_gemma-4-E4B-it-Q4_K_M.gguf"

pause(){ read -r -p "Press Enter to continue..."; }

build_llama(){
  echo "==> [1/3] Installing dependencies and building llama.cpp with Vulkan..."
  pkg update -y
  pkg upgrade -y
  pkg install -y git cmake clang make python curl ddgr vulkan-loader vulkan-tools vulkan-headers glslang
  if [ ! -d "$LLAMA/.git" ]; then git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA"; fi
  git -C "$LLAMA" pull --ff-only
  rm -rf "$LLAMA/build"
  cmake -S "$LLAMA" -B "$LLAMA/build" -DCMAKE_BUILD_TYPE=Release -DGGML_VULKAN=ON
  cmake --build "$LLAMA/build" -j"$(nproc)"
  test -x "$LLAMA/build/bin/llama-server"
  echo "OK: Vulkan llama-server built."
}

download_model(){
  echo "==> [2/3] Downloading Gemma 4 E4B Q4_K_M..."
  mkdir -p "$MODEL_DIR"
  if [ -f "$MODEL" ]; then echo "Model already exists: $MODEL"; return; fi
  curl -L --fail --continue-at - -o "$MODEL" "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_M.gguf?download=true"
  test -s "$MODEL"
  ls -lh "$MODEL"
}

install_scripts(){
  echo "==> [3/3] Installing gemma4 commands..."
  mkdir -p "$BIN"
  cp "$ROOT/scripts/gemma4" "$BIN/gemma4"
  cp "$ROOT/scripts/gemma-web" "$BIN/gemma-web"
  cp "$ROOT/scripts/gemma-temp" "$BIN/gemma-temp"
  chmod +x "$BIN/gemma4" "$BIN/gemma-web" "$BIN/gemma-temp" "$ROOT/scripts/start-server.sh"
  grep -qxF 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$BIN:$PATH"
  command -v gemma4
  echo "OK: scripts installed."
}

tests(){
  export PATH="$BIN:$PATH"
  echo "==> Test 1: installed CLI"
  gemma4 --help
  pause
  echo "==> Test 2: model file"
  ls -lh "$MODEL"
  pause
  echo "==> Test 3: Vulkan build flag"
  grep "GGML_VULKAN:BOOL=ON" "$LLAMA/build/CMakeCache.txt" || echo "WARNING: Vulkan flag was not found."
  pause
  echo "==> Test 4: start server in another Termux session:"
  echo "bash ~/termux-llama-setup/scripts/start-server.sh"
  pause
  echo "==> Test 5: local server health"
  curl --fail http://127.0.0.1:8080/health && echo
  pause
  echo "==> Test 6: local-only request"
  gemma4 --local "Say: local model is working."
  pause
  echo "==> Test 7: automatic web routing"
  gemma4 "What is the current weather in Moscow?"
  pause
  echo "==> Test 8: reasoning mode"
  gemma4 --reasoning "Solve step by step: 180 km in 3 hours. What is the average speed?"
  pause
  echo "==> Test 9: thermal output"
  gemma4 --verbose1 "Briefly explain TCP handshake."
}

echo "Gemma 4 E4B / POCO F8 Ultra installer"
echo "Enter = automatic full installation"
echo "1 = build llama.cpp with Vulkan"
echo "2 = download model"
echo "3 = install scripts"
echo "4 = run tests"
read -r -p "Choose [Enter/1/2/3/4]: " choice
case "$choice" in
  "") build_llama; pause; download_model; pause; install_scripts; pause; echo "Installation complete. Start server: bash ~/termux-llama-setup/scripts/start-server.sh";;
  1) build_llama;;
  2) download_model;;
  3) install_scripts;;
  4) tests;;
  *) echo "Unknown option."; exit 1;;
esac
