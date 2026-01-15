# 自定义 RAG 方法开发指南

如果您希望在 GraphRAG 框架中实现自己的 RAG 方法，需要根据您的需求扩展 **Query (查询逻辑)** 和 **Graph (图结构)** 模块。

## 1. 方法扩展架构概述

*   **Config (配置)**: `Option/Method/*.yaml` 定义方法参数，通过 `retriever.query_type` 和 `graph.graph_type` 路由到具体的类；并通过 `query.query_type` 控制输出模式（`qa` / `summary`）。
*   **Query (查询)**: 继承 `Core.Query.BaseQuery.BaseQuery`，实现检索和生成逻辑。
*   **Graph (图构建)**: 继承 `Core.Graph.BaseGraph.BaseGraph`，实现图的构建和存储逻辑。
*   **Factory (工厂)**: 修改 `QueryFactory` 和 `GraphFactory` 注册您的新类。

## 2. 步骤一：创建配置文件

在 `Option/Method/` 目录下新建您的配置文件（例如 `MyMethod.yaml`）：

```yaml
# 继承并覆盖 Config2.yaml 的设置
graph:
  graph_type: my_graph  # 对应 GraphFactory 中的 key
  
retriever:
  query_type: my_query  # 对应 QueryFactory 中的 key

query:
  query_type: qa
  # 您自定义的参数，将在 Query 类中通过 self.config 获取
  my_param_1: 100
  enable_hybrid: True
```

## 3. 步骤二：实现 Query 逻辑

在 `Core/Query/` 目录下新建 `MyQuery.py`，继承 `BaseQuery` 并实现以下核心抽象方法：

```python
from Core.Query.BaseQuery import BaseQuery
from Core.Common.Constants import Retriever

class MyQuery(BaseQuery):
    def __init__(self, config, retriever_context):
        super().__init__(config, retriever_context)

    async def _retrieve_relevant_contexts(self, **kwargs):
        query = kwargs["query"]
        entity_datas = await self._retriever.retrieve_relevant_content(
            type=Retriever.ENTITY,
            mode="vdb",
            seed=query,
            top_k=self.config.top_k,
        )
        chunks = await self._retriever.retrieve_relevant_content(
            type=Retriever.CHUNK,
            mode="entity_occurrence",
            node_datas=entity_datas or [],
        )
        if not chunks:
            return ""
        if isinstance(chunks, list):
            return "\n".join(chunks)
        return str(chunks)

    async def generation_summary(self, query, context):
        if not context:
            return "No context found."
        prompt = f"Context: {context}\nQuestion: {query}\nAnswer:"
        return await self.llm.aask(prompt)

    async def generation_qa(self, query, context):
        return await self.generation_summary(query, context)
```

**注册 Query 类**:
打开 `Core/Query/QueryFactory.py`，在 `__init__` 中添加您的映射：

```python
from Core.Query.MyQuery import MyQuery

class QueryFactory:
    def __init__(self):
        self.creators = {
            "my_query": self._create_my_query,
        }

    @staticmethod
    def _create_my_query(config, retriever):
        return MyQuery(config, retriever)
```

## 4. 步骤三：实现 Graph 结构 (可选)

如果您需要构建特殊的图结构（而非使用现有的 ERGraph 或 TreeGraph），请在 `Core/Graph/` 下新建 `MyGraph.py`：

```python
from Core.Graph.BaseGraph import BaseGraph

class MyGraph(BaseGraph):
    async def _extract_entity_relationship(self, chunk_key_pair):
        pass

    async def _build_graph(self, chunks):
        pass
```

**注册 Graph 类**:
打开 `Core/Graph/GraphFactory.py`，在 `__init__` 中添加您的映射：

```python
from Core.Graph.MyGraph import MyGraph

class GraphFactory:
    def __init__(self):
        self.creators = {
            "my_graph": self._create_my_graph,
        }
    
    @staticmethod
    def _create_my_graph(config, **kwargs):
        return MyGraph(config, **kwargs)
```

## 5. 步骤四：运行验证

完成上述步骤后，使用您的配置文件运行项目：

```bash
python main.py -opt Option/Method/MyMethod.yaml -dataset_name <YourDataset>
```

## 6. 高级定制 (Advanced)

### 6.1 Prompt 定制
Prompt 定义在 `Core/Prompt/` 目录下的 Python 文件中（如 `GraphPrompt.py`）。您可以修改这些文件中的字符串常量来调整 Prompt，或者在您的 Query 类中定义新的 Prompt。

### 6.2 Retriever 定制
如果需要自定义底层的检索原子操作（如特殊的向量检索策略），可以查看 `Core/Retriever/RetrieverFactory.py` 并使用 `@register_retriever_method` 装饰器注册新的检索方法。

#### 6.2.1 内置 Retriever 类型与可用 mode
`BaseQuery` 内部通过 `MixRetriever` 调度不同类型的 Retriever，调用形如：
`await self._retriever.retrieve_relevant_content(type=Retriever.CHUNK, mode="from_relation", ...)`

各类型默认支持的 `mode`（来自各 Retriever 的 `mode_list`）如下：

*   **ChunkRetriever (`type=Retriever.CHUNK`)**: `entity_occurrence`, `ppr`, `from_relation`, `aug_ppr`
*   **EntityRetriever (`type=Retriever.ENTITY`)**: `ppr`, `vdb`, `from_relation`, `tf_df`, `all`, `by_neighbors`, `link_entity`, `get_all`, `from_relation_by_agent`
*   **RelationshipRetriever (`type=Retriever.RELATION`)**: `entity_occurrence`, `from_entity`, `ppr`, `vdb`, `from_entity_by_agent`, `get_all`, `by_source&target`
*   **CommunityRetriever (`type=Retriever.COMMUNITY`)**: `from_entity`, `from_level`
*   **SubgraphRetriever (`type=Retriever.SUBGRAPH`)**: `concatenate_information_return_list`, `induced_subgraph_return_networkx`, `k_hop_return_set`, `paths_return_list`, `neighbors_return_list`
