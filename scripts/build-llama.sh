#!/data/data/com.termux/files/usr/bin/bash
set -e
LLAMA_DIR="$HOME/llama.cpp"

pkg update -y
pkg install -y git cmake clang make vulkan-loader-android vulkan-tools

if [ ! -d "$LLAMA_DIR/.git" ]; then
  git clone https://github.com/ggml-org/llama.cpp.git "$LLAMA_DIR"
fi

git -C "$LLAMA_DIR" pull --ff-only
cmake -S "$LLAMA_DIR" -B "$LLAMA_DIR/build" -DCMAKE_BUILD_TYPE=Release -DGGML_VULKAN=ON
cmake --build "$LLAMA_DIR/build" -j"$(nproc)"

echo "Done: $LLAMA_DIR/build/bin/llama-server"
