#!/data/data/com.termux/files/usr/bin/bash
set -euo pipefail

ROOT="$HOME/termux-llama-setup"
BIN="$HOME/bin"
LLAMA="$HOME/llama.cpp"
SHADERC="$HOME/shaderc"
SPIRV_HEADERS="$HOME/SPIRV-Headers"
MODEL_DIR="$HOME/models/gemma4-e4b"
MODEL="$MODEL_DIR/google_gemma-4-E4B-it-Q4_K_M.gguf"
LOG_DIR="$ROOT/logs"
PID_FILE="$LOG_DIR/llama-server.pid"

pause() {
  read -r -p "Press Enter to continue..."
}

remove_engine() {
  local answer="" confirm=""
  echo
  echo "This will permanently remove the current local model engine:"
  echo "  $LLAMA"
  echo "  $SHADERC"
  echo "  $SPIRV_HEADERS"
  echo
  echo "The GGUF model in $MODEL_DIR will NOT be deleted."
  echo "Vulkan packages and CLI scripts will NOT be deleted."
  read -r -p "Remove the current model engine? [y/N]: " answer
  case "$answer" in y|Y|yes|YES) ;; *) echo "Removal cancelled."; return ;; esac
  read -r -p "Type DELETE to confirm: " confirm
  [ "$confirm" = "DELETE" ] || { echo "Removal cancelled."; return; }
  pkill -f "llama-server" 2>/dev/null || true
  rm -f "$PID_FILE"
  rm -rf "$LLAMA" "$SHADERC" "$SPIRV_HEADERS"
  echo "OK: current model engine removed."
}

install_vulkan_deps() {
  echo "==> Installing Termux and Vulkan dependencies..."
  pkg update -y
  pkg upgrade -y

  if dpkg -s vulkan-loader-android >/dev/null 2>&1; then
    echo "Removing conflicting vulkan-loader-android..."
    pkg uninstall -y vulkan-loader-android
  fi

  pkg install -y \
    git cmake ninja clang make pkg-config \
    python curl bison flex perl \
    vulkan-loader vulkan-loader-generic \
    vulkan-headers vulkan-tools glslang

  echo "OK: Vulkan dependencies installed."
}

install_spirv_headers() {
  local config="$PREFIX/share/cmake/SPIRV-Headers/SPIRV-HeadersConfig.cmake"

  if [ -f "$config" ]; then
    echo "OK: SPIRV-Headers already installed."
    return
  fi

  echo "==> Building and installing SPIRV-Headers..."
  if [ ! -d "$SPIRV_HEADERS/.git" ]; then
    git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Headers.git "$SPIRV_HEADERS"
  fi

  rm -rf "$SPIRV_HEADERS/build"
  cmake -S "$SPIRV_HEADERS" -B "$SPIRV_HEADERS/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
  cmake --build "$SPIRV_HEADERS/build" -j2
  cmake --install "$SPIRV_HEADERS/build"
  test -f "$config"
  echo "OK: SPIRV-Headers installed."
}

find_or_build_glslc() {
  local candidate=""

  for candidate in \
    "$PREFIX/bin/glslc" \
    "$SHADERC/build/glslc/glslc" \
    "$SHADERC/build/glslc"; do
    if [ -x "$candidate" ]; then
      GLSLC="$candidate"
      echo "Using glslc: $GLSLC"
      return
    fi
  done

  echo "==> Building Shaderc glslc..."
  if [ ! -d "$SHADERC/.git" ]; then
    git clone --depth 1 https://github.com/google/shaderc.git "$SHADERC"
  fi

  cd "$SHADERC"
  ./utils/git-sync-deps
  cmake -S "$SHADERC" -B "$SHADERC/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DSHADERC_SKIP_TESTS=ON
  cmake --build "$SHADERC/build" --target glslc -j2

  if [ -x "$SHADERC/build/glslc/glslc" ]; then
    GLSLC="$SHADERC/build/glslc/glslc"
  elif [ -x "$SHADERC/build/glslc" ]; then
    GLSLC="$SHADERC/build/glslc"
  else
    echo "ERROR: glslc could not be built."
    exit 1
  fi
}

build_llama() {
  install_vulkan_deps
  install_spirv_headers
  find_or_build_glslc

  echo "==> Building llama.cpp with compatible Vulkan shaders..."

  if [ ! -d "$LLAMA/.git" ]; then
    git clone --depth 1 https://github.com/ggml-org/llama.cpp.git "$LLAMA"
  else
    git -C "$LLAMA" pull --ff-only
  fi

  rm -rf "$LLAMA/build"

  cmake -S "$LLAMA" -B "$LLAMA/build" -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DGGML_VULKAN=ON \
    -DGGML_VULKAN_COOPMAT=OFF \
    -DGGML_VULKAN_COOPMAT2=OFF \
    -DGGML_VULKAN_INTEGER_DOT=OFF \
    -DGGML_VULKAN_BFLOAT16=OFF \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DVulkan_GLSLC_EXECUTABLE="$GLSLC"

  cmake --build "$LLAMA/build" --target llama-server -j2

  test -x "$LLAMA/build/bin/llama-server"
  grep -q "^GGML_VULKAN:BOOL=ON$" "$LLAMA/build/CMakeCache.txt"

  echo "OK: Vulkan llama-server built."
  echo "Binary: $LLAMA/build/bin/llama-server"
}

download_model() {
  mkdir -p "$MODEL_DIR"

  if [ -s "$MODEL" ]; then
    echo "Model already exists: $MODEL"
    ls -lh "$MODEL"
    return
  fi

  curl -L --fail --continue-at - -o "$MODEL" \
    "https://huggingface.co/unsloth/gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_M.gguf?download=true"

  test -s "$MODEL"
  ls -lh "$MODEL"
}

install_scripts() {
  mkdir -p "$BIN"
  cp "$ROOT/scripts/gemma4" "$BIN/gemma4"
  cp "$ROOT/scripts/gemma-web" "$BIN/gemma-web"
  cp "$ROOT/scripts/gemma-temp" "$BIN/gemma-temp"
  chmod +x "$BIN/gemma4" "$BIN/gemma-web" "$BIN/gemma-temp"

  grep -qxF 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null || \
    echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"

  export PATH="$BIN:$PATH"
  command -v gemma4
  echo "OK: CLI scripts installed."
}

tests() {
  export PATH="$BIN:$PATH"
  test -x "$LLAMA/build/bin/llama-server"
  grep "^GGML_VULKAN:BOOL=ON$" "$LLAMA/build/CMakeCache.txt"
  echo "OK: Vulkan llama-server found."
  echo "Start server:"
  echo "bash ~/termux-llama-setup/scripts/start-server.sh"
  pause
  curl --fail http://127.0.0.1:8080/health
  echo
  pause
  gemma4 --local "Respond only in English: local model is working."
}

echo "Gemma 4 E4B / POCO F8 Ultra Vulkan installer"
echo "0 = remove current model engine"
echo "Enter = full installation"
echo "1 = build llama.cpp with Vulkan"
echo "2 = download model"
echo "3 = install CLI scripts"
echo "4 = run tests"

read -r -p "Choose [Enter/0/1/2/3/4]: " choice

case "$choice" in
  0) remove_engine ;;
  "") build_llama; pause; download_model; pause; install_scripts ;;
  1) build_llama ;;
  2) download_model ;;
  3) install_scripts ;;
  4) tests ;;
  *) echo "Unknown option."; exit 1 ;;
esac
