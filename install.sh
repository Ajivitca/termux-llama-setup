#!/data/data/com.termux/files/usr/bin/bash
set -e
ROOT="$HOME/termux-llama-setup"
BIN="$HOME/bin"
LLAMA="$HOME/llama.cpp"
SHADERC="$HOME/shaderc"
MODEL_DIR="$HOME/models/gemma4-e4b"
MODEL="$MODEL_DIR/google_gemma-4-E4B-it-Q4_K_M.gguf"
pause(){ read -r -p "Press Enter to continue..."; }
build_llama(){
  echo "Installing dependencies..."
  pkg update -y
  pkg upgrade -y
  pkg install -y git cmake clang make ninja python curl vulkan-loader vulkan-tools vulkan-headers glslang bison
  pip install --break-system-packages ddgr
  echo "Building Shaderc and glslc..."
  if [ ! -d "$SHADERC/.git" ]; then git clone https://github.com/google/shaderc.git "$SHADERC"; fi
  cd "$SHADERC"
  ./utils/git-sync-deps
  cmake -S "$SHADERC" -B "$SHADERC/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DSHADERC_SKIP_TESTS=ON
  cmake --build "$SHADERC/build" --target glslc -j"$(nproc)"
  test -x "$SHADERC/build/glslc/glslc"
  echo "Building llama.cpp with Vulkan..."
  if [ ! -d "$LLAMA/.git" ]; then git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA"; fi
  git -C "$LLAMA" pull --ff-only
  rm -rf "$LLAMA/build"
  cmake -S "$LLAMA" -B "$LLAMA/build" -G Ninja -DCMAKE_BUILD_TYPE=Release -DGGML_VULKAN=ON -DVulkan_GLSLC_EXECUTABLE="$SHADERC/build/glslc/glslc"
  cmake --build "$LLAMA/build" -j"$(nproc)"
  test -x "$LLAMA/build/bin/llama-server"
  echo "OK: Vulkan llama-server built."
}
download_model(){
  mkdir -p "$MODEL_DIR"
  if [ -f "$MODEL" ]; then echo "Model already exists: $MODEL"; return; fi
  curl -L --fail --continue-at - -o "$MODEL" "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_M.gguf?download=true"
  test -s "$MODEL"
  ls -lh "$MODEL"
}
install_scripts(){
  mkdir -p "$BIN"
  cp "$ROOT/scripts/gemma4" "$BIN/gemma4"
  cp "$ROOT/scripts/gemma-web" "$BIN/gemma-web"
  cp "$ROOT/scripts/gemma-temp" "$BIN/gemma-temp"
  chmod +x "$BIN/gemma4" "$BIN/gemma-web" "$BIN/gemma-temp"
  grep -qxF 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null || echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"
  export PATH="$BIN:$PATH"
  command -v gemma4
  echo "OK: CLI scripts installed."
}
tests(){
  export PATH="$BIN:$PATH"
  echo "Test 1: CLI"; gemma4 --help; pause
  echo "Test 2: model"; ls -lh "$MODEL"; pause
  echo "Test 3: Vulkan"; grep "GGML_VULKAN:BOOL=ON" "$LLAMA/build/CMakeCache.txt"; test -x "$SHADERC/build/glslc/glslc"; echo "OK: Vulkan and glslc found."; pause
  echo "Start server in another Termux session:"; echo "bash ~/termux-llama-setup/scripts/start-server.sh"; pause
  echo "Test 4: health"; curl --fail http://127.0.0.1:8080/health; echo; pause
  echo "Test 5: local"; gemma4 --local "Say: local model is working."; pause
  echo "Test 6: automatic web"; gemma4 "What is the current weather in Moscow?"; pause
  echo "Test 7: reasoning"; gemma4 --reasoning "Solve step by step: 180 km in 3 hours. What is the average speed?"; pause
  echo "Test 8: temperatures"; gemma4 --verbose1 "Briefly explain TCP handshake."
}
echo "Gemma 4 E4B / POCO F8 Ultra installer"
echo "Enter = automatic full installation"
echo "1 = build llama.cpp with Vulkan"
echo "2 = download model"
echo "3 = install scripts"
echo "4 = run tests"
read -r -p "Choose [Enter/1/2/3/4]: " choice
case "$choice" in
  "") build_llama; pause; download_model; pause; install_scripts ;;
  1) build_llama ;;
  2) download_model ;;
  3) install_scripts ;;
  4) tests ;;
  *) echo "Unknown option."; exit 1 ;;
esac
