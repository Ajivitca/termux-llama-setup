#!/data/data/com.termux/files/usr/bin/bash
set -u

ROOT="$HOME/termux-llama-setup"
BIN="$HOME/bin"
LOG_DIR="$ROOT/logs"
LOG_FILE="$LOG_DIR/llama-server.log"
PID_FILE="$LOG_DIR/llama-server.pid"

export PATH="$BIN:$PATH"
mkdir -p "$LOG_DIR"

wait_input() {
  local message="$1" default="$2" answer="" i
  printf '%s' "$message"

  for i in 1 2 3 4 5 6 7 8 9 10; do
    if read -r -t 1 answer; then
      echo
      REPLY="$answer"
      return
    fi
    printf '.'
  done

  echo
  REPLY="$default"
}

pause() {
  local ignored="" i
  printf 'Press Enter for next test, or wait 10 seconds'

  for i in 1 2 3 4 5 6 7 8 9 10; do
    if read -r -t 1 ignored; then
      echo
      return
    fi
    printf '.'
  done

  echo
}

show_call() {
  echo
  echo "========================================"
  echo "BASH COMMAND:"
  echo "gemma4 $*"
  echo "========================================"
}

stop_server() {
  echo "==> Stopping existing local server..."

  if [ -f "$PID_FILE" ]; then
    PID="$(cat "$PID_FILE" 2>/dev/null || true)"
    if [ -n "${PID:-}" ] && kill -0 "$PID" 2>/dev/null; then
      echo "Stopping PID: $PID"
      kill "$PID" 2>/dev/null || true

      for i in 1 2 3 4 5; do
        kill -0 "$PID" 2>/dev/null || break
        sleep 1
      done

      if kill -0 "$PID" 2>/dev/null; then
        echo "Force-stopping PID: $PID"
        kill -9 "$PID" 2>/dev/null || true
      fi
    fi
    rm -f "$PID_FILE"
  fi

  if curl -fs --max-time 2 http://127.0.0.1:8080/health >/dev/null 2>curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null1; then
    echo "Port 8080 is still occupied; stopping server process..."
    pkill -f 'llama-server|llama.*server' 2>/dev/null || true
    sleep 2
  fi
}

start_server() {
  echo "==> Starting local server..."
  nohup bash "$ROOT/scripts/start-server.sh" >"$LOG_FILE" 2>&1 < /dev/null &
  echo $! > "$PID_FILE"
  echo "PID: $(cat "$PID_FILE")"
  echo "Log file: $LOG_FILE"

  printf 'Waiting for the model to load'

  for i in $(seq 1 180); do
    if curl -fs --max-time 2 http://127.0.0.1:8080/health >/dev/null 2>curl -fsS --max-time 2 http://127.0.0.1:8080/health >/dev/null1; then
      echo
      echo "OK: server is ready."
      echo "Health response:"
      curl -fsS http://127.0.0.1:8080/health
      echo
      return 0
    fi
    printf '.'
    sleep 1
  done

  echo
  echo "ERROR: server did not become ready after 180 seconds."
  tail -n 50 "$LOG_FILE" 2>/dev/null || true
  exit 1
}

echo "Gemma 4 E4B test suite / POCO F8 Ultra"
echo "1 = English prompts and English-only answers"
echo "2 = Russian prompts and Russian-only answers"
wait_input "Choose language [1/2]; default English in 10 seconds: " "1"

case "$REPLY" in
  1|"") LANG="en" ;;
  2) LANG="ru" ;;
  *) echo "Unknown choice; English selected."; LANG="en" ;;
esac

echo "Selected language: $LANG"
echo

stop_server
start_server
pause

if [ "$LANG" = "en" ]; then
  Q1="Respond only in English. Answer in one sentence: is the local model working?"
  Q2="Respond only in English. Solve step by step: a train travels 180 km in 3 hours. What is its average speed?"
  Q3="Respond only in English. What is the current weather in Moscow?"
  Q4="Respond only in English. Briefly explain the TCP handshake."
else
  Q1="Отвечай только на русском. Ответь одним предложением: локальная модель работает?"
  Q2="Отвечай только на русском. Реши пошагово: поезд проехал 180 километров за 3 часа. Какая средняя скорость?"
  Q3="Отвечай только на русском. Какая сейчас погода в Москве?"
  Q4="Отвечай только на русском. Кратко объясни TCP handshake."
fi

echo "==> Test 1: local-only model request"
show_call --local "$Q1"
gemma4 --local "$Q1"
pause

echo "==> Test 2: reasoning model request"
show_call --reasoning "$Q2"
gemma4 --reasoning "$Q2"
pause

echo "==> Test 3: automatic web routing"
show_call "$Q3"
gemma4 "$Q3"
pause

echo "==> Test 4: forced web routing"
show_call --web "$Q3"
gemma4 --web "$Q3"
pause

echo "==> Test 5: temperatures"
show_call --verbose1 "$Q4"
gemma4 --verbose1 "$Q4"

echo
echo "All model tests completed."
