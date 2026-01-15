# LLM / Embedding / Rerank 配置建议

本文件用于统一记录：Embedding、Reranker、生成模型（Chat LLM）与评估裁判（Judge）的推荐组合，并给出论文“实验设置”章节的可复用模板。

## 1. 云端（API）方案

### 1.1 推荐模型清单

- Embedding：OpenAI `text-embedding-3-large`（或 `text-embedding-3-small`）
- Reranker：Cohere `rerank-english-v3.0`（或 v3.5）
- Chat LLM：OpenAI `gpt-4o`（或 `gpt-4o-mini`）
- Judge（评估裁判）：OpenAI `gpt-4o`

### 1.2 组件表（建议写入论文）

| 组件 | 模型 | 标识符 | 作用 | 核心优势 |
|---|---|---|---|---|
| Embedding | OpenAI Text Embedding 3 | text-embedding-3-large | 初始向量检索 | MTEB 得分高、语义覆盖强，常作为 API 基线 |
| Reranker | Cohere Rerank v3 | rerank-english-v3.0 | 上下文重排序与精选 | 显著提升上下文精确度（Context Precision） |
| Generator | GPT-4o | gpt-4o（或 gpt-4o-2024-05-13） | 答案生成 | 指令遵循强、RAG 场景幻觉率低 |
| Evaluator | GPT-4o | gpt-4o | 自动化评分（Judge） | RAGAS/ARES 常用裁判，与人类一致性高 |

## 2. 本地（开源）方案

### 2.1 推荐模型清单

- Embedding：`BAAI/bge-m3`
- Reranker：`BAAI/bge-reranker-v2-m3`
- Chat LLM：`Meta-Llama-3-8B-Instruct`
- Judge（离线可选）：`Prometheus-2`；若允许调用 API，仍建议使用 `gpt-4o`

### 2.2 关键参数与说明

- bge-m3
  - 最大序列长度：8192 tokens，适合长文档切片/长上下文场景对比。
  - 检索模式：建议在论文中说明使用 “Dense Only” 还是 “Hybrid”；为了公平对比多数 RAG 系统，通常以 Dense 作为基线。
- bge-reranker-v2-m3
  - 精度：建议使用 FP16 推理以加速。
  - 输入长度：支持较长文本，减少重排序阶段截断关键证据的风险。

### 2.3 组件表（建议写入论文）

| 组件 | 模型（HuggingFace ID） | 架构 | 作用 | 核心优势 |
|---|---|---|---|---|
| Embedding | BAAI/bge-m3 | BERT-based Hybrid | 向量化索引 | 开源 MTEB 第一梯队，支持多粒度检索 |
| Reranker | BAAI/bge-reranker-v2-m3 | XLM-RoBERTa Cross-Encoder | 结果精排 | 精度高、轻量，和 bge-m3 适配好 |
| Generator | Meta-Llama-3-8B-Instruct | Transformer Decoder | 答案生成 | 2024/2025 开源强基线，推理能力强、显存需求低 |
| Evaluator | Prometheus-2 或 GPT-4o | Mistral/Llama-based 或 API | 自动化评分（Judge） | 离线可用或继续用 API 提升稳定性 |

## 3. 评估指标与 Judge 选择

为了使论文结论更容易被复现与认可，建议使用标准化的 LLM-as-a-Judge 评估框架（例如 RAGAS）。

### 3.1 建议至少报告的核心指标

- Context Precision（上下文精确度）：衡量 Top-K 检索结果中相关内容是否靠前，反映 Embedding 与 Reranker 的协同效果。
- Faithfulness（忠实度）：衡量答案是否基于检索上下文、是否存在幻觉。
- Answer Relevance（答案相关性）：衡量答案是否直接回答了问题。

### 3.2 Judge 模型选择建议

- 最佳实践：即使系统生成模型是本地部署（例如 Llama 3），仍建议使用 `gpt-4o` 作为 Judge 计算分数。
- 原因：小模型（7B/8B）作为裁判往往方差更大、偏差更明显；若必须完全离线，再考虑 Prometheus-2。

## 4. 论文“实验设置”章节写作模板（中文）

### 4.1 实验设置（Experimental Setup）

#### 4.1.1 RAG 流水线配置（Configuration of RAG Pipelines）

为保证提出方法的评估公平且可复现，我们在所有实验中统一了底层模型组件，并提供两套代表性的配置：云端 API 方案与本地开源方案，参考近期基准（例如 RGB [Chen et al., 2024]、LegalBench [Pisano et al., 2024]）。

- 云端（API）方案：使用 OpenAI `text-embedding-3-large` 进行向量检索，使用 Cohere `rerank-english-v3.0` 进行重排序，并使用 `gpt-4o` 进行答案生成。
- 本地（开源）方案：使用 `BAAI/bge-m3` 进行向量检索，使用 `BAAI/bge-reranker-v2-m3` 进行重排序，使用 `Meta-Llama-3-8B-Instruct` 进行答案生成。

#### 4.1.2 实现细节（Implementation Details）

所有文档均采用递归字符切分器处理，chunk 大小为 512 tokens，重叠比例为 10%，以平衡上下文保真与检索粒度。生成阶段温度设置为 0.1，以提高输出稳定性与可复现性。

#### 4.1.3 评估指标（Evaluation Metrics）

我们使用 RAGAS 进行自动化评估，并使用 `gpt-4o` 作为 Judge 计算 Context Precision、Faithfulness 与 Answer Relevance，遵循无参考（reference-free）评估的最佳实践 [Es et al., 2024]。

## 5. 结论与推荐组合

在 2024–2025 的研究语境下，RAG 评估不应止步于“能跑通”。通过 API 组合（OpenAI Embedding + Cohere Rerank + GPT-4o）或开源组合（bge-m3 + bge-reranker + Llama 3），可以显著减少“底层模型差异”对实验结论的干扰，提升可比性与说服力。特别是引入 Reranker 以及使用 Llama 3（而非 Llama 2）通常被视为更现代的实验配置。
