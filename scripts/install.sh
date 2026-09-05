#!/data/data/com.termux/files/usr/bin/bash
set -e

REPO_URL="https://github.com/ajivitca/termux-llama-setup.git"
INSTALL_DIR="$HOME/termux-llama-setup"

echo "==> Updating Termux packages..."
pkg update -y
pkg upgrade -y

echo "==> Installing dependencies..."
pkg install -y git cmake clang make python curl ddgr

if [ ! -d "$INSTALL_DIR/.git" ]; then
  echo "==> Cloning setup repository..."
  git clone "$REPO_URL" "$INSTALL_DIR"
else
  echo "==> Updating setup repository..."
  git -C "$INSTALL_DIR" pull --ff-only
fi

echo "==> Installing command-line tools..."
mkdir -p "$HOME/bin"
cp "$INSTALL_DIR/scripts/gemma4" "$HOME/bin/gemma4"
cp "$INSTALL_DIR/scripts/gemma-web" "$HOME/bin/gemma-web"
cp "$INSTALL_DIR/scripts/gemma-temp" "$HOME/bin/gemma-temp"
chmod +x "$HOME/bin/gemma4" "$HOME/bin/gemma-web" "$HOME/bin/gemma-temp"

grep -qxF 'export PATH="$HOME/bin:$PATH"' "$HOME/.bashrc" 2>/dev/null || \
  echo 'export PATH="$HOME/bin:$PATH"' >> "$HOME/.bashrc"

echo
echo "==> Done."
echo "Restart Termux or run: source ~/.bashrc"
echo "Next steps:"
echo "  1. bash ~/termux-llama-setup/scripts/build-llama.sh"
echo "  2. bash ~/termux-llama-setup/scripts/download-model.sh"
echo "  3. bash ~/termux-llama-setup/scripts/start-server.sh"
echo "  4. In a second Termux session: gemma4 "Hello""
