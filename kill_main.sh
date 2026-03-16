#!/usr/bin/env bash
set -euo pipefail

# 自动读取 run_main.sh 的默认参数
RUN_MAIN_PATH="./run_main.sh"

# 如果没有传入 DATASET_NAME，则从 run_main.sh 中读取默认值
if [ -z "${DATASET_NAME:-}" ]; then
    if [ -f "${RUN_MAIN_PATH}" ]; then
        # 从 run_main.sh 中提取 DATASET_NAME 的默认值
        DATASET_NAME="$(grep -E '^DATASET_NAME=' "${RUN_MAIN_PATH}" | head -n 1 | sed -E 's/.*\$\{DATASET_NAME:-([^}]+)\}.*/\1/' || true)"
        # 如果上面的正则没匹配到，尝试另一种格式
        if [ -z "${DATASET_NAME}" ]; then
            DATASET_NAME="$(grep -E '^DATASET_NAME=' "${RUN_MAIN_PATH}" | head -n 1 | sed -E 's/.*DATASET_NAME="([^"]+)".*/\1/' || true)"
        fi
    fi
fi

# 使用默认值
# DATASET_NAME="${DATASET_NAME:-multihop-rag}"

# PID 文件路径（与 run_main.sh 保持一致）
PID_FILE="/root/GraphRAG/Output/${DATASET_NAME}/run_main.pid"
LOG_FILE="/root/GraphRAG/Output/${DATASET_NAME}/run_main.log"

echo "Stopping run_main.sh process... | Dataset: ${DATASET_NAME} | PID File: ${PID_FILE}"


# 检查 PID 文件是否存在
if [ ! -f "${PID_FILE}" ]; then
    echo "Warning: PID file not found: ${PID_FILE}"
    echo ""
    echo "Attempting to find running process..."
    
    # 尝试通过进程名查找
    PIDS=$(pgrep -f "python.*main.py.*${DATASET_NAME}" 2>/dev/null || true)
    if [ -n "${PIDS}" ]; then
        echo "Found running main.py processes: ${PIDS}"
        for PID in ${PIDS}; do
            echo "Killing PID ${PID}..."
            kill -TERM "${PID}" 2>/dev/null || true
        done
        sleep 2
        # 检查是否还有残留进程
        REMAINING=$(pgrep -f "python.*main.py.*${DATASET_NAME}" 2>/dev/null || true)
        if [ -n "${REMAINING}" ]; then
            echo "Force killing remaining processes..."
            for PID in ${REMAINING}; do
                kill -9 "${PID}" 2>/dev/null || true
            done
        fi
        echo "Done."
    else
        echo "No running processes found for dataset: ${DATASET_NAME}"
    fi
    exit 0
fi

# 读取 PID
PID=$(cat "${PID_FILE}")

if [ -z "${PID}" ]; then
    echo "Error: PID file is empty: ${PID_FILE}"
    rm -f "${PID_FILE}"
    exit 1
fi

echo "Found PID: ${PID}"

# 检查进程是否存在
if ! kill -0 "${PID}" 2>/dev/null; then
    echo "Process ${PID} is not running (stale PID file)."
    rm -f "${PID_FILE}"
    exit 0
fi

# 优雅终止 - 先发送 SIGTERM
echo "Sending SIGTERM to process ${PID}..."
if kill -TERM "${PID}" 2>/dev/null; then
    # 等待进程退出（最多等待 10 秒）
    for i in {1..10}; do
        if ! kill -0 "${PID}" 2>/dev/null; then
            echo "Process terminated gracefully."
            rm -f "${PID_FILE}"
            break
        fi
        sleep 1
    done
    
    # 如果进程仍未退出，强制杀死
    if kill -0 "${PID}" 2>/dev/null; then
        echo "Process did not terminate gracefully, sending SIGKILL..."
        kill -9 "${PID}" 2>/dev/null || true
        echo "Process force killed."
        rm -f "${PID_FILE}"
    fi
else
    echo "Failed to send signal to process."
fi

# 查找并终止子进程
CHILD_PIDS=$(pgrep -P "${PID}" 2>/dev/null || true)
if [ -n "${CHILD_PIDS}" ]; then
    echo "Terminating child processes: ${CHILD_PIDS}"
    echo "${CHILD_PIDS}" | xargs kill -TERM 2>/dev/null || true
    sleep 2
    REMAINING_CHILDREN=$(pgrep -P "${PID}" 2>/dev/null || true)
    if [ -n "${REMAINING_CHILDREN}" ]; then
        echo "${REMAINING_CHILDREN}" | xargs kill -9 2>/dev/null || true
    fi
fi
echo "Process cleanup complete!"

# 可选：删除日志文件（如果需要保留日志，请注释掉下面这行）
# rm -f "${LOG_FILE}"