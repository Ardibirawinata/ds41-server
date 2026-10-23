#!/usr/bin/env bash
set -euo pipefail

MODEL_FILE="${MODEL_FILE:-DeepSeek-V4.1-Flash-UNCENSORED-Q3_K_M-00001-of-00009.gguf}"
MMPROJ_FILE="${MMPROJ_FILE:-DeepSeek-V4.1-Flash-mmproj-BF16.gguf}"
MODEL_PATH="${LLAMA_ARG_MODEL:-/repository/${MODEL_FILE}}"
MMPROJ_PATH="/repository/${MMPROJ_FILE}"
PORT="${PORT:-${LLAMA_ARG_PORT:-8080}}"
CTX="${CTX:-${LLAMA_ARG_CTX_SIZE:-8192}}"
THREADS="${THREADS:-$(nproc)}"

if [ ! -f "$MODEL_PATH" ]; then
  echo "FATAL: model tidak ditemukan: $MODEL_PATH"
  echo "isi /repository:"
  ls -la /repository || true
  exit 1
fi

echo "model   : $MODEL_PATH"
echo "mmproj  : $MMPROJ_PATH"
echo "listen  : 0.0.0.0:$PORT  ctx=$CTX threads=$THREADS"
echo "shard   : $(ls -1 /repository/*.gguf 2>/dev/null | wc -l) file .gguf"

ARGS=(--host 0.0.0.0 --port "$PORT" -m "$MODEL_PATH" -c "$CTX" -t "$THREADS" -np 1 --jinja)
[ -f "$MMPROJ_PATH" ] && ARGS+=(--mmproj "$MMPROJ_PATH")

exec llama-server "${ARGS[@]}"
