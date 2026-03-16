#!/bin/bash

# ================= 清理代理设置 =================
# 必须先清理代理，否则会导致连接问题
unset HTTP_PROXY HTTPS_PROXY ALL_PROXY http_proxy https_proxy all_proxy ALL_PROXY
export no_proxy="localhost,127.0.0.1,0.0.0.0"

# ================= 配置区 =================
PYTHON_BIN="/root/anaconda3/bin/python"

# LLM 模型配置
LLM_MODEL_PATH="/root/model/LLM-Research/Meta-Llama-3___1-8B-Instruct"
LLM_SERVED_MODEL_NAME="Meta-Llama-3.1-8B-Instruct"
LLM_BASE_PORT=8000  # LLM 对外暴露的主端口

# Embedding 模型配置
EMBED_MODEL_PATH="/root/model/BAAI/bge-m3"
EMBED_SERVED_MODEL_NAME="bge-m3"
EMBED_BASE_PORT=9000  # Embedding 对外暴露的主端口

LOG_DIR="/root/GraphRAG/logs"

# GPU 配置
NUM_GPUS=8
LLM_GPU_MEMORY_UTILIZATION=0.85  # LLM 每张卡显存占用
EMBED_GPU_MEMORY_UTILIZATION=0.1  # Embedding 每张卡显存占用
MAX_MODEL_LEN=65535        # 5090 显存够大，可以拉满上下文

# ================= GPU 指定（可自定义） =================
# LLM 使用的 GPU 编号，逗号分隔，例如 "4,5,6,7" 或 "0,1,2,3,4,5,6,7"
LLM_GPUS="${LLM_GPUS:-2,3,4,5,6,7}"
# Embedding 使用的 GPU 编号，逗号分隔
EMBED_GPUS="${EMBED_GPUS:-2,3,4,5,6,7}"

# ================= 参数解析 =================
# 支持通过环境变量覆盖，或通过命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        --llm-gpus)
            LLM_GPUS="$2"
            shift 2
            ;;
        --embed-gpus)
            EMBED_GPUS="$2"
            shift 2
            ;;
        --llm-gpus=*)
            LLM_GPUS="${1#*=}"
            shift
            ;;
        --embed-gpus=*)
            EMBED_GPUS="${1#*=}"
            shift
            ;;
        *)
            echo "未知参数: $1"
            echo "用法: $0 [--llm-gpus 0,1,2,3] [--embed-gpus 4,5,6,7]"
            exit 1
            ;;
    esac
done

# 解析 GPU 列表为数组
IFS=',' read -ra LLM_GPU_ARRAY <<< "$LLM_GPUS"
IFS=',' read -ra EMBED_GPU_ARRAY <<< "$EMBED_GPUS"

