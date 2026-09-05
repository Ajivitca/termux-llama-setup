# Gemma 4 E4B on POCO F8 Ultra: Termux + Vulkan

Мои настройки локального запуска llama.cpp в Termux.

## Содержимое

- `system_prompt.txt` — короткий системный промпт для ответов в интерфейсе чата.

## Исходный проект

llama.cpp: https://github.com/ggml-org/llama.cpp

## Target device and Vulkan

This setup targets the **POCO F8 Ultra, 16 GB RAM / 512 GB storage**, using the **Snapdragon 8 Elite Gen 5 (SM8850-AC)** and **Adreno 840 GPU**.

`llama.cpp` is built with Vulkan enabled by default:

```bash
cmake -S ~/llama.cpp -B ~/llama.cpp/build -DCMAKE_BUILD_TYPE=Release -DGGML_VULKAN=ON

## Full installation guide: POCO F8 Ultra

This guide targets the **POCO F8 Ultra (16 GB RAM / 512 GB storage)** with Snapdragon 8 Elite Gen 5 and Adreno 840.

### 1. Install Termux

1. Open the official Termux release page: https://github.com/termux/termux-app/releases
2. Download and install the current `apt-android-7` APK for Android 7 or newer.
3. Do not mix F-Droid/GitHub Termux builds with the Play Store build because they use different signing keys.
4. Open Termux after installation and allow storage access only if you need it:

```bash
termux-setup-storage
```

### 2. Clone this repository

Run these commands in Termux:

```bash
pkg update -y
pkg upgrade -y
pkg install -y git
git clone https://github.com/ajivitca/termux-llama-setup.git
cd ~/termux-llama-setup
```

### 3. Install the CLI tools

```bash
bash scripts/install.sh
source ~/.bashrc
gemma4 --help
```

Expected result: the command prints its option list. The installer places `gemma4`, `gemma-web`, and `gemma-temp` in `~/bin`.

### 4. Build llama.cpp with Vulkan

This is the default build path. It compiles llama.cpp with `-DGGML_VULKAN=ON` for Adreno GPU acceleration:

```bash
bash scripts/build-llama.sh
```

Verify that the binary was created:

```bash
test -x ~/llama.cpp/build/bin/llama-server && echo "OK: llama-server exists" || echo "ERROR: llama-server is missing"
```

### 5. Download Gemma 4 E4B

```bash
bash scripts/download-model.sh
```

Verify the model file:

```bash
ls -lh ~/models/gemma4-e4b/google_gemma-4-E4B-it-Q4_K_M.gguf
```

### 6. Start the local model server

Keep this command running in the first Termux session:

```bash
bash scripts/start-server.sh
```

The active configuration is Vulkan build, `-ngl 99` GPU-layer offload, 2048-token context, 6 CPU threads, and the local address `127.0.0.1:8080`.

### 7. Check the local server

Open a second Termux session and run:

```bash
curl http://127.0.0.1:8080/health
```

Expected result: a health response such as `ok`. Open `http://127.0.0.1:8080` in the phone browser to use the built-in local Web UI.

### 8. Test local mode

This sends no query to a search engine:

```bash
gemma4 --local "Explain quantum entanglement in Russian"
```

The final line should include `[source: local`.

### 9. Test automatic web routing

The wrapper first asks the local model whether a request needs current information. Use a time-sensitive question:

```bash
gemma4 "What is the current weather in Moscow?"
```

Expected result: the final line should include `[source: web`. The query is sent to DuckDuckGo via `ddgr`, then the local model creates a Russian answer from the returned search result.

### 10. Test reasoning mode

Reasoning mode raises the response limit from 100 to 500 tokens:

```bash
gemma4 --reasoning "Solve step by step: if a train travels 180 km in 3 hours, what is its average speed?"
```

The final line should include `mode: reasoning`.

### 11. Test temperature output

```bash
gemma4 --verbose1 "Briefly explain the TCP handshake"
```

After the answer, the script prints available values such as `CPU max`, `GPU max`, and `Battery`. Missing values mean that the Android kernel did not expose a matching thermal zone to Termux.

### 12. Useful checks

```bash
pgrep -af llama-server
curl http://127.0.0.1:8080/health
gemma4 --help
```

If `gemma4` is not found, run `source ~/.bashrc` or restart Termux. If the server health check fails, start `bash scripts/start-server.sh` again and inspect its output for Vulkan backend information.

---

# Русская инструкция

## POCO F8 Ultra

Настройка рассчитана на **POCO F8 Ultra 16 GB / 512 GB**, Snapdragon 8 Elite Gen 5 и Adreno 840. `llama.cpp` собирается с Vulkan по умолчанию (`-DGGML_VULKAN=ON`) и запускается с GPU offload `-ngl 99`.

## Установка

1. Termux: https://github.com/termux/termux-app/releases
2. Установи актуальный APK `apt-android-7`.
3. Открой Termux и выполни:

```bash
pkg update -y
pkg upgrade -y
pkg install -y git
git clone https://github.com/ajivitca/termux-llama-setup.git
cd ~/termux-llama-setup
bash scripts/install.sh
source ~/.bashrc
gemma4 --help
```

## Сборка Vulkan

```bash
bash scripts/build-llama.sh
test -x ~/llama.cpp/build/bin/llama-server && echo "OK: llama-server найден" || echo "ERROR: llama-server не найден"
```

## Загрузка модели

```bash
bash scripts/download-model.sh
ls -lh ~/models/gemma4-e4b/google_gemma-4-E4B-it-Q4_K_M.gguf
```

## Запуск сервера

В первой сессии Termux:

```bash
bash scripts/start-server.sh
```

Во второй сессии:

```bash
curl http://127.0.0.1:8080/health
```

Локальный Web UI: http://127.0.0.1:8080

Сервер доступен только на самом телефоне: `127.0.0.1` не открывает его в Wi-Fi/LAN.

## Проверки ассистента

Локальный запрос без web-поиска:

```bash
gemma4 --local "Объясни квантовую запутанность"
```

Автоматический web-поиск по решению скрипта:

```bash
gemma4 "Какая сейчас погода в Москве?"
```

В конце ожидается `[source: web | ...]`.

Длинный ответ:

```bash
gemma4 --reasoning "Реши пошагово: поезд проехал 180 км за 3 часа. Какая средняя скорость?"
```

Температуры CPU, GPU и батареи:

```bash
gemma4 --verbose1 "Кратко объясни TCP handshake"
```

Проверка процесса и API:

```bash
pgrep -af llama-server
curl http://127.0.0.1:8080/health
```

Не публикуй GGUF-модели, логи, токены или приватные ключи.
