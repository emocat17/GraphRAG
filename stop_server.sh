#!/bin/bash

# ================= 读取启动配置 =================
PID_FILE="/root/GraphRAG/logs/server.pid"
LOG_DIR="/root/GraphRAG/logs"

if [ -f "$PID_FILE" ]; then
    source "$PID_FILE"
else
    echo "错误: PID 文件不存在 ($PID_FILE)"
    echo "请先运行 start_server.sh 启动服务"
    exit 1
fi

echo "=============================================="
echo "从 PID 文件读取配置:"
echo "  LLM GPUs:      ${LLM_GPUS:-未知}"
echo "  Embed GPUs:    ${EMBED_GPUS:-未知}"
echo "  LLM Gateway PID: ${LLM_GATEWAY_PID:-未知}"
echo "  Embed Gateway PID: ${EMBED_GATEWAY_PID:-未知}"
echo "=============================================="

# ================= 1. 停止 LLM Gateway 服务 =================
echo ""
echo ">>> 停止 LLM Gateway..."
if [ -n "$LLM_GATEWAY_PID" ]; then
    if kill -0 "$LLM_GATEWAY_PID" 2>/dev/null; then
        kill "$LLM_GATEWAY_PID" 2>/dev/null && echo "  LLM Gateway (PID $LLM_GATEWAY_PID) 已发送 SIGTERM" || echo "  LLM Gateway 停止失败"
    else
        echo "  LLM Gateway (PID $LLM_GATEWAY_PID) 不存在或已退出"
    fi
else
    echo "  LLM Gateway PID 未记录"
fi

# ================= 2. 停止 Embedding Gateway 服务 =================
echo ""
echo ">>> 停止 Embedding Gateway..."
if [ -n "$EMBED_GATEWAY_PID" ]; then
    if kill -0 "$EMBED_GATEWAY_PID" 2>/dev/null; then
        kill "$EMBED_GATEWAY_PID" 2>/dev/null && echo "  Embedding Gateway (PID $EMBED_GATEWAY_PID) 已发送 SIGTERM" || echo "  Embedding Gateway 停止失败"
    else
        echo "  Embedding Gateway (PID $EMBED_GATEWAY_PID) 不存在或已退出"
    fi
else
    echo "  Embedding Gateway PID 未记录"
fi

# ================= 3. 停止 LLM vLLM 实例 =================
echo ""
echo ">>> 停止 LLM vLLM 实例..."
if [ -n "$LLM_INSTANCE_PIDS" ]; then
    for pid in $LLM_INSTANCE_PIDS; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null && echo "  LLM Instance (PID $pid) 已停止" || echo "  LLM Instance (PID $pid) 停止失败"
        else
            echo "  LLM Instance (PID $pid) 不存在或已退出"
        fi
    done
else
    echo "  LLM Instance PIDs 未记录，尝试按端口匹配..."
    for i in "${!LLM_GPU_ARRAY[@]}"; do
        PORT=$((LLM_BASE_PORT + 1 + i))
        # 按端口匹配进程
        FOUND_PIDS=$(lsof -ti :$PORT 2>/dev/null || true)
        if [ -n "$FOUND_PIDS" ]; then
            for fp in $FOUND_PIDS; do
                kill -0 "$fp" 2>/dev/null && kill "$fp" 2>/dev/null && echo "  端口 $PORT 进程 (PID $fp) 已停止"
            done
        fi
    done
fi

# ================= 4. 停止 Embedding vLLM 实例 =================
echo ""
echo ">>> 停止 Embedding vLLM 实例..."
if [ -n "$EMBED_INSTANCE_PIDS" ]; then
    for pid in $EMBED_INSTANCE_PIDS; do
        if kill -0 "$pid" 2>/dev/null; then
            kill "$pid" 2>/dev/null && echo "  Embed Instance (PID $pid) 已停止" || echo "  Embed Instance (PID $pid) 停止失败"
        else
            echo "  Embed Instance (PID $pid) 不存在或已退出"
        fi
    done
else
    echo "  Embed Instance PIDs 未记录，尝试按端口匹配..."
    for i in "${!EMBED_GPU_ARRAY[@]}"; do
        PORT=$((EMBED_BASE_PORT + 1 + i))
        # 按端口匹配进程
        FOUND_PIDS=$(lsof -ti :$PORT 2>/dev/null || true)
        if [ -n "$FOUND_PIDS" ]; then
            for fp in $FOUND_PIDS; do
                kill -0 "$fp" 2>/dev/null && kill "$fp" 2>/dev/null && echo "  端口 $PORT 进程 (PID $fp) 已停止"
            done
        fi
    done
fi

# ================= 5. 等待进程退出 =================
echo ""
echo ">>> 等待进程退出..."
sleep 3

# ================= 6. 强制终止残留进程 =================
echo ""
echo ">>> 检查残留进程..."

# 按端口检查
REMAINING=0
for PORT in $LLM_BASE_PORT $((LLM_BASE_PORT+1)) $((LLM_BASE_PORT+2)) $((LLM_BASE_PORT+3)) $((LLM_BASE_PORT+4)) $((LLM_BASE_PORT+5)) $((LLM_BASE_PORT+6)) $((LLM_BASE_PORT+7)); do
    PIDS=$(lsof -ti :$PORT 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        for p in $PIDS; do
            echo "  强制终止端口 $PORT 残留进程 (PID $p)..."
            kill -9 "$p" 2>/dev/null || true
            REMAINING=$((REMAINING + 1))
        done
    fi
done

for PORT in $EMBED_BASE_PORT $((EMBED_BASE_PORT+1)) $((EMBED_BASE_PORT+2)) $((EMBED_BASE_PORT+3)) $((EMBED_BASE_PORT+4)) $((EMBED_BASE_PORT+5)) $((EMBED_BASE_PORT+6)) $((EMBED_BASE_PORT+7)); do
    PIDS=$(lsof -ti :$PORT 2>/dev/null || true)
    if [ -n "$PIDS" ]; then
        for p in $PIDS; do
            echo "  强制终止端口 $PORT 残留进程 (PID $p)..."
            kill -9 "$p" 2>/dev/null || true
            REMAINING=$((REMAINING + 1))
        done
    fi
done

if [ $REMAINING -eq 0 ]; then
    echo "  无残留进程"
else
    echo "  已强制终止 $REMAINING 个残留进程"
fi

# ================= 7. 清理 PID 文件 =================
echo ""
echo ">>> 清理 PID 文件..."
if [ -f "$PID_FILE" ]; then
    rm -f "$PID_FILE"
    echo "  PID 文件已删除"
fi

# ================= 8. 清理日志文件（可选） =================
# 如果想保留日志，注释掉下面这行
# rm -f "$LOG_DIR"/*.log

echo ""
echo "------------------------------------------------------"
echo "服务已完全停止"
echo "------------------------------------------------------"
