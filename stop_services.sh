#!/bin/bash

# ==========================================
# GraphRAG (DIGIMON) Service Stopper
# ==========================================

echo "Stopping GraphRAG services..."

# Find and kill vLLM processes
# We search for 'vllm.entrypoints.openai.api_server'
PIDS=$(pgrep -f "vllm.entrypoints.openai.api_server")

if [ -z "$PIDS" ]; then
    echo "✅ No vLLM services found running."
else
    echo "⚠️ Found vLLM processes with PIDs: $PIDS"
    echo "Killing processes..."
    kill -9 $PIDS
    echo "✅ vLLM services stopped."
fi

# Clean up any potential zombie worker processes (VLLM::Worker and VLLM::EngineCore)
# These usually die with the parent, but we can be thorough
WORKER_PIDS=$(pgrep -f "VLLM::Worker")
ENGINE_PIDS=$(pgrep -f "VLLM::EngineCore")

if [ ! -z "$WORKER_PIDS" ]; then
     echo "Cleaning up worker processes..."
     kill -9 $WORKER_PIDS 2>/dev/null
fi

if [ ! -z "$ENGINE_PIDS" ]; then
     echo "Cleaning up engine processes..."
     kill -9 $ENGINE_PIDS 2>/dev/null
fi

echo "=========================================="
echo "All GraphRAG services have been stopped."
echo "=========================================="
