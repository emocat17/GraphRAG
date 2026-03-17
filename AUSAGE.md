# GraphRAG 本地调试/开发/测试配置手册

## 项目定位与目标

- GraphRAG 是一套面向图结构 RAG 方法的统一实验框架，强调模块化、可替换与可评测。
- 项目核心目标是用同一套数据与评测流程对多种图 RAG 方法进行对比与分析。

## 关键流程总览

- 入口：`main.py` 读取方法配置并运行完整评测流程。
- 核心阶段：chunking → graph 构建 → index → retriever_context → query → evaluation。
- 输出：按数据集与方法组织目录，保存结果、配置快照与评测指标。

## 目录与输出约定

- 数据目录：`Data/{dataset_name}`
- 统一输出根目录：`Output/{dataset_name}/{exp_name}/`
  - 其中 `exp_name` 由方法配置里的 `exp_name` 决定（例如 `LightRAG`）。
  - 运行后会生成：
    - `Results/results.json`（JSON Lines）
    - `Configs/`（拷贝的配置文件快照）
    - `Metrics/evaluation_results.csv`

## 本地模型与服务

### vLLM

- 启动脚本：[start_server.sh](file:///root/GraphRAG/start_server.sh)

## 方法清单与定位

- 现有方法配置集中在 `Option/Method/`，通过 `-opt` 选择。
- 常见方法包括：GraphRAG、LGraphRAG、GGraphRAG、HippoRAG、KGP、LightRAG、RAPTOR、ToG 等。

## 数据与输入格式

- 数据根目录：`/root/RAGKnow/Data/{dataset_name}`。
- 语料（corpus）与问题（question）为 JSON Lines 格式，常用字段：
  - corpus: `title`, `context`, `id`
  - question: `question`, `answer`, `id`（可选 `options`, `answer_idx`）

## 常用脚本

- 启动本地推理服务：[start_server.sh](file:///root/GraphRAG/start_server.sh)
- 停止本地推理服务：[stop_server.sh](file:///root/GraphRAG/stop_server.sh)
- 运行主流程：[run_main.sh](file:///root/GraphRAG/run_main.sh)

## 运行命令（默认跑全量 query）


```bash
# 启动和停止服务
bash start_server.sh
bash stop_server.sh

ps aux | grep python
```


```bash
# 启动和中断：一定要使用conda环境：conda activate graphrag
bash run_main.sh
bash kill_run.sh
conda activate graphrag && python Process.py
#跳过图构建：,若图文件存在则可以使用,节约时间
SKIP_GRAPH_BUILD=1 bash run_main.sh


# 完整重建： 
SKIP_GRAPH_BUILD=0 bash run_main.sh

```

```bash
python tests/analyze.py 
python eval_long_narrative.py <path_to_results.json>
python eval_long_narrative.py Output/multihop-rag-base/KariosRAG/Results/results.json


python progress.py -d hotpotqa

```