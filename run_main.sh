#!/usr/bin/env bash
set -euo pipefail

DATASET_NAME="${DATASET_NAME:-multihop-rag}"
METHOD_CONFIG="${METHOD_CONFIG:-Option/Method/HippoRAG.yaml}"
QUERY_CONCURRENCY="${QUERY_CONCURRENCY:-16}"
CPU_THREADS="${CPU_THREADS:-$(nproc)}"
SKIP_GRAPH_BUILD="${SKIP_GRAPH_BUILD:-${SKIP_GRAPG_BUILD:-${skip_grapg_build:-0}}}"



METHOD_BASENAME="$(basename "${METHOD_CONFIG}")"
METHOD_NAME="${METHOD_BASENAME%.*}"
LOG_FILE="${LOG_FILE:-/root/GraphRAG/Output/${DATASET_NAME}/run_main.log}"
PYTHON_BIN="${PYTHON_BIN:-python}"
NLTK_DATA_PATH="${NLTK_DATA_PATH:-/root/GraphRAG/nltk_data}"

export NLTK_DATA="${NLTK_DATA_PATH}"
export OMP_NUM_THREADS="${CPU_THREADS}"
export MKL_NUM_THREADS="${CPU_THREADS}"
export OPENBLAS_NUM_THREADS="${CPU_THREADS}"
export NUMEXPR_NUM_THREADS="${CPU_THREADS}"
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy
export no_proxy="localhost,127.0.0.1,0.0.0.0"
export METHOD_EXP_NAME="${METHOD_EXP_NAME:-${METHOD_NAME}}"
export GRAPHRAG_DISABLE_FILE_LOG="${GRAPHRAG_DISABLE_FILE_LOG:-1}"
export GRAPHRAG_LOG_PATH="/root/GraphRAG/Output/${DATASET_NAME}/${METHOD_EXP_NAME}"

METHOD_CONFIG_PATH="${METHOD_CONFIG}"
if [ "${SKIP_GRAPH_BUILD}" = "1" ]; then
    TEMP_METHOD_CONFIG="$(mktemp /tmp/method_config_XXXXXX.yaml)"
    METHOD_CONFIG_PATH="${TEMP_METHOD_CONFIG}"
    export METHOD_CONFIG_ORIG="${METHOD_CONFIG}"
    METHOD_CONFIG_ORIG="${METHOD_CONFIG_ORIG}" METHOD_CONFIG_PATH="${METHOD_CONFIG_PATH}" "${PYTHON_BIN}" - <<'PY'
import os
import yaml

src = os.environ.get("METHOD_CONFIG_ORIG")
dst = os.environ.get("METHOD_CONFIG_PATH")
with open(src, "r", encoding="utf-8") as f:
    data = yaml.safe_load(f) or {}
graph = data.get("graph") or {}
graph["force"] = False
data["graph"] = graph
with open(dst, "w", encoding="utf-8") as f:
    yaml.safe_dump(data, f, allow_unicode=True, sort_keys=False)
PY
else
    OUTPUT_DIR="/root/GraphRAG/Output/${DATASET_NAME}"
    if [ -d "${OUTPUT_DIR}" ]; then
        OUTPUT_DIR="${OUTPUT_DIR}" "${PYTHON_BIN}" - <<'PY'
import os
import shutil

path = os.environ.get("OUTPUT_DIR")
if path and os.path.isdir(path):
    shutil.rmtree(path)
PY
    fi
fi

mkdir -p "$(dirname "${LOG_FILE}")"
PID_FILE="${LOG_FILE%.log}.pid"
RUN_ARGS=(
    -u main.py
    -opt "${METHOD_CONFIG_PATH}"
    -dataset_name "${DATASET_NAME}"
)
RUN_ARGS+=(--query_concurrency "${QUERY_CONCURRENCY}")
nohup "${PYTHON_BIN}" "${RUN_ARGS[@]}" > "${LOG_FILE}" 2>&1 &
echo $! > "${PID_FILE}"
disown
printf "%s\n" "Started. Log: ${LOG_FILE}"