LLM_NUM_GPUS=${#LLM_GPU_ARRAY[@]}
EMBED_NUM_GPUS=${#EMBED_GPU_ARRAY[@]}

echo "=============================================="
echo "GPU 配置:"
echo "  LLM GPUs:      ${LLM_GPUS} (共 ${LLM_NUM_GPUS} 张)"
echo "  Embed GPUs:    ${EMBED_GPUS} (共 ${EMBED_NUM_GPUS} 张)"
echo "  LLM 显存利用率: ${LLM_GPU_MEMORY_UTILIZATION}"
echo "  Embed 显存利用率: ${EMBED_GPU_MEMORY_UTILIZATION}"
echo "=============================================="

# ================= 写入 PID 文件 =================
PID_DIR="/root/GraphRAG/logs"
mkdir -p "$PID_DIR"

# 记录启动配置到 PID 文件
echo "# LLM config" > "$PID_DIR/server.pid"
echo "LLM_BASE_PORT=$LLM_BASE_PORT" >> "$PID_DIR/server.pid"
echo "LLM_GPUS=$LLM_GPUS" >> "$PID_DIR/server.pid"
echo "LLM_GPU_ARRAY=(${LLM_GPU_ARRAY[*]})" >> "$PID_DIR/server.pid"
echo "LLM_NUM_GPUS=$LLM_NUM_GPUS" >> "$PID_DIR/server.pid"
echo "" >> "$PID_DIR/server.pid"
echo "# Embed config" >> "$PID_DIR/server.pid"
echo "EMBED_BASE_PORT=$EMBED_BASE_PORT" >> "$PID_DIR/server.pid"
echo "EMBED_GPUS=$EMBED_GPUS" >> "$PID_DIR/server.pid"
echo "EMBED_GPU_ARRAY=(${EMBED_GPU_ARRAY[*]})" >> "$PID_DIR/server.pid"
echo "EMBED_NUM_GPUS=$EMBED_NUM_GPUS" >> "$PID_DIR/server.pid"
echo "" >> "$PID_DIR/server.pid"
echo "# Process PIDs (to be filled)" >> "$PID_DIR/server.pid"
echo "LLM_GATEWAY_PID=" >> "$PID_DIR/server.pid"
echo "EMBED_GATEWAY_PID=" >> "$PID_DIR/server.pid"
echo "LLM_INSTANCE_PIDS=\"\" " >> "$PID_DIR/server.pid"
echo "EMBED_INSTANCE_PIDS=\"\" " >> "$PID_DIR/server.pid"

# 清空日志
mkdir -p $LOG_DIR
for i in $(seq 0 7); do
    > "$LOG_DIR/vllm_gpu_$i.log"
    > "$LOG_DIR/vllm_embed_gpu_$i.log"
done
> "$LOG_DIR/gateway.log"
> "$LOG_DIR/embed_gateway.log"
echo "日志已清空"

# ================= 1. 启动 LLM vLLM 实例 =================
echo ""
echo ">>> 启动 LLM 服务 (端口 $LLM_BASE_PORT -> $((LLM_BASE_PORT + LLM_NUM_GPUS)))..."

LLM_PIDS=""
for i in "${!LLM_GPU_ARRAY[@]}"
do
    GPU_ID=${LLM_GPU_ARRAY[$i]}
    INSTANCE_PORT=$((LLM_BASE_PORT + 1 + i))
    LOG_FILE="$LOG_DIR/vllm_gpu_${GPU_ID}.log"

    # 使用 CUDA_VISIBLE_DEVICES 隔离指定显卡
    # 开启 --kv-cache-dtype fp8 (节省显存支持更长上下文)
    # 添加 --enforce-eager 避免 Triton 编译问题
    # 添加 --no-enable-prefix-caching 减少输出随机性
    # NO_COLOR=1 TERM=dumb 避免日志中的颜色符号乱码
    CUDA_VISIBLE_DEVICES=$GPU_ID nohup env NO_COLOR=1 TERM=dumb $PYTHON_BIN -m vllm.entrypoints.openai.api_server \
        --model "${LLM_MODEL_PATH}" \
        --served-model-name "${LLM_SERVED_MODEL_NAME}" \
        --port "${INSTANCE_PORT}" \
        --gpu-memory-utilization "${LLM_GPU_MEMORY_UTILIZATION}" \
        --max-model-len "${MAX_MODEL_LEN}" \
        --dtype auto \
        --kv-cache-dtype fp8 \
        --enforce-eager \
        --no-enable-prefix-caching \
        --disable-log-requests > "${LOG_FILE}" 2>&1 &

    PID=$!
    LLM_PIDS="$LLM_PIDS $PID"
    echo "  [LLM Instance GPU:$GPU_ID] 启动在端口 $INSTANCE_PORT, PID: $PID, 日志: $LOG_FILE"
done

# 2. 动态生成并启动 LLM 负载均衡网关
GATEWAY_SCRIPT="$LOG_DIR/gateway_service.py"

cat <<EOF > "$GATEWAY_SCRIPT"
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import httpx
import itertools

app = FastAPI()
WORKER_PORTS = [${LLM_BASE_PORT} + 1 + i for i in range(${LLM_NUM_GPUS})]
WORKER_URLS = [f"http://localhost:{p}/v1" for p in WORKER_PORTS]
worker_cycle = itertools.cycle(WORKER_URLS)
client = httpx.AsyncClient(timeout=None)

@app.api_route("/v1/{path:path}", methods=["GET", "POST"])
async def proxy(request: Request, path: str):
    target_url = f"{next(worker_cycle)}/{path}"
    headers = dict(request.headers)
    headers.pop("host", None)
    
    # 封装转发逻辑
    req = client.build_request(
        request.method, target_url, headers=headers, 
        content=await request.body(), params=request.query_params
    )
    res = await client.send(req, stream=True)
    return StreamingResponse(res.aiter_raw(), status_code=res.status_code, headers=dict(res.headers))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=${LLM_BASE_PORT})
EOF

nohup env NO_COLOR=1 TERM=dumb $PYTHON_BIN "$GATEWAY_SCRIPT" > "$LOG_DIR/gateway.log" 2>&1 &
GATEWAY_PID=$!
echo "  [LLM Gateway] 启动在端口 $LLM_BASE_PORT, PID: $GATEWAY_PID"

# ================= 3. 启动 Embedding vLLM 实例 =================
echo ""
echo ">>> 启动 Embedding 服务 (端口 $EMBED_BASE_PORT -> $((EMBED_BASE_PORT + EMBED_NUM_GPUS)))..."

EMBED_PIDS=""
for i in "${!EMBED_GPU_ARRAY[@]}"
do
    GPU_ID=${EMBED_GPU_ARRAY[$i]}
    INSTANCE_PORT=$((EMBED_BASE_PORT + 1 + i))
    LOG_FILE="$LOG_DIR/vllm_embed_gpu_${GPU_ID}.log"

    # Embedding 模型使用不同的参数
    CUDA_VISIBLE_DEVICES=$GPU_ID nohup env NO_COLOR=1 TERM=dumb $PYTHON_BIN -m vllm.entrypoints.openai.api_server \
        --model "${EMBED_MODEL_PATH}" \
        --served-model-name "${EMBED_SERVED_MODEL_NAME}" \
        --port "${INSTANCE_PORT}" \
        --gpu-memory-utilization "${EMBED_GPU_MEMORY_UTILIZATION}" \
        --dtype auto \
        --enforce-eager \
        --disable-log-requests > "${LOG_FILE}" 2>&1 &

    PID=$!
    EMBED_PIDS="$EMBED_PIDS $PID"
    echo "  [Embed Instance GPU:$GPU_ID] 启动在端口 $INSTANCE_PORT, PID: $PID, 日志: $LOG_FILE"
done

# 4. 动态生成并启动 Embedding 负载均衡网关
EMBED_GATEWAY_SCRIPT="$LOG_DIR/embed_gateway_service.py"

cat <<EOF > "$EMBED_GATEWAY_SCRIPT"
import uvicorn
from fastapi import FastAPI, Request
from fastapi.responses import StreamingResponse
import httpx
import itertools

app = FastAPI()
WORKER_PORTS = [${EMBED_BASE_PORT} + 1 + i for i in range(${EMBED_NUM_GPUS})]
WORKER_URLS = [f"http://localhost:{p}/v1" for p in WORKER_PORTS]
worker_cycle = itertools.cycle(WORKER_URLS)
client = httpx.AsyncClient(timeout=None)

@app.api_route("/v1/{path:path}", methods=["GET", "POST"])
async def proxy(request: Request, path: str):
    target_url = f"{next(worker_cycle)}/{path}"
    headers = dict(request.headers)
    headers.pop("host", None)
    
    # 封装转发逻辑
    req = client.build_request(
        request.method, target_url, headers=headers, 
        content=await request.body(), params=request.query_params
    )
    res = await client.send(req, stream=True)
    return StreamingResponse(res.aiter_raw(), status_code=res.status_code, headers=dict(res.headers))

if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=${EMBED_BASE_PORT})
EOF

