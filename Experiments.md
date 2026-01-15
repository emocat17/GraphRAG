# GraphRAG (DIGIMON) 项目使用指南

本指南基于 `d:\GitWorks\GraphRAG\README.md` 及项目实际代码结构整理，旨在提供清晰的配置、部署、运行及扩展说明。

---

## 1. 配置指南 (Configuration)

本项目使用 YAML 文件进行配置，采用双层配置结构：**基础配置** (`Option/Config2.yaml`) 和 **方法配置** (`Option/Method/*.yaml`)。此外，代码还会尝试读取用户目录下的覆盖配置：`~/Option/Config2.yaml`（用于放置自己的 API Key、data_root 等本机参数）。

### 1.1 配置文件结构

*   **基础配置**: `Option/Config2.yaml`
    *   包含全局通用的设置，如 LLM API Key、Embedding 模型、工作目录等。
    *   **关键字段**:
        *   `llm`: 设置 `api_key`, `base_url`, `model` (例如 `gpt-3.5-turbo`)。
        *   `data_root`: 数据集根目录（通常指向本项目的 `Data/` 目录）。
        *   `working_dir`: 实验输出根目录（最终会在其下按 `dataset_name` 再分一层目录）。
*   **方法配置**: `Option/Method/` 目录下 (例如 `RAPTOR.yaml`, `KGP.yaml`)
    *   针对特定 RAG 方法的参数覆盖。
    *   **关键字段**:
        *   `graph.graph_type`: 指定使用的图构建类 (如 `tree_graph`, `er_graph`)。
        *   `retriever.query_type`: 指定使用的查询逻辑类 (如 `basic`, `ppr`, `tog`)。
        *   `query`: 查询阶段的具体参数。

### 1.2 修改配置示例

在运行前，请确保 `Option/Config2.yaml` 中的 LLM 设置正确：

```yaml
llm:
  api_type: "openai" # 或 "azure"
  api_key: "YOUR_API_KEY"
  base_url: "https://api.openai.com/v1"
  model: "gpt-4o"
```

---

## 2. 部署指南 (Deployment)

本项目是一个基于命令行的实验框架，建议使用 Conda 环境运行。

### 2.1 环境准备

1.  **创建 Conda 环境**:
    ```bash
    conda env create -f experiment.yml
    conda activate graphrag
    ```

### 2.2 数据集准备与配置 (Data Preparation)

本项目支持配置多个数据集，通过文件夹名称进行管理。
运行前请确保配置中的 `data_root` 指向数据集根目录（例如 `d:\GitWorks\GraphRAG\Data` 或 `./Data`）。

#### 2.2.1 目录结构规范
所有数据集均存放于 `Data/` 目录下。每个数据集对应一个独立的文件夹（Folder Name 即为 `dataset_name`），文件夹内**必须**包含以下两个文件名（不可修改）：
*   `Corpus.json`: 文档库文件
*   `Question.json`: 问题集文件

**目录结构示例**:
```text
d:\GitWorks\GraphRAG\Data\
├── HotpotQA\              <-- 数据集名称: HotpotQA
│   ├── Corpus.json        <-- 必须重命名为此
│   └── Question.json      <-- 必须重命名为此
├── MedicalQA\             <-- 数据集名称: MedicalQA
│   ├── Corpus.json
│   └── Question.json
└── Finance_V1\            <-- 数据集名称: Finance_V1
    ├── Corpus.json
    └── Question.json
```

#### 2.2.2 文件格式说明
文件采用 **JSONL (JSON Lines)** 格式，每行一个独立的 JSON 对象。

*   **Corpus.json (文档库)**
    ```json
    {"title": "文档标题1", "context": "文档内容全文...", "id": 0}
    {"title": "文档标题2", "context": "文档内容全文...", "id": 1}
    ```
    *   `title`: 文档标题（必须）
    *   `context`: 文档正文内容（必须，构建图谱和检索的基础）
    *   `id`: 可选字段（当前代码不会读取该字段）

