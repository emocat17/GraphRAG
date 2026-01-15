# GraphRAG (DIGIMON) 项目完整使用指南

> **注意**：本项目是一个**命令行实验框架**，用于评估不同的 GraphRAG 方法。它**不是**一个带有 Web UI 的服务，也没有独立的数据库初始化脚本。所有的操作均通过 `main.py` 命令行入口进行。

## 1. 项目配置体系

项目的配置由“基础配置”和“方法配置”两层组成。

### 1.1 基础环境配置
- **配置文件位置**: `Option/Config2.yaml` (以及代码中的 `Option/Config2.py` 默认值)
- **主要作用**: 配置 LLM（大模型）、Embedding（向量模型）、工作目录和数据根目录。
- **关键配置项**:
  ```yaml
  llm:
    api_type: "openai" # 或 "open_llm" (用于 Ollama/LlamaFactory)
    base_url: "https://api.openai.com/v1" # 你的 API 地址
    api_key: "sk-..." 
    model: "gpt-4o"

  embedding:
    api_type: "hf" # 或 "openai"
    model: "sentence-transformers/all-mpnet-base-v2"
    api_key: "..." # 如果需要
    dimensions: 768

  data_root: "Data" # 数据集存放的根目录
  working_dir: "Output" # 实验结果输出目录
  ```

### 1.2 方法配置 (Method Options)
- **配置文件位置**: `Option/Method/*.yaml`
- **主要作用**: 定义具体的 RAG 流程，包括分块策略、构图方式、检索策略和查询生成参数。
- **示例文件**: `Option/Method/RAPTOR.yaml`
- **如何修改**: 复制一份现有的 YAML 文件，修改其中的 `graph_type`, `retriever`, `query` 等参数即可定义一个新的实验方法。

---

## 2. 部署与安装

### 2.1 环境安装
项目提供了 `experiment.yml` 用于创建 Conda 环境。

```bash
# 1. 创建环境
conda env create -f experiment.yml -n digimon

# 2. 激活环境
conda activate digimon

# 3. (Windows 可选) 如果 yml 安装失败，建议手动安装核心依赖
pip install torch transformers sentence-transformers networkx numpy pandas pyyaml loguru tiktoken openai pydantic
```

### 2.2 数据准备
项目默认支持的数据格式为 JSON，需放置在 `data_root` 指定的目录下（例如 `Data/HotpotQA/`）。

必须包含两个文件：
1.  **`Corpus.json`**: 语料库（文档集合）。
2.  **`Question.json`**: 问题集合（包含问题和参考答案）。

*(详细数据格式将在下文“数据格式规范”中说明)*

---

## 3. 运行实验

### 3.1 启动命令
使用 `main.py` 运行实验。你需要指定**方法配置文件**和**数据集名称**。

```bash
# 语法
python main.py -opt <方法配置文件路径> -dataset_name <数据集目录名>

# 示例：在 HotpotQA 数据集上运行 RAPTOR 方法
python main.py -opt Option/Method/RAPTOR.yaml -dataset_name HotpotQA
```

> **Windows 用户提示**: 建议在路径中使用正斜杠 `/` 或确保路径分隔符正确，避免转义问题。

### 3.2 运行流程
当你运行上述命令时，系统会依次执行以下步骤（由 `main.py` 编排）：
1.  **加载配置**: 合并 `Config2.yaml` 和指定的 `-opt` YAML 文件。
2.  **数据加载**: 读取 `Corpus.json` 和 `Question.json`。
3.  **构建/加载图与索引 (Insert Stage)**:
    - 文档分块 (Chunking)
    - 构建图 (Building Graph): 如 TreeGraph, PassageGraph 等。
    - 构建向量索引 (Index Building): 对实体、关系或子图建立索引。
4.  **执行查询 (Query Stage)**:
    - 遍历 `Question.json` 中的问题。
    - 根据配置的 `Retriever` 和 `Query` 策略生成答案。
5.  **评估 (Evaluation Stage)**:
    - 调用 `Evaluator` 计算指标（如准确率等）。
    - 结果保存在 `working_dir/<dataset_name>/<exp_name>/` 目录下。

### 3.3 输出结果
运行完成后，检查 `working_dir`（默认为当前目录或 `Output`）下的文件夹：
- `Results/results.json`: 包含每个问题的模型回答。
- `Metrics/metrics.json`: 包含整体评测指标。
- `Configs/`: 本次运行的配置备份。

---

## 4. 高级配置与扩展

### 4.1 数据格式规范
项目要求数据存放在 `data_root/<DatasetName>/` 下，且必须包含以下两个文件（JSONL 格式）：

#### 1. `Corpus.json` (文档库)
每一行是一个 JSON 对象，包含文档的标题和内容。
```json
{"title": "文档标题1", "context": "文档内容全文...", "id": 0}
{"title": "文档标题2", "context": "文档内容全文...", "id": 1}
```
*(注意：代码中读取字段为 `title` 和 `context`，`doc_id` 会自动生成)*

#### 2. `Question.json` (问答对)
每一行是一个 JSON 对象，包含问题和参考答案。
```json
{"question": "你的问题是什么？", "answer": "参考答案文本"}
{"question": "第二个问题...", "answer": "答案..."}
```

### 4.2 支持的图类型 (Graph Types)
在方法配置文件（如 `Option/Method/*.yaml`）中，`graph.graph_type` 参数支持以下值（对应 `Core/Graph` 中的实现）：

| 类型名称 | 描述 | 对应类 |
| :--- | :--- | :--- |
| `er_graph` | 实体-关系图 (Entity-Relationship Graph) | `ERGraph` |
| `tree_graph` | 树状图 (如 RAPTOR 使用) | `TreeGraph` |
| `tree_graph_balanced` | 平衡树状图 | `TreeGraphBalanced` |
| `passage_graph` | 段落图 (Passage Graph) | `PassageGraph` |
| `rkg_graph` | 丰富知识图谱 (Rich Knowledge Graph) | `RKGraph` |

### 4.3 提示词 (Prompt) 定制
目前项目的 Prompt **不是**通过 YAML 配置的，而是直接定义在 Python 代码中。
- **文件位置**: `Core/Prompt/` 目录。
- **主要文件**:
    - `GraphPrompt.py`: 包含实体抽取、关系抽取等构建图所需的 Prompt。
    - `QueryPrompt.py`: 包含回答生成、重写问题等查询阶段的 Prompt。
    - `RaptorPrompt.py`: 专门用于 RAPTOR 方法的 Prompt。

若需修改 Prompt，请直接编辑上述 Python 文件中的字符串常量（如 `ENTITY_EXTRACTION`）。

### 4.4 增加新的 RAG 方法（配置驱动）
不需要写代码，只需组合现有的算子。
1.  在 `Option/Method/` 下新建 `MyMethod.yaml`。
2.  修改关键参数，例如：
    - `graph.graph_type`: 切换图类型（如 `tree_graph` vs `passage_graph`）。
    - `retriever.query_type`: 切换查询策略（如 `basic` vs `ppr`）。
3.  运行 `python main.py -opt Option/Method/MyMethod.yaml ...`。

### 4.5 开发新的组件（代码驱动）
如果配置无法满足需求，需要在 `Core/` 目录下开发新类：
- **新检索器**: 在 `Core/Retriever/` 下继承 `BaseRetriever`，并在 `RetrieverFactory` 注册。
- **新图结构**: 在 `Core/Graph/` 下继承 `BaseGraph`，并在 `GraphFactory` 注册。
- **新查询逻辑**: 在 `Core/Query/` 下继承 `BaseQuery`，并在 `QueryFactory` 注册。