nohup env NO_COLOR=1 TERM=dumb $PYTHON_BIN "$EMBED_GATEWAY_SCRIPT" > "$LOG_DIR/embed_gateway.log" 2>&1 &
EMBED_GATEWAY_PID=$!
echo "  [Embed Gateway] 启动在端口 $EMBED_BASE_PORT, PID: $EMBED_GATEWAY_PID"

# ================= 5. 更新 PID 文件 =================
# 重新写入完整的 PID 信息
cat <<EOF > "$PID_DIR/server.pid"
# LLM config
LLM_BASE_PORT=$LLM_BASE_PORT
LLM_GPUS=$LLM_GPUS
LLM_GPU_ARRAY=(${LLM_GPU_ARRAY[*]})
LLM_NUM_GPUS=$LLM_NUM_GPUS

# Embed config
EMBED_BASE_PORT=$EMBED_BASE_PORT
EMBED_GPUS=$EMBED_GPUS
EMBED_GPU_ARRAY=(${EMBED_GPU_ARRAY[*]})
EMBED_NUM_GPUS=$EMBED_NUM_GPUS

# Process PIDs
LLM_GATEWAY_PID=$GATEWAY_PID
EMBED_GATEWAY_PID=$EMBED_GATEWAY_PID
LLM_INSTANCE_PIDS="$LLM_PIDS"
EMBED_INSTANCE_PIDS="$EMBED_PIDS"
EOF

echo ""
echo "------------------------------------------------------"
echo "集群已在后台启动！"
echo "LLM 主 API 地址: http://localhost:${LLM_BASE_PORT}/v1"
echo "Embedding 主 API 地址: http://localhost:${EMBED_BASE_PORT}/v1"
echo "你可以通过 'tail -f $LOG_DIR/vllm_gpu_${LLM_GPU_ARRAY[0]}.log' 查看 LLM 加载进度"
echo "你可以通过 'tail -f $LOG_DIR/vllm_embed_gpu_${EMBED_GPU_ARRAY[0]}.log' 查看 Embedding 加载进度"
echo "PID 文件: $PID_DIR/server.pid"
echo "现在可以安全退出终端了。"
echo "------------------------------------------------------"
