#!/bin/bash

# ==========================================
# GraphRAG (DIGIMON) Local Service Launcher
# ==========================================

# 1. Environment Setup
# Clear proxy settings to prevent local connection issues
export HTTP_PROXY=""
export HTTPS_PROXY=""
export ALL_PROXY=""

# Path to the conda environment python
# Adjust if your environment name is different
PYTHON_EXEC="/root/anaconda3/envs/rag/bin/python"

echo "=========================================="
echo "Initializing GraphRAG Local Services..."
echo "=========================================="

# 2. Check and Start vLLM (Chat Model)
# The project requires an OpenAI-compatible API for the chat model.
# We use vLLM to serve the local Meta-Llama-3-8B-Instruct model.

VLLM_PORT=8000
MODEL_PATH="/root/model/LLM-Research/Meta-Llama-3-8B-Instruct"
MODEL_NAME="Meta-Llama-3-8B-Instruct"

echo "Checking vLLM service status..."

if pgrep -f "vllm.entrypoints.openai.api_server" > /dev/null; then
    echo "✅ vLLM server is already running."
else
    echo "🚀 Starting vLLM server on port $VLLM_PORT..."
    echo "   Model: $MODEL_PATH"
    
    # Start vLLM in background
    # --tensor-parallel-size 8: Utilize all 8 GPUs for distributed inference
    # --gpu-memory-utilization 0.8: Leave space for embedding model and other ops
    nohup python -m vllm.entrypoints.openai.api_server \
        --model $MODEL_PATH \
        --served-model-name $MODEL_NAME \
        --port $VLLM_PORT \
        --trust-remote-code \
        --tensor-parallel-size 8 \
        --gpu-memory-utilization 0.8 > vllm.log 2>&1 &
        
    VLLM_PID=$!
    echo "   vLLM process started with PID: $VLLM_PID"
    echo "   Logs are being written to: vllm.log"
    
    # Wait for service to be ready
    echo "⏳ Waiting for vLLM to become ready (this may take a minute)..."
    
    MAX_RETRIES=30
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
echo "   Embedding Model:    Loaded locally via HuggingFace (In-process)"
echo "=========================================="
echo ""
echo "You can now run your experiments using commands like:"
echo "   $PYTHON_EXEC main.py -opt Option/Method/RAPTOR.yaml -dataset_name hotpotqa"
echo ""
