#!/data/data/com.termux/files/usr/bin/bash
set -e
ROOT="$HOME/termux-llama-setup"
BIN="$HOME/bin"
LLAMA="$HOME/llama.cpp"
MODEL="$HOME/models/gemma4-e4b/google_gemma-4-E4B-it-Q4_K_M.gguf"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/llama-server.log"
PID_FILE="$LOG_DIR/llama-server.pid"
pause(){ read -r -p "Press Enter to continue..."; }
export PATH="$BIN:$PATH"
mkdir -p "$LOG_DIR"
echo "==> Test 1: CLI"
gemma4 --help
pause
echo "==> Test 2: model"
test -s "$MODEL"
ls -lh "$MODEL"
pause
echo "==> Test 3: Vulkan binary"
test -x "$LLAMA/build/bin/llama-server"
grep -q "GGML_VULKAN:BOOL=ON" "$LLAMA/build/CMakeCache.txt"
echo "OK: Vulkan build found."
pause
echo "==> Test 4: server"
if curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null; then
  echo "OK: Server already running."
else
  echo "Starting server in background..."
  nohup bash "$ROOT/scripts/start-server.sh" >"$LOG_FILE" 2>&1 < /dev/null &
  echo $! > "$PID_FILE"
  echo "PID: $(cat "$PID_FILE")"
  echo "Log: $LOG_FILE"
  i=0
  until curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null; do
    i=$((i+1))
    if [ "$i" -ge 180 ]; then
      echo "ERROR: Server was not ready after 180 seconds."
      tail -n 50 "$LOG_FILE" 2>/dev/null || true
      exit 1
    fi
    sleep 1
  done
  echo "OK: Server ready."
fi
curl -fsS http://127.0.0.1:8080/health; echo
pause
echo "==> Test 5: local request"
gemma4 --local "Скажи по-русски: локальная модель работает."
pause
echo "==> Test 6: automatic web request"
gemma4 "Какая сейчас погода в Москве?"
pause
echo "==> Test 7: reasoning request"
gemma4 --reasoning "Реши пошагово: 180 километров за 3 часа. Какая средняя скорость?"
pause
echo "==> Test 8: temperatures"
gemma4 --verbose1 "Кратко объясни TCP handshake."
echo "All tests completed."
