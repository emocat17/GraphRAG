# GraphRAG (DIGIMON) 使用指南

本指南详细说明了如何配置、启动服务以及运行 GraphRAG 实验。

## 1. 启动服务 (vLLM)

使用 `start_services.sh` 脚本来启动本地 vLLM 服务。该脚本会自动处理 GPU 分配和模型加载。

### 命令
```bash
bash start_services.sh
```

### 配置说明
您可以在 `start_services.sh` 文件的顶部修改以下配置：
- 比如:
*   **VLLM_GPU_IDS**: 指定分配给 vLLM (Chat Model) 的 GPU ID 列表。
    *   *默认*: `"0,1,2,3"` (4张卡)
    *   *注意*: Llama-3-8B 模型要求 Tensor Parallel size 能整除 32 (如 2, 4, 8)。
*   **PYTHON_GPU_IDS**: 指定预留给 Python 主程序 (Embedding, Clustering 等) 的 GPU ID 列表。
    *   *默认*: `"4,5,6,7"` (4张卡)
*   **VLLM_PORT**: vLLM 服务端口 (默认 8000)。
*   **MODEL_PATH**: 模型路径。

### 启动后检查
脚本运行后会输出类似以下信息，表示服务已就绪：
```
✅ vLLM is ready!
Service Status:
   Chat Model (vLLM):  http://localhost:8000/v1
```

---

## 2. 运行实验 (Main Experiment)

服务启动后，使用以下命令运行主实验程序。请确保 `CUDA_VISIBLE_DEVICES` 与 `start_services.sh` 中配置的 `PYTHON_GPU_IDS` 一致，以避免显存冲突。

### 命令
```bash
export CUDA_VISIBLE_DEVICES=4,5,6,7
/root/anaconda3/envs/rag/bin/python main.py -opt Option/Method/RAPTOR.yaml -dataset_name hotpotqa

export CUDA_VISIBLE_DEVICES=4,5,6,7
/root/anaconda3/envs/rag/bin/python main.py -opt Option/Method/LightRAG.yaml -dataset_name multihop-rag

export CUDA_VISIBLE_DEVICES=2,3,4,5,6,7
/root/anaconda3/envs/rag/bin/python main.py -opt Option/Method/LightRAG.yaml -dataset_name multihop-rag
```

### 参数说明
*   `CUDA_VISIBLE_DEVICES=4,5,6,7`: 限制 Python 进程仅能看到和使用后 4 张 GPU，避免干扰 vLLM。
*   `-opt Option/Method/RAPTOR.yaml`: 指定实验配置文件。
*   `-dataset_name hotpotqa`: 指定数据集名称。

---

## 3. 停止服务

实验结束或需要重启时，使用 `stop_services.sh` 脚本彻底停止所有相关服务。

### 命令
```bash
bash stop_services.sh
```

### 功能
*   停止 `vllm.entrypoints.openai.api_server` 主进程。
*   清理残留的 `VLLM::Worker` 和 `VLLM::EngineCore` 僵尸进程，释放 GPU 显存。

---

## 4. 性能优化说明 (GMM GPU 加速)

针对聚类阶段 (Clustering) 速度慢的问题，我们已集成自动 GPU 加速功能。

*   **机制**: 程序会自动检测是否可用 GPU。
    *   如果可用且数据量 > 2000，将自动调用 `Core.Graph.GMMTorch` (基于 PyTorch 实现的 GPU 版 GMM) 进行加速。
    *   否则，自动回退到 CPU (sklearn) 版本。
*   **效果**: 在大数据集上，聚类速度可提升数倍，且 CPU 利用率会更均衡（移除了人为的串行等待）。
*   **无需额外操作**: 只要正确设置了 `CUDA_VISIBLE_DEVICES`，加速功能会自动生效。



```sh
grep -c "Core.Common.CostManager:update_cost" /home/Gitworks/GraphRAG/Output/hotpotqa/LightRAG/Logs/20260116130706.log
```

```sh
du -sh /home/Gitworks/GraphRAG/Output/hotpotqa
```