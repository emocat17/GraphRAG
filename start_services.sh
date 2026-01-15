#!/bin/bash

# ==========================================
# GraphRAG (DIGIMON) Local Service Launcher
# ==========================================

# --- Configuration ---

# GPUs to use for vLLM (Chat Model)
# Specify GPU IDs separated by commas (e.g., "0,1,2,3,4,5")
# Note: Tensor Parallel size must divide the number of attention heads (32 for Llama 3 8B).
# So we use 4 GPUs (32 is divisible by 4). 6 GPUs (32/6) is not allowed.
VLLM_GPU_IDS="2,3"

# GPUs to reserve for Python/Main script (Embedding & Graph Ops)
# These will NOT be used by vLLM.
PYTHON_GPU_IDS="4,5,6,7"

# vLLM Configuration
VLLM_PORT=8000
MODEL_PATH="/root/model/LLM-Research/Meta-Llama-3-8B-Instruct"
MODEL_NAME="Meta-Llama-3-8B-Instruct"
# GPU Memory Utilization for vLLM (0.9 is usually safe if GPUs are isolated)
VLLM_GPU_UTIL=0.9

# Python Environment
PYTHON_EXEC="/root/anaconda3/envs/rag/bin/python"

# ---------------------

# 1. Environment Setup
export HTTP_PROXY=""
export HTTPS_PROXY=""
export ALL_PROXY=""

echo "=========================================="
echo "Initializing GraphRAG Local Services..."
echo "=========================================="

# Calculate Tensor Parallelism size based on VLLM_GPU_IDS
TP_SIZE=$(echo $VLLM_GPU_IDS | tr ',' '\n' | wc -l)
echo "Configuration:"
echo "   vLLM GPUs:       $VLLM_GPU_IDS (Count: $TP_SIZE)"
echo "   Python GPUs:     $PYTHON_GPU_IDS"
echo "   vLLM Mem Util:   $VLLM_GPU_UTIL"

# 2. Check and Start vLLM (Chat Model)

echo "Checking vLLM service status..."

if pgrep -f "vllm.entrypoints.openai.api_server" > /dev/null; then
    echo "✅ vLLM server is already running."
else
    echo "🚀 Starting vLLM server on port $VLLM_PORT..."
    echo "   Model: $MODEL_PATH"
    
    # Isolate GPUs for vLLM
    export CUDA_VISIBLE_DEVICES=$VLLM_GPU_IDS
    
    # Start vLLM in background
    nohup python -m vllm.entrypoints.openai.api_server \
        --model $MODEL_PATH \
        --served-model-name $MODEL_NAME \
        --port $VLLM_PORT \
        --trust-remote-code \
        --tensor-parallel-size $TP_SIZE \
        --gpu-memory-utilization $VLLM_GPU_UTIL > vllm.log 2>&1 &
        
    VLLM_PID=$!
    echo "   vLLM process started with PID: $VLLM_PID"
    echo "   Logs are being written to: vllm.log"
    
    # Wait for service to be ready
    echo "⏳ Waiting for vLLM to become ready (this may take a minute)..."
    
    MAX_RETRIES=60
    COUNT=0
    while ! curl -s http://localhost:$VLLM_PORT/v1/models > /dev/null; do
        sleep 5
        COUNT=$((COUNT+1))
        if [ $COUNT -ge $MAX_RETRIES ]; then
            echo "❌ Timeout waiting for vLLM to start. Please check vllm.log for errors."
            exit 1
        fi
        echo -n "."
    done
    echo ""
    echo "✅ vLLM is ready!"
fi

echo "=========================================="
echo "Service Status:"
echo "   Chat Model (vLLM):  http://localhost:$VLLM_PORT/v1"
echo "   vLLM Device Map:    GPUs $VLLM_GPU_IDS"
echo "=========================================="
echo ""
echo "To run your experiment using the RESERVED GPUs ($PYTHON_GPU_IDS), use:"
echo ""
echo "   CUDA_VISIBLE_DEVICES=$PYTHON_GPU_IDS $PYTHON_EXEC main.py -opt Option/Method/RAPTOR.yaml -dataset_name hotpotqa"
echo ""
echo "=========================================="