*   **Question.json (问题集)**
    ```json
    {"question": "你的问题是什么？", "answer": "参考答案(可为空字符串)"}
    {"question": "第二个问题...", "answer": "参考答案"}
    ```
    *   `question`: 用于测试的问题文本（必须）
    *   `answer`: 参考答案（必须；如果没有参考答案，请填空字符串 `""`，以兼容当前代码的读取与评估流程）

#### 2.2.3 常见问题 (FAQ)
> **Q: 我下载的 HotpotQA 有很多领域的数据，如何处理？**
> **A:** 您需要在 `Data/` 下为每个领域创建一个独立的文件夹，并将该领域的数据文件放入并重命名。例如：
> *   将生物领域数据放入 `Data/HotpotQA_Bio/` 并重命名为 `Corpus.json` 和 `Question.json`。
> *   将金融领域数据放入 `Data/HotpotQA_Finance/` 并重命名。
> *   运行时分别使用 `-dataset_name HotpotQA_Bio` 和 `-dataset_name HotpotQA_Finance`。

---

## 3. 运行指南 (Running)

项目入口为 `main.py`，通过命令行参数指定配置文件和数据集。

### 3.1 启动命令

使用 `-dataset_name` 参数指定 `Data/` 目录下的文件夹名称。

```bash
# 基本用法
python main.py -opt Option/Method/<MethodName>.yaml -dataset_name <DatasetName>

# 示例 1：运行默认的 HotpotQA 数据集
python main.py -opt Option/Method/RAPTOR.yaml -dataset_name HotpotQA

# 示例 2：运行自定义的 MedicalQA 数据集 (对应 Data/MedicalQA 目录)
python main.py -opt Option/Method/RAPTOR.yaml -dataset_name MedicalQA
```

#### 3.1.1 重要说明：`-opt` 路径分隔符
`main.py` 在保存配置快照时会按字符串方式解析 `-opt` 参数路径，因此在 Windows 下也请使用 **正斜杠 `/`**（例如 `Option/Method/RAPTOR.yaml`），不要使用反斜杠 `\` 或绝对路径。

### 3.2 运行流程说明

`main.py` 会依次执行以下步骤：
1.  **Chunking**: 读取指定数据集下的 `Corpus.json` 并切分为文本块。
2.  **Build Graph**: 根据配置 (`graph_type`) 构建知识图谱。
3.  **Index Building**: 为实体和关系构建向量索引。
4.  **Query**: 读取指定数据集下的 `Question.json` 进行回答。
5.  **Evaluation**: (可选) 如果配置了评估模块，会自动评估回答质量。

#### 3.2.1 重要说明：默认只跑前 10 个问题
当前 `main.py` 中查询循环将 `dataset_len` 强制设置为 10，因此默认只会对 `Question.json` 的前 10 条记录进行检索与评估。若希望跑全量数据，请修改 `main.py` 中的 `dataset_len = 10`。

### 3.3 结果查看

运行结果将保存在配置中 `working_dir`（基础输出目录）下。代码会自动把 `dataset_name` 拼接到 `working_dir` 后面，因此最终目录结构为：
`<working_dir>/<dataset_name>/<exp_name>/Results/results.json`

例如（默认 `working_dir: ./Output` 且 `exp_name: default`）：`.\Output\HotpotQA\default\Results\results.json`

---

## 4. 自定义 RAG 方法开发指南

如果您希望在 GraphRAG 框架中实现自己的 RAG 方法（如自定义图构建或检索逻辑），请参考独立的开发指南文档：

👉 **[自定义 RAG 方法开发指南 (GraphAdd.md)](GraphAdd.md)**

该文档详细说明了如何：
1.  创建新的方法配置文件。
2.  继承 `BaseQuery` 实现自定义检索逻辑。
3.  继承 `BaseGraph` 实现自定义图结构。
4.  在工厂类中注册您的新组件。
