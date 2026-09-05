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
