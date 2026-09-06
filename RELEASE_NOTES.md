# Termux llama.cpp Vulkan installer — v1.0.0

Release date: 2026-09-06

## Русский

Этот релиз обновляет инсталлятор для Termux и доводит установку `llama.cpp` с Vulkan до рабочего состояния на Android.

### Что изменилось
- Добавлена полноценная сборка `llama.cpp` с Vulkan-бэкендом для Termux.
- Добавлена автоматическая установка и проверка `SPIRV-Headers`.
- Добавлена автоматическая сборка Shaderc и поиск `glslc`.
- Исправлена генерация Vulkan-шейдеров: `cmd.push_back("-O");` заменено на `cmd.push_back("-O0");`.
- Добавлена проверка успешной сборки через `llama-server`.
- Добавлены сценарии установки, запуска сервера и тестирования модели.
- Добавлен режим удаления текущего локального engine без удаления модели.

### Как установить
1. Установи Termux из F-Droid.
2. Обнови пакеты:
   ```bash
   pkg update -y && pkg upgrade -y
Запусти инсталлятор:
bash ~/termux-llama-setup/install.sh
Выбери нужный режим:
Enter — полная установка.
1 — только сборка llama.cpp с Vulkan.
2 — только скачивание модели.
3 — только установка CLI-скриптов.
4 — только тесты.
0 — удаление текущего engine.
Как проверить
После сборки проверь:
test -x ~/llama.cpp/build/bin/llama-server
grep '^GGML_VULKAN:BOOL=ON$' ~/llama.cpp/build/CMakeCache.txt
Как использовать
Запуск сервера:
~/termux-llama-setup/scripts/start-server.sh
Проверка сервера:
curl http://127.0.0.1:8080/health
Локальный запрос:
gemma4 --local "Respond only in English: local model is working."
Режим рассуждений:
gemma4 --reasoning "Respond only in English. Solve step by step: a train travels 180 km in 3 hours. What is its average speed?"
Web-запрос:
gemma4 "Respond only in English. What is the current weather in Moscow?"
Сценарии
Чистая установка: выбирай Enter.
Проверка только сборки: выбирай 1.
Повторная загрузка модели: выбирай 2.
Переустановка CLI-скриптов: выбирай 3.
Диагностика: выбирай 4.
Удаление старого engine: выбирай 0.
Примечания
Сборка Vulkan на Android может занимать заметное время, потому что Shaderc и генерация шейдеров компилируются локально.
Если экран гаснет, рекомендуется держать активный wakelock, чтобы Android не переводил Termux в deep sleep.
Для стабильной работы желательно запускать сборку и тесты при подключённом питании.
English
This release updates the Termux installer and brings llama.cpp Vulkan installation on Android into a working state.
What changed
Added a complete llama.cpp build flow with Vulkan backend for Termux.
Added automatic installation and verification of SPIRV-Headers.
Added automatic Shaderc build and glslc discovery.
Fixed Vulkan shader generation by replacing cmd.push_back("-O"); with cmd.push_back("-O0");.
Added build verification through llama-server.
Added install, server startup, and model test workflows.
Added a mode to remove the current local engine without deleting the model.
How to install
Install Termux from F-Droid.
Update packages:
pkg update -y && pkg upgrade -y
Run the installer:
bash ~/termux-llama-setup/install.sh
Choose the mode you need:
Enter — full installation.
1 — build llama.cpp with Vulkan only.
2 — download the model only.
3 — install CLI scripts only.
4 — run tests only.
0 — remove the current engine.
How to verify
After the build, check:
test -x ~/llama.cpp/build/bin/llama-server
grep '^GGML_VULKAN:BOOL=ON$' ~/llama.cpp/build/CMakeCache.txt
How to use
Start the server:
~/termux-llama-setup/scripts/start-server.sh
Check the server:
curl http://127.0.0.1:8080/health
Run a local prompt:
gemma4 --local "Respond only in English: local model is working."
Run reasoning mode:
gemma4 --reasoning "Respond only in English. Solve step by step: a train travels 180 km in 3 hours. What is its average speed?"
Run a web request:
gemma4 "Respond only in English. What is the current weather in Moscow?"
Scenarios
Fresh install: choose Enter.
Build check only: choose 1.
Re-download the model: choose 2.
Reinstall CLI scripts: choose 3.
Diagnostics: choose 4.
Remove old engine: choose 0.
Notes
Vulkan builds on Android can take a while because Shaderc and shader generation are compiled locally.
If the screen turns off, keep a wakelock active so Android does not place Termux into deep sleep.
For best stability, run builds and tests while connected to power.
