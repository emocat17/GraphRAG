# In-depth Analysis of Graph-based RAG in a Unified Framework [Experiment, Analysis & Benchmark]

# ABSTRACT

Graph-based Retrieval-Augmented Generation (RAG) has proven effective in integrating external knowledge into large language models (LLMs), improving their factual accuracy, adaptability, interpretability, and trustworthiness. A number of graph-based RAG methods have been proposed in the literature. However, these methods have not been systematically and comprehensively compared under the same experimental settings. In this paper, we first summarize a unified framework to incorporate all graph-based RAG methods from a high-level perspective. We then extensively compare representative graph-based RAG methods over a range of questing-answering (QA) datasets – from specific questions to abstract questions – and examine the effectiveness of all methods, providing a thorough analysis of graph-based RAG approaches. As a byproduct of our experimental analysis, we are also able to identify new variants of the graph-based RAG methods over specific QA and abstract QA tasks respectively, by combining existing techniques, which outperform the state-of-the-art methods. Finally, based on these findings, we offer promising research opportunities. We believe that a deeper understanding of the behavior of existing methods can provide new valuable insights for future research.

# PVLDB Reference Format:

Yingli Zhou, Yaodong Su, Youran Sun, Shu Wang, Taotao Wang, Runyuan He, Yongwei Zhang, Sicong Liang, Xilin Liu, Yuchi Ma, and Yixiang Fang. In-depth Analysis of Graph-based RAG in a Unified Framework

[Experiment, Analysis & Benchmark]. PVLDB, 18(1): XXX-XXX, 2025. doi:XX.XX/XXX.XX

# PVLDB Artifact Availability:

The source code, data, and/or other artifacts have been made available at https://github.com/JayLZhou/GraphRAG.

# 1 INTRODUCTION

The development of Large Language Models (LLMs) like GPT-4 [1], Qwen2.5 [89], and Llama 3.1 [14] has sparked a revolution in the field of artificial intelligence [22, 31, 46, 54, 63, 83, 84, 96]. Despite their remarkable comprehension and generation capabilities, LLMs may still generate incorrect outputs due to a lack of domain-specific

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8ce037ee9d7895d30558ea3e30c08c4f610b1f85872d016f2adcaca6bb29ce7a.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/25c5b94dea025fea3ad693800185117da8b914f27104a1bb3b443951ded7b131.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/3da2da7757eee4ca85dd8dc41c0e06463c6f2104fe9a4aab23618cfb8e3d726d.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f18919ded4d8ea7ccb9071bca3cf9fd5cdb759dc0f8c0df1634d108f8697b468.jpg)



Figure 1: Overview of vanilla RAG and graph-based RAG.


knowledge, real-time updated information, and proprietary knowledge, which are outside LLMs' pre-training corpus, known as "hallucination" [67].

To bridge this gap, the Retrieval Augmented Generation (RAG) technique [18, 21, 30, 32, 87, 91, 94] has been proposed, which supplements LLM with external knowledge to enhance its factual accuracy and trustworthiness. Given a user query  $Q$ , the key idea of naive-based RAG [42] (i.e., vanilla RAG) is to retrieve relevant chunks from the external corpus, and then feed them along with  $Q$  as a prompt into LLM to generate answers. Consequently, RAG techniques have been widely applied in various fields, especially in domains where LLMs need to generate reliable outputs, such as healthcare [54, 83, 96], finance [46, 63], and education [22, 84]. Moreover, RAG has proven highly useful in many data management tasks, including NL2SQL [16, 43], data cleaning [17, 45, 59, 70], knob tuning [23, 41], DBMS diagnosis [74, 97, 98], and SQL rewrite [47, 78]. In turn, the database community has recently begun to actively explore how to build efficient and reliable RAG systems [2, 36]. Due to the important role of the RAG technique in LLM-based applications, numerous RAG methods have been proposed in the past year [30]. Among these methods, the state-of-the-art RAG approaches typically use the graph data as the external data (also called graph-based RAG), since they capture the rich semantic information and link relationships between entities. Unlike vanilla RAG, graph-based RAG methods retrieve relevant information related to the query  $Q$  such as nodes, relationships, or subgraphs—from the graph, and then incorporate this information into the prompt along with  $Q$  for the LLM to generate an answer. The overview of naive-based RAG and graph-based RAG are shown in Figure 1.

Recently, several mainstream database systems have started supporting graph-based RAG, including PostgreSQL [68], Neo4j [62], and Databricks [11]. At the same time, graph-based RAG has become a core component in modern graph-native agentic systems,


Table 1: Classification of existing representative graph-based RAG methods. Index Component indicates which graph elements (e.g., nodes, relationships, communities) are stored in the index.


<table><tr><td>Method</td><td>Graph Type</td><td>Index Component</td><td>Retrieval Primitive</td><td>Retrieval Granularity</td><td>Specific QA</td><td>Abstract QA</td></tr><tr><td>RAPTOR [72]</td><td>Tree</td><td>Tree node</td><td>Question vector</td><td>Tree node</td><td>✓</td><td>✓</td></tr><tr><td>KGP [85]</td><td>Passage Graph</td><td>Entity</td><td>Question</td><td>Chunk</td><td>✓</td><td>✗</td></tr><tr><td>HippoRAG [25]</td><td>Knowledge Graph</td><td>Entity</td><td>Entities in question</td><td>Chunk</td><td>✓</td><td>✗</td></tr><tr><td>G-retriever [29]</td><td>Knowledge Graph</td><td>Entity, Relationship</td><td>Question vector</td><td>Subgraph</td><td>✓</td><td>✗</td></tr><tr><td>ToG [77]</td><td>Knowledge Graph</td><td>Entity, Relationship</td><td>Question</td><td>Subgraph</td><td>✓</td><td>✗</td></tr><tr><td>DALK [44]</td><td>Knowledge Graph</td><td>Entity</td><td>Entities in question</td><td>Subgraph</td><td>✓</td><td>✗</td></tr><tr><td>LGraphRAG [15]</td><td>Textual Knowledge Graph</td><td>Entity, Community</td><td>Question vector</td><td>Entity, Relationship, Chunk, Community</td><td>✓</td><td>✗</td></tr><tr><td>GGraphRAG [15]</td><td>Textual Knowledge Graph</td><td>Community</td><td>Question vector</td><td>Community</td><td>✗</td><td>✓</td></tr><tr><td>FastGraphRAG [19]</td><td>Textual Knowledge Graph</td><td>Entity</td><td>Entities in question</td><td>Entity, Relationship, Chunk</td><td>✓</td><td>✓</td></tr><tr><td>LLightRAG [24]</td><td>Rich Knowledge Graph</td><td>Entity, Relationship</td><td>Low-level keywords in question</td><td>Entity, Relationship, Chunk</td><td>✓</td><td>✓</td></tr><tr><td>GLightRAG [24]</td><td>Rich Knowledge Graph</td><td>Entity, Relationship</td><td>High-level keywords in question</td><td>Entity, Relationship, Chunk</td><td>✓</td><td>✓</td></tr><tr><td>HLightRAG [24]</td><td>Rich Knowledge Graph</td><td>Entity, Relationship</td><td>Both high- and low-level keywords</td><td>Entity, Relationship, Chunk</td><td>✓</td><td>✓</td></tr></table>

such as LangGraph [40] and Chat2Graph [6]. Following the success of graph-based RAG, researchers from fields such as database, data mining, machine learning, and natural language processing have designed efficient and effective graph-based RAG methods [15, 24, 25, 33, 44, 67, 72, 85, 86]. In Table 1, we summarize the key characteristics of 12 representative graph-based RAG methods based on the graph types they rely on, their index components, retrieval primitives and granularity, and the types of tasks they support. After a careful literature review, we make the following observations. First, no prior work has proposed a unified framework to abstract the graph-based RAG solutions and identify key performance factors. Second, existing works focus on evaluating the overall performance, but not individual components. Third, there is no existing comprehensive comparison between all these methods in terms of accuracy and efficiency.

Our work. To address the above issues, in this paper, we conduct an in-depth study on graph-based RAG methods. We first summarize a novel unified framework with four stages, namely 1 Graph building, 2 Index construction, 3 Operator configuration, and 4 Retrieval & generation, which captures the core ideas of all existing methods. Under this framework, we systematically compare 12 existing representative graph-based RAG methods. We conduct comprehensive experiments on the widely used question-answering (QA) datasets, including the specific and abstract questions, which evaluate the effectiveness of these methods in handling diverse query types and provide an in-depth analysis.

In summary, our principal contributions are as follows.

- Summarize a novel unified framework with four stages for graph-based RAG solutions from a high-level perspective (Sections 3 ~ 6).

- Conduct extensive experiments from different angles using various benchmarks, providing a thorough analysis of graph-based RAG methods. Based on our analysis, we identify new variants of graph-based RAG methods, by combining existing techniques, which outperform the state-of-the-art methods (Section 7).

- Summarize lessons learned and propose practical research opportunities that can facilitate future studies (Section 8).

The rest of the paper is organized as follows. In Section 2, we present the preliminaries and introduce a novel unified framework for graph-based RAG solutions in Section 3. In Sections 4 through

6, we compare the graph-based RAG methods under our unified framework. The comprehensive experimental results and analysis are reported in Section 7. We present the learned lessons and a list of research opportunities in Section 8, and Section 9 reviews related work while Section 10 summarizes the paper.

# 2 PRELIMINARIES

In this section, we review some key concepts of LLM and the general workflow of graph-based RAG methods.

# 2.1 Large Language Models (LLMs)

We introduce some fundamental concepts of LLMs, including LLM prompting and retrieval augmented generation (RAG).

LLM Prompting. After instruction tuning on large corpus of human interaction scenarios, LLM is capable of following human instructions to complete different tasks [13, 64]. Specifically, given the task input, we construct a prompt that encapsulates a comprehensive task description. The LLM processes this prompt to fulfill the task and generate the corresponding output. Note that pre-training on trillions of bytes of data enables LLM to generalize to diverse tasks by simply adjusting the prompt [64].

Retrieval Augmented Generation. During completing tasks with prompting, LLMs often generate erroneous or meaningless responses, i.e., the hallucination problem [31]. To mitigate the problem, retrieval augmented generation (RAG) is utilized as an advanced LLM prompting technique by using the knowledge within the external corpus, typically including two major steps [21]: (1) retrieval: given a user question  $Q$ , using the index to retrieve the most relevant (i.e., top- $k$ ) chunks to  $Q$ , where the large corpus is first split into smaller chunks, and (2) generation: guiding LLM to generate answers with the retrieved chunks along with  $Q$  as a prompt.

# 2.2 Graph-based RAG

Unlike vanilla RAG, graph-based RAG methods employ graph structures built from external corpus to enhance contextual understanding in LLMs and generate more informed and accurate responses [67]. Typically, graph-based RAG methods are composed of three major stages: (1) graph building: given a large corpus  $\mathcal{D}$  with  $d$  chunks, for each chunk, an LLM extracts nodes and edges, which are then combined to construct a graph  $\mathcal{G}$ ; (2) retrieval: given a user question  $Q$ , using the index to retrieve the most relevant

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f4abddaf56626ea2023ec3bbd021d4d58404154e55092a74087065ef2d1653b9.jpg)



Figure 2: Workflow of graph-based RAG methods under our unified framework.


information (e.g., nodes or subgraphs) from  $\mathcal{G}$ , and (3) generation: guiding LLM to generate answers by incorporating the retrieved information into the prompt along with  $Q$ .

# 3 A UNIFIED FRAMEWORK

In this section, we develop a novel unified framework, consisting of four stages: 1 Graph building, 2 Index construction, 3 Operator configuration, and 4 Retrieval & generation, which can cover all existing graph-based RAG methods, as shown in Algorithm 1.


Algorithm 1: A unified framework for graph-based RAG


input :Corpus  $\mathcal{D}$  ,user question  $Q$  ,and parameters  $\mathcal{P}$  output:The answers for user question  $Q$    
1  $C\gets$  split  $\mathcal{D}$  into multiple chunks; // (1) Graph building.   
2  $\mathcal{G}\leftarrow$  GraphBuilding(C); // (2) Index construction.   
3  $I\gets$  IndexConstruction(G,C); // (3)Operator configuration.   
4  $O\gets$  OperatorConfiguration(P); // (4) Retrieve relevant information and generate response.   
5  $\mathcal{R}\gets$  Retrieval&generation(G,I,O,Q,C);   
6 return  $\mathcal{R}$

Specifically, given the large corpus  $\mathcal{D}$ , we first split it into multiple chunks  $C$  (line 1). We then sequentially execute operations in the following four stages (lines 2-5): (1) Build the graph  $\mathcal{G}$  for input chunks  $C$  (Section 4); (2) Construct the index based on the graph  $\mathcal{G}$  from the previous stage (Section 5); (3) Configure the retriever operators for subsequent retrieving stages (Section 6), and (4) For the input user question  $Q$ , retrieve relevant information from  $\mathcal{G}$  using the selected operators and feed them along with the question  $Q$  into the LLM to generate the answer. The workflow of graph-based RAG methods under our framework is shown in Figure 2. We note that graph-based RAG methods differ across the four stages. Specifically, as shown in Table 1, different methods construct distinct types of graphs in Stage ①, build different indices in Stage ②, and retrieve information at varying levels of granularity. Consequently, they employ different operators for retrieval, leading to variations in both Stage ③ and Stage ④. Note that the query is first converted

into a retrieval primitive, which serves as the basis for retrieval in each method (see Section 6.3).

# 4 GRAPH BUILDING

The graph building stage aims to transfer the input corpus into a graph, serving as a fundamental component in graph-based RAG methods. Before building a graph, the corpus is first split into smaller chunks. Then, an LLM or other tools are used to construct nodes and edges based on these chunks, as shown in Figure 2①. We note that this preprocessing step is essential for all RAG methods. Further details are provided in our technical report [71]. There are five types of graphs, each with a corresponding construction method; we present a brief description of each graph type and its construction method below:

Passage Graph. In the passage graph (PG), each chunk represents a node, and edges are built by the entity linking tools [85]. If two chunks contain a number of the same entities larger than a threshold, we link an edge for these two nodes.

Tree. The tree is constructed in a progressive manner, where each chunk represents the leaf node in the tree. Then, it uses an LLM to generate higher-level nodes. Specifically, at the  $i$ -th layer, the nodes of  $(i + 1)$ -th layer are created by clustering nodes from the  $i$ -th layer that does not yet have parent nodes. For each cluster with more than two nodes, the LLM generates a virtual parent node with a high-level summary of its child node descriptions.

$\bullet$  Knowledge Graph. The knowledge graph (KG) is constructed by extracting entities and relationships from each chunk, where each entity represents an object and the relationship denotes the semantic relation between two entities.

4 Textual Knowledge Graph. A textual knowledge graph (TKG) is a specialized KG (following the same construction step as KG), with the key difference being that in a TKG, each entity and relationship is assigned a brief textual description.

$\bullet$  Rich Knowledge Graph. The rich knowledge graph (RKG) is an extended version of TKG, containing more information, including textual descriptions for entities and relationships, as well as keywords for relationships. We summarize the key characteristics of each graph type in Table 2, considering their contained attributes (e.g., inclusion of entity names and descriptions), the time and number of tokens required for construction, the resulting graph size, and the richness of information contained within each graph. In


Table 2: Comparison of different types of graph.


<table><tr><td>Graph</td><td>Entity Name</td><td>Entity Type</td><td>Entity Description</td><td>Relationship Name</td><td>Relationship Keyword</td><td>Relationship Description</td><td>Edge Weight</td><td>Token Consuming</td><td>Graph Size</td><td>Information Richness</td><td>Construction Time</td></tr><tr><td>Tree</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>★</td><td>★</td><td>★★</td><td>★</td></tr><tr><td>PG</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>N/A</td><td>★★★★</td><td>★</td><td>★★★★</td></tr><tr><td>KG</td><td>✓</td><td>✘</td><td>✘</td><td>✓</td><td>✘</td><td>✘</td><td>✓</td><td>★★</td><td>★★</td><td>★★★</td><td>★★</td></tr><tr><td>TKG</td><td>✓</td><td>✓</td><td>✓</td><td>✘</td><td>✘</td><td>✓</td><td>✓</td><td>★★★</td><td>★★★</td><td>★★★★</td><td>★★★</td></tr><tr><td>RKG</td><td>✓</td><td>✓</td><td>✓</td><td>✘</td><td>✓</td><td>✓</td><td>✓</td><td>★★★</td><td>★★★</td><td>★★★★★</td><td>★★★</td></tr></table>

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/5f3559eba9e9b877c1238cab1758fb2422ac0bb9f5715aec27dda6b4b1af9513.jpg)



Figure 3: Examples of five types of graphs.


addition, we provide a case study of how the five types of graphs are constructed from the external corpus in Figure 3. The detailed descriptions are shown in our technical report [71].

# 5 INDEX CONSTRUCTION

To support efficient online querying, existing graph-based RAG methods typically include an index-construction stage, which involves storing graph elements - such as entities and relationships - in a vector database and computing community reports to enable efficient online retrieval, as shown in Figure 2. Generally, there are three types of indices, Node index, Relationship index, and

$\bullet$  Community index, where for the first two types, we use the well-known text-encoder models, such as BERT [12] or ColBert [39] to generate embeddings for nodes or relationships in the graph.

- Node index stores the graph nodes in the vector database. For RAPTOR, G-retriever, DALK, FastGraphRAG, LGraphRAG, LLightRAG, and HLightRAG, all nodes in the graph are directly stored in the vector database. For each node in KG, its embedding vector is generated by encoding its entity name, while for nodes in Tree, TKG, and RKG, the embedding vectors are generated by encoding their associated textual descriptions. In KGP, it stores the TF-IDF matrix [27], which represents the term-weight distribution across different nodes (i.e., chunks) in the index.

$\Theta$  Relationship index stores the relationships of the graph in a vector database, where for each relationship, its embedding vector is generated by encoding a description that combines its associated context (e.g., description) and the names of its linked entities.

$\bullet$  Community index stores the community reports for each community, where communities are generated by the clustering algorithm and the LLM produces the reports. Specifically, Leiden [80] algorithm is utilized by LGraphRAG and GGraphRAG.

Remark. Relationship index tends to have a larger size, whereas the Community index is more compact but incurs the highest construction cost in terms of tokens and time, and provides the detailed comparisons of these indices in our technical report [71].

# 6 RETRIEVAL AND GENERATION

In this section, we explore the key steps in graph-based RAG methods, i.e., selecting operators, and using them to retrieve relevant information to question  $Q$ .

# 6.1 Retrieval operators

In this subsection, we demonstrate that the retrieval stage of various graph-based RAG methods can be abstracted into a modular sequence of operators. Different methods select and compose these operators in distinct ways, enabling flexible and extensible retrieval pipelines. By systematically analyzing existing graph-based RAG implementations, we identify a comprehensive set of 19 retrieval operators, and based on the granularity of retrieval, we classify the operators into five categories. We note that most operators are derived from designs described in the original papers—though often unnamed—so we assign them meaningful and consistent names. For the remaining operators, which are not explicitly defined in the literature, we extract and summarize them based on source code analysis. Importantly, by selecting and arranging these operators in different sequences, all existing (and potentially future) graph-based RAG methods can be implemented.

- Node type. This type of operator focuses on retrieving "important" nodes for a given question, and based on the selection policy, there are seven different operators to retrieve nodes. ① VDB leverages the vector database to retrieve nodes by computing the vector similarity with the query vector. ② RelNode extracts nodes from

the provided relationships. PPR uses the Personalized PageRank (PPR) algorithm [28] to identify the top-  $k$  similar nodes to the question, where the restart probability of each node is based on its similarity to the entities in the given question. Agent utilizes the capabilities of LLMs to select nodes from a list of candidate nodes. One hop selects the one-hop neighbor entities of the given entities. Link selects the top-1 most similar entity for each entity in the given set from the vector database. TF-IDF retrieves the top-  $k$  relevant entities by ranking them based on term frequency and inverse document frequency from the TF-IDF matrix.

- Relationship type. These operators are designed to retrieve relationships from the graph that are most relevant to the user question. There are four operators: 1 VDB, 2 Onehop, 3 Aggregator, and 4 Agent. Specifically, the VDB operator also uses the vector database to retrieve relevant relationships. The Onehop operator selects relationships linked by one-hop neighbors of the given selected entities. The Aggregator operator builds upon the PPR operator in the node operator. Given the PPR scores of entities, the most relevant relationships are determined by leveraging entity-reelationship interactions. Specifically, the score of each relationship is obtained by summing the scores of the two entities it connects. Thus, the top- $k$  relevant relationships can be selected. The key difference for the Agent operator is that, instead of using a candidate entity list, it uses a candidate relationship list, allowing the LLM to select the most relevant relationships based on the question.

- Chunk type. The operators in this type aim to retrieve the most relevant chunks to the given question. There are three operators: 1 Aggregator, 2 FromRel, and 3 Occurrence. Specifically, Aggregator uses the relationship score vector from the Link operator and a relationship–chunk interaction matrix to aggregate chunk scores via matrix multiplication, selecting the top-k chunks with the highest scores. For FromRel: Given a set of relationships, all chunks containing at least one of them are retrieved. The Occurrence selects the top-k chunks based on the given relationships. Specifically, for each relationship, we identify its two associated entities. If both entities appear in the same chunk, the chunk's score is incremented by 1. After processing all relationships, the top-k chunks with the highest scores are selected.

- Subgraph type. There are three operators to retrieve the relevant subgraphs from the graph  $\mathcal{G}$ : The 1 KhopPath operator aims to identify  $k$ -hop paths in  $\mathcal{G}$  by iteratively finding such paths where the start and end points belong to the given entity set. After identifying a path, the entities within it are removed from the entity set, and this process repeats until the entity set is empty. Note that if two paths can be merged, they are combined into one path. For example, if we have two paths  $A \to B \to C$  and  $A \to B \to C \to D$ , we can merge them into a single path  $A \to B \to C \to D$ . The 2 Steiner operator first identifies the relevant entities and relationships, then uses these entities as seed nodes to construct a Steiner tree [27]. The 3 AgentPath operator aims to identify the most relevant  $k$ -hop paths to a given question, by using LLM to filter out the irrelevant paths.

- Community type. Only the LGraphRAG and GGraphRAG using the community operators, which includes two detailed operators, 1 Entity, and 2 Layer. This operator first identifies communities that contain the specified entities, with each community maintaining an associated entity list. It then ranks the selected communities based on relevance scores assigned by the LLM, returning the top- $k$

highest-scoring ones. Each community is associated with a layer attribute, and the Layer operator retrieves all communities at or below the specified layer.

# 6.2 Operator configuration

Under our unified framework, any existing graph-based RAG method can be implemented by leveraging the operator pool along with specific method parameter  $\mathcal{P}$ , as shown in Figure 2. Instead,  $\mathcal{P}$  acts as a control module that configures the retrieval pipeline for a given graph-based RAG method by determining: (1) which atomic operators should be used in the method; and (2) the execution order of these operators within the retrieval process.

In Table 3, we present how the existing graph-based RAG methods utilize our provided operators to assemble their retrieval stages. For example, LlghtRAG first applies the VDB operator to retrieve relevant nodes, then uses the Onehop operator to retrieve relevant relationships, and finally employs the Occurrence operator to obtain the relevant chunks. In the above example, we can set  $\mathcal{P} = \langle$  VDB, Onehop, Occurrence\rangle. Essentially, the parameter  $\mathcal{P}$  represents the retrieval configuration to distinguish the retrieval stage for each specific graph-based RAG method. Due to this independent and modular decomposition of all graph-based RAG methods, we not only gain a deeper understanding of how these approaches work but also gain the flexibility to combine these operators to create new methods. Besides, new operators can be easily created, for example, we can create a new operator VDB within the community type, which allows us to retrieve the most relevant communities by using vector search to compare the semantic similarity between the question and the communities. In our later experimental results (see Exp.5 in Section 7.3), thanks to our modular design, we can design a new state-of-the-art RAG method by first creating two new operators and combining them with the existing operators.

# 6.3 Retrieval & generation

In the Retrieval & generation stage, the graph-based RAG methods first go through a Question conversion stage (see the second subfigure on the right side of Figure 2), which aims to transfer the user input question  $Q$  into the retrieval primitive  $\mathcal{D}$ , where  $\mathcal{D}$  denotes the atomic retrieval unit, such as entities or keywords in  $Q$ , and the embedding vector of  $Q$ .

In the Question conversion stage, DALK, HippoRAG, and ToG extract entities from the question; KGP directly uses the original question as the retrieval primitive. The three versions of LightRAG extract keywords from the question as the retrieval primitive, and the remaining methods use the embedding vector of  $Q$ .

Based on the retrieval primitive  $\mathcal{D}$  and the selected operators, the most relevant information to  $Q$  is retrieved and combined with  $Q$  to form the final prompt for LLM response generation. Generally, there are two types of answer generation paradigms: ① Directly and ② Map-Reduce. The former directly utilizes the LLM to generate the answer. The Map-Reduce strategy in GGraphRAG prompts the LLM to generate partial answers and confidence scores from each retrieved community. These (answer, score) pairs are ranked, and the top ones are appended to form the final prompt for answer generation. An example is shown in [71].


Table 3: Operators utilized in graph-based RAG methods; "N/A" means that this type of operator is not used.


<table><tr><td>Method</td><td>Node</td><td>Relationship</td><td>Chunk</td><td>Subgraph</td><td>Community</td></tr><tr><td>RAPTOR</td><td>VDB</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td></tr><tr><td>KGP</td><td>TF-IDF</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td></tr><tr><td>HippoRAG</td><td>Link + PPR</td><td>Aggregator</td><td>Aggregator</td><td>N/A</td><td>N/A</td></tr><tr><td>G-retriever</td><td>VDB</td><td>VDB</td><td>N/A</td><td>Steiner</td><td>N/A</td></tr><tr><td>ToG</td><td>Link + Onehop + Agent</td><td>Onehop + Agent</td><td>N/A</td><td>N/A</td><td>N/A</td></tr><tr><td>DALK</td><td>Link + Onehop + Agent</td><td>N/A</td><td>N/A</td><td>KhopPath + AgentPath</td><td>N/A</td></tr><tr><td>FastGraphRAG</td><td>Link + VDB + PPR</td><td>Aggregator</td><td>Aggregator</td><td>N/A</td><td>N/A</td></tr><tr><td>LGraphRAG</td><td>VDB</td><td>Onehop</td><td>Occurrence</td><td>N/A</td><td>Entity</td></tr><tr><td>RGraphRAG</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td><td>Layer</td></tr><tr><td>LLightRAG</td><td>VDB</td><td>Onehop</td><td>Occurrence</td><td>N/A</td><td>N/A</td></tr><tr><td>GLightRAG</td><td>FromRel</td><td>VDB</td><td>FromRel</td><td>N/A</td><td>N/A</td></tr><tr><td>HLightRAG</td><td>VDB + FromRel</td><td>Onehop + VDB</td><td>Occurrence + FromRel</td><td>N/A</td><td>N/A</td></tr></table>


Table 4: Datasets used in our experiments; The underlined number of chunks denotes that the dataset is pre-split into chunks by the expert annotator.


<table><tr><td>Dataset</td><td># of Tokens</td><td># of Questions</td><td># ofChunks</td><td>QA Type</td></tr><tr><td>MultihopQA</td><td>1,434,889</td><td>2,556</td><td>609</td><td>Specific QA</td></tr><tr><td>Quality</td><td>1,522,566</td><td>4,609</td><td>265</td><td>Specific QA</td></tr><tr><td>PopQA</td><td>2,630,554</td><td>1,172</td><td>33,595</td><td>Specific QA</td></tr><tr><td>MusiqueQA</td><td>3,280,174</td><td>3,000</td><td>29,898</td><td>Specific QA</td></tr><tr><td>HotpotQA</td><td>8,495,056</td><td>3,702</td><td>66,581</td><td>Specific QA</td></tr><tr><td>ALCE</td><td>13,490,670</td><td>948</td><td>89,562</td><td>Specific QA</td></tr><tr><td>Mix</td><td>611,602</td><td>125</td><td>61</td><td>Abstract QA</td></tr><tr><td>MultihopSum</td><td>1,434,889</td><td>125</td><td>609</td><td>Abstract QA</td></tr><tr><td>Agriculture</td><td>1,949,584</td><td>125</td><td>12</td><td>Abstract QA</td></tr><tr><td>CS</td><td>2,047,923</td><td>125</td><td>10</td><td>Abstract QA</td></tr><tr><td>Legal</td><td>4,774,255</td><td>125</td><td>94</td><td>Abstract QA</td></tr></table>

# 7 EXPERIMENTS

We now present the experimental results. Section 7.1 discusses the setup. We discuss the results for specific QA and abstract QA tasks in Sections 7.2 and 7.3, respectively.

# 7.1 Setup

$\triangleright$  Workflow of our evaluation. We present the first open-source testbed for graph-based RAG methods, which (1) collects and reimplements 12 representative methods within a unified framework (as depicted in Section 3). (2) supports a fine-grained comparison over the building blocks of the retrieval stage with up to  $100+$  variants, and (3) provides a comprehensive evaluation over 11 datasets with various metrics in different scenarios. We summarize the workflow of our empirical study in [71].

Benchmark Dataset. We employ 11 widely used real-world datasets [15, 24, 25, 32] to evaluate the performance of each graph-based RAG method. These datasets span various corpus domains and cover diverse task types.

- Specific. This group focuses on detail-oriented questions referencing specific entities (e.g., "Who won the 2024 U.S. presidential election?"). We divide them into two types based on complexity: Simple (answerable from one or two chunks without reasoning): Quality [65], PopQA [57], Hot-potQA [90]) and Complex (requiring multi-hop reasoning and synthesis): MultihopQA [79], MusiqueQA [81], ALCE [20])

- Abstract. Unlike the previous groups, the questions in this category are not centered on specific factual queries. Instead, they involve abstract, conceptual inquiries that encompass broader topics, summaries, or overarching themes.

An example of an abstract question is: "How does artificial intelligence influence modern education?" The abstract question requires a high-level understanding of the dataset contents, including five datasets: Mix [69], Multi-hopSum [79], Agriculture [69], CS [69], and Legal [69].

Their statistics, including the numbers of tokens, and questions, and the question-answering (QA) types are reported in Table 4. For specific (both complex and simple) QA datasets, we use the questions provided by each dataset. While for abstract QA datasets, We follow the question generation method introduced in [15], using GPT-40 to generate 125 questions per dataset with controlled difficulty, which is also aligned with existing works [15, 19, 24, 67]. The details and prompt template used for question generation are provided in our technical report [71]. Note that MultihopQA and MultihopSum originate from the same source, but differ in the types of questions they include—the former focuses on complex QA tasks, while the latter on abstract QA tasks.

$\triangleright$  Evaluation Metric. For the specific QA tasks, we use Accuracy and Recall to evaluate performance on the first five datasets based on whether gold answers are included in the generations instead of strictly requiring exact matching, following [57, 73]. For the ALCE dataset, answers are typically full sentences rather than specific options or words. Following existing works [20, 72], we use string recall (STRREC), string exact matching (STREM), and string hit (STRHIT) as evaluation metrics. For abstract QA tasks, we adopt four evaluation metrics following prior works [15, 24]: Comprehensiveness, Diversity, Empowerment, and Overall, which assess answer quality from different perspectives. We employ a head-to-head comparison strategy using GPT-4o as the evaluator. Specifically, for each pair of answers, the LLM is prompted to judge which one is better with respect to a given metric, rather than assigning explicit scores. This comparative approach is motivated by the strong performance of LLMs as evaluators of natural language generation, often matching or exceeding human judgments [82, 95]. We provide detailed descriptions of the evaluation protocol and example case studies for all four metrics in our technical report [71].

$\triangleright$  Implementation. We implement all the algorithms in Python with our proposed unified framework and try our best to ensure a native and effective implementation. All experiments are run on 350 Ascend 910B-3 NPUs [34]. Besides, Zeroshot [5], and vanilla RAG (denoted by VanillaRAG) [42] are also included in our study, which typically represent the model's inherent capability and the performance improvement brought by basic RAG, respectively. If a


Table 5: Comparison of methods on different datasets, where Purple denotes the best result, and Orange denotes the best result excluding the best one; For the three largest datasets, we replace the clustering method in RAPTOR from Gaussian Mixture to K-means, as the former fails to finish within two days; The results of this version (i.e., K-means) are marked with  $\dagger$ .


<table><tr><td rowspan="2">Method</td><td colspan="2">MultihopQA</td><td>Quality</td><td colspan="2">PopQA</td><td colspan="2">MusiqueQA</td><td colspan="2">HotpotQA</td><td colspan="3">ALCE</td></tr><tr><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Recall</td><td>STRREC</td><td>STREM</td><td>STRHIT</td></tr><tr><td>ZeroShot</td><td>49.022</td><td>34.256</td><td>37.058</td><td>28.592</td><td>8.263</td><td>1.833</td><td>5.072</td><td>35.467</td><td>42.407</td><td>15.454</td><td>3.692</td><td>30.696</td></tr><tr><td>VanillaRAG</td><td>50.626</td><td>36.918</td><td>39.141</td><td>60.829</td><td>27.058</td><td>17.233</td><td>27.874</td><td>50.783</td><td>57.745</td><td>34.283</td><td>11.181</td><td>63.608</td></tr><tr><td>G-retriever</td><td>42.019</td><td>43.116</td><td>31.807</td><td>17.084</td><td>6.075</td><td>2.733</td><td>11.662</td><td>-</td><td>-</td><td>9.754</td><td>2.215</td><td>19.726</td></tr><tr><td>ToG</td><td>41.941</td><td>38.435</td><td>34.888</td><td>47.677</td><td>23.727</td><td>9.367</td><td>20.536</td><td>-</td><td>-</td><td>13.975</td><td>3.059</td><td>29.114</td></tr><tr><td>KGP</td><td>48.161</td><td>36.272</td><td>33.955</td><td>57.255</td><td>24.635</td><td>17.333</td><td>27.572</td><td>-</td><td>-</td><td>27.692</td><td>8.755</td><td>51.899</td></tr><tr><td>DALK</td><td>53.952</td><td>47.232</td><td>34.251</td><td>45.604</td><td>19.159</td><td>11.367</td><td>22.484</td><td>33.252</td><td>47.232</td><td>21.408</td><td>4.114</td><td>44.937</td></tr><tr><td>LLightRAG</td><td>44.053</td><td>35.528</td><td>34.780</td><td>38.885</td><td>16.764</td><td>9.667</td><td>19.810</td><td>34.144</td><td>41.811</td><td>21.937</td><td>5.591</td><td>43.776</td></tr><tr><td>GLightRAG</td><td>48.474</td><td>38.365</td><td>33.413</td><td>20.944</td><td>8.146</td><td>7.267</td><td>17.204</td><td>25.581</td><td>33.297</td><td>17.859</td><td>3.587</td><td>37.131</td></tr><tr><td>HLightRAG</td><td>50.313</td><td>41.613</td><td>34.368</td><td>41.244</td><td>18.071</td><td>11.000</td><td>21.143</td><td>35.647</td><td>43.334</td><td>25.578</td><td>6.540</td><td>50.422</td></tr><tr><td>FastGraphRAG</td><td>52.895</td><td>44.278</td><td>37.275</td><td>53.324</td><td>22.433</td><td>13.633</td><td>24.470</td><td>43.193</td><td>51.007</td><td>30.190</td><td>8.544</td><td>56.962</td></tr><tr><td>HippoRAG</td><td>53.760</td><td>47.671</td><td>48.297</td><td>59.900</td><td>24.946</td><td>17.000</td><td>28.117</td><td>50.324</td><td>58.860</td><td>23.357</td><td>6.962</td><td>43.671</td></tr><tr><td>LGraphRAG</td><td>55.360</td><td>50.429</td><td>37.036</td><td>45.461</td><td>18.657</td><td>12.467</td><td>23.996</td><td>33.063</td><td>42.691</td><td>28.448</td><td>8.544</td><td>54.747</td></tr><tr><td>RAPTOR</td><td>56.064</td><td>44.832</td><td>56.997</td><td>62.545</td><td>27.304</td><td>\( 24.133^{\dagger} \)</td><td>\( 35.595^{\dagger} \)</td><td>\( 55.321^{\dagger} \)</td><td>\( 62.424^{\dagger} \)</td><td>\( 35.255^{\dagger} \)</td><td>\( 11.076^{\dagger} \)</td><td>\( 65.401^{\dagger} \)</td></tr></table>

method cannot finish in two days, we mark its result as  $\mathbf{N} / \mathbf{A}$  in the figures and “-” in the tables.

Hyperparameter Settings. In our experiments, we use Llama-3-8B [14] as the default LLM, not only because it is the most widely adopted model in recent RAG studies [93], but also due to its strong capabilities in language understanding and reasoning [14], as well as its practical efficiency for deployment. For LLM, we set the maximum token length to 8,096, and use greedy decoding to generate one sample for the deterministic output. For each method requiring top- $k$  selection (e.g., chunks or entities), we set  $k = 4$  to accommodate the token length limitation. We use one of the most advanced text-encoding models, BGE-M3 [58], as the embedding model across all methods to generate embeddings for vector search. If an expert annotator pre-splits the dataset into chunks, we use those as they preserve human insight. Otherwise, following existing works [15, 24], we divide the corpus into 1,200-token chunks. For other hyperparameters of each method, we adopt the original code settings when available; otherwise, we reproduce them based on the configurations described in the corresponding papers.

# 7.2 Evaluation for specific QA

In this section, we evaluate the performance of different methods on specific QA tasks.

$\triangleright$  Exp.1. Overall performance. We report the metric values of all algorithms on specific QA tasks in Table 5. We can make the following observations and analyses: (1) Generally, the RAG technique significantly enhances LLM performance across all datasets, and the graph-based RAG methods (e.g., HippoRAG and RAPTOR) typically exhibit higher accuracy than Vani11aRAG. However, if the retrieved elements are not relevant to the given question, RAG may degrade the LLM's accuracy. For example, on the Quality dataset, compared to Zeroshot, RAPTOR improves accuracy by  $53.80\%$  while G-retriever decreases it by  $14.17\%$ . This is mainly because, for simple QA tasks, providing only entities and relationships from a subgraph is insufficient to answer such questions effectively.

(2) For specific QA tasks, retaining the original text chunks is crucial for accurate question answering, as the questions and answers in these datasets are derived from the text corpus. This may explain

why G-retriever, ToG, and DALK, which rely solely on graph structure information, perform poorly on most datasets. However, on MultihopQA, which requires multi-hop reasoning, DALK effectively retrieves relevant reasoning paths, achieving accuracy and recall improvements of  $6.57\%$  and  $27.94\%$  over VanillaRAG, respectively.

(3) If the dataset is pre-split into chunks by the expert annotator, VanillaRAG often performs better compared to datasets where chunks are split based on the token size, and we further investigate this phenomenon later in our technical report [71].

(4) RAPTOR often achieves the best performance among most datasets, especially for simple questions. For complex questions, RAPTOR also performs exceptionally well. This is mainly because, for such questions, high-level summarized information is crucial for understanding the underlying relationships across multiple chunks. Hence, as we shall see, LGraphRAG is expected to achieve similar results, as it also incorporates high-level information (i.e., a summarized report of the most relevant community for a given question). However, we only observe this effect on the MultihopQA dataset. For the other two complex QA datasets, LGraphRAG even underperforms compared to Vani11LaRAG. Meanwhile, RAPTOR still achieves the best performance on these two datasets. We hypothesize that this discrepancy arises from differences in how high-level information is retrieved (See Table 3).

(5) For the three largest datasets, the K-means [27]-based RAPTOR (denoted as RAPTOR-K) also demonstrates remarkable performance. This suggests that the clustering method used in RAPTOR merely impacts overall performance. This may be because different clustering methods share the same key idea: grouping similar items into the same cluster. Therefore, they may generate similar chunk clusters. We note that RAPTOR-K achieves comparable or even better performance than RAPTOR, and the detailed results are shown in technical report [71]. If RAPTOR does not finish constructing the graph within two days, we use RAPTOR-K instead.

Remark. We note that not all graph-based RAG methods consistently outperform the baseline VaniillaRAG on every question. By carefully analyzing the failure case of the top-performing methods, we examine why HippoRAG, RAPTOR, and LGraphRAG sometimes fall short in specific QA tasks. In short, the main failure reasons are: incorrect or incomplete entity extraction and irrelevant chunk

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/eafbe5d1a76a3866ccb48bb19993ed1ae3c443cafa8600274ad919ac7b6d9f57.jpg)



(a) MultihopQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/df70ec034e0b25f2c96e19e6f38372414a93923c36f4effdf4d7799a35770566.jpg)



(b) Quality


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/cf41210ef82427e9c71323112c9caa9c5b05986e70188a2489b857f2ede502b3.jpg)



(c) PopQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/bbfe2797ef3bce9ea55fe048f923fc280c1524b04ae0ec32f842907bb6ba10b0.jpg)



(d) MusiqueQA



Figure 4: Token cost of graph building on specific QA datasets.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d9d2c93b812f35700d0b02fff4dd5e4a9268afe346f8b16bfb34666afc142760.jpg)



Figure 5: Token cost of index construction on specific QA. retrieval via Personalized PageRank for HippoRAG; low-quality cluster summaries for RAPTOR; and irrelevant community reports (via the Entity operator) and unrelated chunks (via the Occurrence operator) for LGraphRAG. Please see the failure cases in [71].


$\triangleright$  Exp.2. Token costs of graph and index building. In this experiment, we first report the token costs of building four types of graphs across all datasets. Notably, building PG incurs no token cost, as it does not rely on the LLM for graph construction. We only report the results on four datasets here, and leave the remaining results in our technical report [71]. As shown in Figure 4(a) to (d), we observe the following: (1) Building trees consistently requires the least token cost, while TKG and RKG incur the highest token costs, with RKG slightly exceeding TKG. In some cases, RKG requires up to  $40 \times$  more tokens than trees. (2) KG falls between these extremes, requiring more tokens than trees but fewer than TKG and RKG. This trend aligns with the results in Table 2, where graphs with more attributes require higher token costs for construction. (3) Recall that the token cost for an LLM call consists of two parts: the prompt token, which accounts for the tokens used in providing the input, and the completion part, which includes the tokens generated by the model as a response. We can see that regardless of the graph type, the prompt part always incurs higher token costs than the completion part; the detailed results are shown in [71].

We then examine the token costs of index building across all datasets. Since only LGraphRAG and GGraphRAG require an LLM for index construction, we report only the token costs for generating community reports in Figure 5. We can see that the token cost for index construction is nearly the same as that for building TKG. This is mainly because it requires generating a report for each community, and the number of communities is typically large, especially in large datasets. For example, the HotpotQA dataset contains 57,384 communities, significantly increasing the overall token consumption. That is to say, on large datasets, the two versions of GraphRAG often take more tokens than other methods in the offline stage.

$\triangleright$  Exp.3. Evaluation of the generation costs. In this experiment, we evaluate the time and token costs for each method in specific QA tasks. Specifically, we report the average time and token costs for each query across all datasets in Table 6. We only report the results on three datasets here, and leave the remaining results in [71]. It is not surprising that ZeroShot and Vani11aRAG are the most cost-efficient methods in terms of both time and token consumption. In terms of token cost, RAPTOR and HippoRAG are generally more efficient than other graph-based RAG methods, as


Table 6: Time and token costs of all methods on specific QA.


<table><tr><td rowspan="2">Method</td><td colspan="2">MultihopQA</td><td colspan="2">PopQA</td><td colspan="2">ALCE</td></tr><tr><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td></tr><tr><td>ZeroShot</td><td>3.23 s</td><td>270.3</td><td>1.17 s</td><td>82.2</td><td>2.41 s</td><td>177.2</td></tr><tr><td>VanillaRAG</td><td>2.35 s</td><td>3,623.4</td><td>1.41 s</td><td>644.1</td><td>1.04 s</td><td>849.1</td></tr><tr><td>G-retriever</td><td>6.87 s</td><td>1,250.0</td><td>37.51 s</td><td>3,684.5</td><td>101.16 s</td><td>5,096.1</td></tr><tr><td>ToG</td><td>69.74 s</td><td>16,859.6</td><td>42.02 s</td><td>11,224.2</td><td>34.94 s</td><td>11,383.2</td></tr><tr><td>KGP</td><td>38.86 s</td><td>13,872.2</td><td>37.49 s</td><td>6,738.9</td><td>105.09 s</td><td>9,326.6</td></tr><tr><td>DALK</td><td>28.03 s</td><td>4,691.5</td><td>16.33 s</td><td>2,496.5</td><td>17.04 s</td><td>4,071.9</td></tr><tr><td>LLightRAG</td><td>19.28 s</td><td>5,774.1</td><td>10.71 s</td><td>2,447.5</td><td>10.34 s</td><td>4,427.9</td></tr><tr><td>GLightRAG</td><td>18.37 s</td><td>5,951.5</td><td>12.10 s</td><td>3,255.6</td><td>13.02 s</td><td>4,028.1</td></tr><tr><td>HLightRAG</td><td>19.31 s</td><td>7,163.2</td><td>17.71 s</td><td>5,075.8</td><td>16.55 s</td><td>6,232.3</td></tr><tr><td>FastGraphRAG</td><td>7.17 s</td><td>5,874.8</td><td>13.25 s</td><td>6,157.0</td><td>25.82 s</td><td>6,010.9</td></tr><tr><td>HippoRAG</td><td>3.46 s</td><td>3,261.1</td><td>2.32 s</td><td>721.3</td><td>2.94 s</td><td>858.2</td></tr><tr><td>LGraphRAG</td><td>2.98 s</td><td>6,154.9</td><td>1.72 s</td><td>4,325.2</td><td>2.11 s</td><td>5,441.1</td></tr><tr><td>RAPTOR</td><td>3.18 s</td><td>3,210.0</td><td>1.36 s</td><td>1,188.3</td><td>1.54 s</td><td>793.6</td></tr></table>

they share a similar retrieval stage with VanillaRAG. The main difference lies in the chunk retrieval operators they use. Besides, KGP and ToG are the most expensive methods, as they rely on the agents (i.e., different roles of the LLM) for information retrieval during prompt construction. The former utilizes the LLM to reason the next required information based on the original question and retrieved chunks, while the latter employs LLM to select relevant entities and relationships for answering the question. On the other hand, the costs of LlightRAG, GLightRAG, and HLightRAG gradually increase, aligning with the fact that more information is incorporated into the prompt construction. All three methods are more expensive than LGraphRAG in specific QA tasks, as they use LLM to extract keywords in advance. Moreover, the time cost of all methods is proportional to the completion token cost. We present the results in our technical report [71], which explains why in some datasets, VanillaRAG is even faster than ZeroShot.

$\triangleright$  Exp.4. Detailed analysis for RAPTOR and LGraphRAG. Due to space limitations, we highlight only the key insights derived from our analysis of RAPTOR and LGraphRAG. First, RAPTOR reveals that a significantly higher proportion of retrieved high-level information (i.e., content from non-leaf nodes) appears in complex QA tasks compared to simple ones, suggesting that high-level information is crucial for multi-hop reasoning. Second, we find that community reports serve as more effective high-level information than the chunk summaries used in RAPTOR, and the similarity-driven community retrieval strategy proves more robust than the Entity operator employed in LGraphRAG. Finally, for multi-hop reasoning tasks like MultihopQA, entity and relationship information provides valuable auxiliary signals that help the LLM connect relevant facts and guide the reasoning process. The detailed analysis and respective experiment results are shown in [71].

$\triangleright$ Exp.5. Effect of chunk size. We evaluate the impact of chunk size on all RAG methods for specific QA by splitting the corpus into chunks of 600, 1200, and 2400 tokens. To this end, we construct three new datasets—PopAll, HotpotAll, and ALCEAll—by re-chunking the full corpora of PopQA, HotpotQA, and ALCE based on token


Table 7: Comparison of methods on different datasets under different chunk sizes.


<table><tr><td rowspan="2">Method</td><td rowspan="2">Chunk Size</td><td colspan="2">MultihopQA</td><td colspan="2">PopAll</td><td colspan="2">HotpotAll</td><td colspan="3">ALCEAll</td></tr><tr><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Recall</td><td>STRREC</td><td>STREM</td><td>STRHIT</td></tr><tr><td rowspan="3">VanillaRAG</td><td>600</td><td>54.421</td><td>42.740</td><td>57.255</td><td>24.171</td><td>49.190</td><td>56.935</td><td>30.174</td><td>8.333</td><td>57.911</td></tr><tr><td>1,200</td><td>50.626</td><td>36.918</td><td>57.041</td><td>25.877</td><td>44.254</td><td>52.511</td><td>29.334</td><td>8.228</td><td>56.329</td></tr><tr><td>2,400</td><td>50.665</td><td>37.172</td><td>47.677</td><td>19.122</td><td>27.553</td><td>34.293</td><td>26.350</td><td>7.490</td><td>51.371</td></tr><tr><td rowspan="3">DALK</td><td>600</td><td>55.986</td><td>48.202</td><td>41.243</td><td>16.131</td><td>32.766</td><td>41.737</td><td>21.734</td><td>4.536</td><td>44.304</td></tr><tr><td>1,200</td><td>53.952</td><td>47.232</td><td>42.602</td><td>17.024</td><td>30.416</td><td>39.544</td><td>21.327</td><td>4.430</td><td>43.987</td></tr><tr><td>2,400</td><td>53.208</td><td>46.829</td><td>45.318</td><td>18.651</td><td>28.633</td><td>37.826</td><td>20.350</td><td>4.430</td><td>41.456</td></tr><tr><td rowspan="3">HippoRAG</td><td>600</td><td>47.144</td><td>41.210</td><td>62.401</td><td>26.892</td><td>50.783</td><td>58.454</td><td>27.025</td><td>8.122</td><td>51.477</td></tr><tr><td>1,200</td><td>53.760</td><td>47.671</td><td>60.472</td><td>25.041</td><td>55.267</td><td>62.862</td><td>21.633</td><td>5.696</td><td>41.561</td></tr><tr><td>2,400</td><td>52.152</td><td>46.601</td><td>50.751</td><td>19.986</td><td>45.624</td><td>53.597</td><td>26.477</td><td>6.118</td><td>52.848</td></tr><tr><td rowspan="3">LGraphRAG</td><td>600</td><td>55.282</td><td>46.267</td><td>53.181</td><td>26.292</td><td>41.194</td><td>49.801</td><td>33.692</td><td>10.971</td><td>62.447</td></tr><tr><td>1,200</td><td>55.360</td><td>50.429</td><td>39.814</td><td>17.998</td><td>30.686</td><td>38.824</td><td>27.785</td><td>8.017</td><td>52.954</td></tr><tr><td>2,400</td><td>54.930</td><td>44.588</td><td>43.317</td><td>20.185</td><td>37.061</td><td>45.366</td><td>28.398</td><td>7.806</td><td>54.008</td></tr><tr><td rowspan="3">RAPTOR</td><td>600</td><td>56.729</td><td>46.358</td><td>61.830</td><td>28.176</td><td>56.132</td><td>63.584</td><td>35.111</td><td>12.236</td><td>63.186</td></tr><tr><td>1,200</td><td>56.064</td><td>44.832</td><td>47.963</td><td>21.399</td><td>31.983</td><td>39.864</td><td>34.044</td><td>10.971</td><td>62.342</td></tr><tr><td>2,400</td><td>56.299</td><td>44.610</td><td>48.177</td><td>21.289</td><td>31.983</td><td>39.122</td><td>33.432</td><td>10.654</td><td>61.181</td></tr></table>


Table 8: Comparison of our newly designed methods on specific datasets with complex questions.


<table><tr><td>Dataset</td><td>Metric</td><td>LGraphRAG</td><td>RAPTOR</td><td>VGraphRAG</td></tr><tr><td rowspan="2">MultihopQA</td><td>Accuracy</td><td>55.360</td><td>56.064</td><td>59.664</td></tr><tr><td>Recall</td><td>50.429</td><td>44.832</td><td>50.893</td></tr><tr><td rowspan="2">MusiqueQA</td><td>Accuracy</td><td>12.467</td><td>24.133</td><td>26.933</td></tr><tr><td>Recall</td><td>23.996</td><td>35.595</td><td>40.026</td></tr><tr><td rowspan="3">ALCE</td><td>STRREC</td><td>28.448</td><td>35.255</td><td>41.023</td></tr><tr><td>STREM</td><td>8.544</td><td>11.076</td><td>15.401</td></tr><tr><td>STRHIT</td><td>54.747</td><td>65.401</td><td>71.835</td></tr></table>

length. This re-chunking is necessary because these datasets are pre-split by expert annotators, which may not accurately reflect the effects of chunk sizes. We only report the results of five methods in Table 7, and present the remaining results in [71]. We can see that: (1) For simple QA datasets (e.g., PopAll and HotpotAll), smaller chunk sizes generally yield better performance. This is because such questions often require information that is directly available in a single chunk or two. Smaller chunks provide more focused and precise context, improving answer accuracy. (2) We note that performance on simple QA tasks is highly sensitive to chunk size, while for complex QA tasks, performance remains relatively stable across different chunk sizes. This is because complex questions typically require reasoning across multiple chunks, making them less dependent on individual chunk granularity.

$\triangleright$  Exp.6. New SOTA algorithm. Based on the above analysis, we aim to develop a new state-of-the-art method for complex QA datasets, denoted as VGraphRAG. Specifically, our algorithm first retrieves the top-  $k$  entities and their corresponding relationships, this step is the same as LGraphRAG. Next, we adopt the vector search-based retrieval strategy to select the most relevant communities and chunks. Then, by combining the four elements above, we construct the final prompt of our method to effectively guide the LLM in generating accurate answers. The results are also shown in Table 8, we can see that VGraphRAG performs best on all complex QA datasets. For example, compared to RAPTOR, our new algorithm VGraphRAG improves Accuracy by  $6.42\%$  on the MultihopQA dataset and  $11.6\%$  on the MusiqueQA dataset, respectively.


Table 9: Effect of LLM backbones for specific QA task.


<table><tr><td rowspan="2">Method</td><td rowspan="2">LLM backbone</td><td colspan="2">MultihopQA</td><td colspan="3">ALCEAll</td></tr><tr><td>Accuracy</td><td>Recall</td><td>STRREC</td><td>STREM</td><td>STRHIT</td></tr><tr><td rowspan="4">ZeroShot</td><td>Llama-3-8B</td><td>49.022</td><td>34.256</td><td>15.454</td><td>3.692</td><td>30.696</td></tr><tr><td>Qwen-2.5-32B</td><td>45.070</td><td>33.332</td><td>30.512</td><td>10.127</td><td>56.118</td></tr><tr><td>Llama-3-70B</td><td>55.908</td><td>52.987</td><td>31.234</td><td>7.170</td><td>61.920</td></tr><tr><td>GPT-4o-mini</td><td>59.546</td><td>48.322</td><td>34.965</td><td>10.232</td><td>66.245</td></tr><tr><td rowspan="4">VanillaRAG</td><td>Llama-3-8B</td><td>50.626</td><td>36.918</td><td>29.334</td><td>8.228</td><td>56.329</td></tr><tr><td>Qwen-2.5-32B</td><td>56.299</td><td>47.660</td><td>39.490</td><td>14.873</td><td>69.937</td></tr><tr><td>Llama-3-70B</td><td>56.768</td><td>49.127</td><td>34.961</td><td>9.810</td><td>68.038</td></tr><tr><td>GPT-4o-mini</td><td>59.311</td><td>47.941</td><td>35.735</td><td>10.127</td><td>68.249</td></tr><tr><td rowspan="4">HLightRAG</td><td>Llama-3-8B</td><td>50.313</td><td>41.613</td><td>22.475</td><td>6.329</td><td>43.776</td></tr><tr><td>Qwen-2.5-32B</td><td>53.678</td><td>51.403</td><td>34.168</td><td>10.971</td><td>63.819</td></tr><tr><td>Llama-3-70B</td><td>57.081</td><td>54.510</td><td>29.548</td><td>8.228</td><td>57.911</td></tr><tr><td>GPT-4o-mini</td><td>55.829</td><td>46.424</td><td>41.334</td><td>15.506</td><td>71.730</td></tr><tr><td rowspan="4">HippoRAG</td><td>Llama-3-8B</td><td>53.760</td><td>47.671</td><td>21.633</td><td>5.696</td><td>41.561</td></tr><tr><td>Qwen-2.5-32B</td><td>48.083</td><td>40.488</td><td>37.419</td><td>13.397</td><td>66.245</td></tr><tr><td>Llama-3-70B</td><td>57.277</td><td>57.736</td><td>32.904</td><td>9.916</td><td>32.534</td></tr><tr><td>GPT-4o-mini</td><td>67.723</td><td>55.482</td><td>39.274</td><td>12.447</td><td>72.046</td></tr><tr><td rowspan="4">RAPTOR</td><td>Llama-3-8B</td><td>56.064</td><td>44.832</td><td>34.044</td><td>10.971</td><td>62.342</td></tr><tr><td>Qwen-2.5-32B</td><td>60.485</td><td>56.359</td><td>39.267</td><td>13.924</td><td>70.359</td></tr><tr><td>Llama-3-70B</td><td>63.028</td><td>61.042</td><td>37.286</td><td>12.236</td><td>68.671</td></tr><tr><td>GPT-4o-mini</td><td>60.603</td><td>51.521</td><td>29.770</td><td>8.017</td><td>58.861</td></tr><tr><td rowspan="4">VGraphRAG</td><td>Llama-3-8B</td><td>59.664</td><td>50.893</td><td>35.213</td><td>11.603</td><td>64.030</td></tr><tr><td>Qwen-2.5-32B</td><td>57.277</td><td>55.151</td><td>39.234</td><td>14.557</td><td>69.831</td></tr><tr><td>Llama-3-70B</td><td>67.567</td><td>68.445</td><td>37.576</td><td>12.447</td><td>69.198</td></tr><tr><td>GPT-4o-mini</td><td>68.193</td><td>56.564</td><td>43.963</td><td>18.038</td><td>74.473</td></tr></table>

$\triangleright$  Exp.7. Effect of LLM backbone. We evaluate the impact of different LLM backbones—Llama-3-8B [14], Qwen-2.5-32B [88], Llama-3-70B [14], and GPT-4o-mini—on the MultihopQA and ALCEAll datasets. The main results are shown in Table 9, while the remaining parts are presented in [71]. We make the following observations: (1) Stronger models generally yield better performance, especially in the Zeroshot setting, which most directly reflects the inherent capabilities of the underlying LLM. (2) The three variants of LightRAG, LLightRAG, GLightRAG, and HLightRAG as well as LGraphRAG, achieve significant performance improvements when using more powerful LLMs. This can be attributed to their reliance on Rich Knowledge Graphs and Textual Knowledge Graphs, where stronger LLMs contribute to the construction of higher-quality graphs. (3) HippoRAG shows notably superior performance when using GPT-4o-mini compared to other LLM backbones. We attribute this to GPT-4o-mini's ability to extract more accurate entities from the question and to construct higher-quality knowledge graphs,

thereby improving the retrieval of relevant chunks and the final answer accuracy. (4) Regardless of the LLM backbone, our proposed method VGraphRAG consistently achieves the best performance, demonstrating the advantages of our proposed unified framework.

# 7.3 Evaluation for abstract QA

In this section, we evaluate the performance of different methods on abstract QA tasks.

$\triangleright$  Exp.1. Overall Performance. We evaluate the performance of methods that support abstract QA (see Table 1) by presenting head-to-head win rate percentages, comparing the performance of each row method against each column method. Here, we denote VR, RA, GS, LR, and FG as VanillarAG, RAPTOR, GGraphRAG with high-layer communities (i.e., two-layer for this original implementation), HLightRAG and FastGraphRAG, respectively. The results are shown in Figure 6 to Figure 10, and we can see that: (1) Graph-based RAG methods often outperform VanillarAG, primarily because they effectively capture inter-connections among chunks. (2) Across all four metrics, GGraphRAG stands out across all metrics. It achieves the highest Comprehensiveness by leveraging community-level retrieval to reduce fragmented evidence and capture broader context. For Diversity, both RAPTOR and GGraphRAG perform well by aggregating content across clusters or communities, covering a wide range of subtopics. On Empowerment, GGraphRAG and LightRAG lead by integrating structured elements such as entities and relations, helping the LLM generate more grounded and actionable answers. Overall, GGraphRAG consistently ranks first, with RAPTOR typically second, demonstrating the value of high-level summaries and the effectiveness of Map-Reduce.

$\triangleright$  Exp.2. Evaluation of the generation costs. In this experiment, we present the time and token costs for each method in abstract QA tasks. As shown in Table 10, GGraphRAG is the most expensive method, as expected, while other graph-based methods exhibit comparable costs, although they are more expensive than Vani11aRAG. For example, on the MutihopSum dataset, GGraphRAG requires  $57 \times$  more time and  $210 \times$  more tokens per query compared to Vani11aRAG. Specifically, each query in GGraphRAG takes around 9 minutes and consumes 300K tokens, making it impractical for real-world scenarios. This is because, to answer an abstract question, GGraphRAG needs to analyze all retrieved communities, which is highly time- and token-consuming, especially when the number of communities is large (e.g., in the thousands).

$\triangleright$  Exp.3. New SOTA algorithm. While the GGraphRAG shows remarkable performance in abstract QA, its time and token costs are not acceptable in practice, since given a question  $Q$ , GGraphRAG needs to use LLM to analyze all communities via Map-Reduce. (See Section 6.3) To alleviate this issue, we propose a cost-efficient variant of GGraphRAG, named CheapRAG. Instead of applying the LLM to analyze all communities, CheapRAG first computes the vector similarity between each community and the query to filter out irrelevant ones. It then applies the LLM only to the most relevant communities, significantly reducing token costs compared to GGraphRAG. Moreover, we observe that many top-performing methods, such as RAPTOR, HlightRAG, and GGraphRAG, all leverage the original chunks. This suggests that original chunks remain useful for certain questions. Hence, CheapRAG also incorporates original chunks into its retrieval process. After retrieving the top- $k$  most relevant

communities and chunks, CheapRAG adopts a Map-Reduce strategy: the LLM generates partial answers for each selected community and chunk independently, and then summarizes them into a final response. As shown in Figure 11 and Table 10, CheapRAG not only achieves better performance than GGraphRAG but also significantly reduces token costs (in most cases). For example, on the Multihop-Sum dataset, CheapRAG reduces token costs by  $100 \times$  compared to GGraphRAG, while achieving better answer quality. We leave improving the answer diversity of CheapRAG to future work.

$\triangleright$  Exp.4. Effect of chunk size and LLM backbone. We also study the impact of chunk size and LLM backbone on abstract QA tasks, following the same experimental setup as in Section 7.2. Due to space limitations, we report the results based on the "Overall" metric in Figure 12, with additional details provided in [71]. Our key observations are as follows: (1) The performance of GGraphRAG remains stable across different chunk sizes, likely due to its use of the Map-Reduce strategy for final answer synthesis, which mitigates the influence of chunk granularity. (2) In contrast, methods like FastGraphRAG and VanillaRAG show greater variance across chunk sizes, as their performance relies heavily on the granularity of individual chunks—smaller chunks tend to provide more precise information, directly impacting retrieval and generation quality. (3) Regardless of chunk size, RAPTOR and GGraphRAG consistently achieve the best performance, reaffirming our earlier conclusion that high-level structural information is essential for abstract QA tasks. (4) All methods still lag behind GGraphRAG, further highlighting that community-level information is particularly beneficial for abstract QA tasks. In addition, we evaluate our newly proposed method CheapRAG against the baselines under varying chunk sizes and LLM backbones. As shown in [71], CheapRAG consistently achieves the best performance across all settings.

# 8 LESSONS AND OPPORTUNITIES

We summarize the lessons (L) for practitioners and propose practical research opportunities (O) based on our observations.

# Lessons:

$\triangleright$  L1. In Figure 13, we depict a roadmap of the recommended RAG methods, highlighting which methods are best suited for different scenarios. It is derived from all conducted experiments, which is an overall conclusion for both graph-based RAG methods.

$\triangleright$  L2. Chunk quality is critical to the overall performance of RAG methods, and human experts typically produce more effective chunking than approaches based solely on token length.(See results in Table 7 and Figure 12.)

$\triangleright$  L3. For complex questions in specific QA, high-level information is typically needed, as they capture the complex relationship among chunks, and the vector search-based retrieval strategy is better than the rule-based (e.g., Entity operator) one. This lesson is supported by the results in Tables 5 and 8.

$\triangleright$  L4. Community reports provide a more effective high-level structure than summarized chunk clusters for abstract QA tasks, as they better capture diversified topics and overarching themes within local modules of the corpus. (See is results in Figures  $6 \sim 12$ ).

$\triangleright$  L5. Original chunks are useful for all QA tasks, as they provide essential textual descriptions for augmenting or completing information needed to answer questions. When attempting to design new graph-based RAG methods, incorporating the relevant original

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/9377d2dedbf4e715815379f9243984a7ca77678e009690504d3c7c712e95adb8.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/53409b9671273aaa17bddfc695bff275cfa9c8323e7e2f1b3fc549fcdeeb319e.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d74c0de4135a3a7609438e7e22f3799c465ad9d6abcfbef8f8f21548cb780620.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/c9f5707807650b306575d8542577cbff860cf049486a033eab31296edc888f88.jpg)



(d) Overall



Figure 6: The abstract QA results on Mix dataset.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/550414f7256e56b9f3f6edee617218a018167b811628fdc6789d7a2f472373cf.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/1f41ad88aa495e315aa361ebc3df81adca49511ac3d5262d8879982f1e1e00ef.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/37db6e2a14409d44fd40f528c8e4ad2ec1d79cae94abdb5102eff51d81880678.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/5d2170f7c2491e2d77c4150bf9a618872e762a3daf010ebec18e73252f8b937f.jpg)



(d) Overall



Figure 7: The abstract QA results on MultihopSum dataset.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/85dd3c88578ca834f20ed37aa75004933fff442e90dfaa8c25bf267161bc8390.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/80f03fd880a2b05744585d4c840dcd2bd36855ab8ec715cd54939ec515bfce1a.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/c14f8e8c3d4ff57da82a1a17c972a2790bb2be964f3501a3d99039ee490b1036.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/2d0966958a71807a50d73f555a0b146205956e8e71dc25b49411a2894130f4f1.jpg)



(d) Overall



Figure 8: The abstract QA results on Agriculture dataset.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/e5748e378934480f282be8d9b8e7d8e25d9f637148f9dae61364b7adbf6973c9.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/79d880087bfaca0f76bb0b8819a2fcd56580701c049d9693c11d61db287edf52.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d64787637b320bb4f2fef9b69d9138c48ce25c4635cba6def57f3d42a27319d7.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/0adcca55a658516928c7c4b41cb285c33413a1fe07150b736b3ebdc71fae6125.jpg)



(d) Overall



Figure 9: The abstract QA results on CS dataset.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/c7cde89ea0a1e9f0045f0fe0516b7749087431b9813503b648b506aadda91a07.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/68c5f07593fe6ddf9b8dd248e0f850ded4959ffbcc2642111318d2ae4d688caa.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d2cc9b1b9edbfc6a85c4b2ae0caa5638e073f643cf66b0fd1402f3ca59320611.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/77021ec8bfe114675d73c4852a85d5f4916ae5c6302b944eb5470f6532794f77.jpg)



(d) Overall



Figure 10: The abstract QA results on Legal dataset.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/7c55227b455fefc823c099aa8ef4d1765fa7179b221e8e6fd397de045ab8a99d.jpg)



(a) Mix


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/4a785fde9572fef3904133884c02d7c99d15f725802ed1585eeaf510fce8bff5.jpg)



(b) MultihopSum


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/3d41585defa036ad852c93ac41d05a89aee205ddc0ef69c16f91a487f26abc5d.jpg)



(c) Agriculture


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/5e1fec2190b5349fdef4d82ac7ae86437efc6070e381b8fb264f84a72eb7a542.jpg)



(d) CS


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/a42e5edd0177d934b0531143e599d6ec33ac70bdb424d59e1ce664992b285b20.jpg)



(e) Legal



Figure 11: Comparison of our newly designed method on abstract QA datasets.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/7f45b814c49e56c27f52b84fa7f295daa7aa6f6a1d2d23426fe651746e1ca760.jpg)



(a) chunk size=600


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/35e16c04686e1f06476c3684610d2fe1cd86703a085d91b5f1dfb7edfd2c0671.jpg)



(b) chunksize=2400


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/5b783fb5b3c1d37593279c3cc91ae6aafd1cf623e4bc6515b9febe81c5bbbb45.jpg)



(c) Qwen-2.5-32B


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/7107104f6ff1628697305746e635f3ecbbe782d1173494aa855705ab103b5e70.jpg)



(d) Llama-3-70B


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/ddd67845387cfb32955426e7602a288f6200974dcd80817526672f5d2b5ef148.jpg)



(e) GPT-4o-mini



Figure 12: Performance with different chunk sizes and LLM backbones on the MultihopSum dataset.



Table 10: The average time and token costs on abstract QA datasets.


<table><tr><td rowspan="2">Dataset</td><td colspan="2">VanillaRAG</td><td colspan="2">RAPTOR</td><td colspan="2">GGraphRAG</td><td colspan="2">HLightRAG</td><td colspan="2">FastGraphRAG</td><td colspan="2">CheapRAG</td></tr><tr><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td></tr><tr><td>Mix</td><td>18.7 s</td><td>4,114</td><td>35.5 s</td><td>4,921</td><td>72.2 s</td><td>10,922</td><td>22.6 s</td><td>5,687</td><td>20.9 s</td><td>4,779</td><td>27.3 s</td><td>11,720</td></tr><tr><td>MultihopSum</td><td>9.1 s</td><td>1,680</td><td>32.7 s</td><td>4,921</td><td>521.0 s</td><td>353,889</td><td>33.7 s</td><td>5,329</td><td>34.4 s</td><td>5,839</td><td>54.1 s</td><td>3,784</td></tr><tr><td>Agriculture</td><td>17.4 s</td><td>5,091</td><td>20.7 s</td><td>3,753</td><td>712.3 s</td><td>448,762</td><td>25.3 s</td><td>4,364</td><td>28.8 s</td><td>5,640</td><td>47.1 s</td><td>10,544</td></tr><tr><td>CS</td><td>17.8 s</td><td>4,884</td><td>32.7 s</td><td>4,921</td><td>442.0 s</td><td>322,327</td><td>51.4 s</td><td>4,908</td><td>28.2 s</td><td>5,692</td><td>48.8 s</td><td>17,699</td></tr><tr><td>Legal</td><td>26.2 s</td><td>2,943</td><td>59.8 s</td><td>3,573</td><td>231.2 s</td><td>129,969</td><td>31.1 s</td><td>4,441</td><td>34.0 s</td><td>5,411</td><td>34.8 s</td><td>14,586</td></tr></table>

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/e4ceb1690ffaf66fb945d9a58b18f23d73a9c5226512aa98680c427d44416fb5.jpg)



Figure 13: The taxonomy tree of RAG methods.


chunks is not a bad idea. Based on the results in Tables 5 and 8, and Figures  $6\sim 12$  , we conclude this lesson.

# Opportunities:

$\triangleright$  O1. All existing graph-based RAG methods (both specific QA and abstract QA) assume the setting of the external corpus is static. What if the external knowledge source evolves over time? For example, Wikipedia articles are constantly evolving, with frequent updates to reflect new information. Can we design graph-based RAG methods that efficiently and effectively adapt to such dynamic changes in external knowledge sources?

$\triangleright$  O2. The quality of a graph plays a key role in determining the effectiveness of graph-based RAG methods. However, evaluating graph quality before actually handling a question remains a critical challenge that needs to be addressed. Existing graph construction methods consume a substantial number of tokens and often produce graphs with redundant entities or miss potential relationships, so designing a cost-efficient yet effective construction method is a meaningful research direction.

$\triangleright$  O3. In many domains, the corpus is private (e.g., finance, legal, and medical), and retrieving the relevant information from such corpus can reveal information about the knowledge source. Designing a graph-based RAG method that incorporates local differential privacy is an interesting research problem.

$\triangleright$  O4. How to use LLMs and graph-based RAG methods to facilitate query optimization, such as generating efficient query plans and execution strategies, for database systems. More details are in our technical report [71].

# 9 RELATED WORKS

In this section, we mainly review the related works of existing RAG methods. We also present the applications of RAG in various areas, particularly in data management area.

- RAG methods. RAG has been proven to be very effective in migrating the "hallucination" of LLMs [5, 7-9, 35, 75]. Recently, most RAG approaches [15, 24, 25, 44, 67, 72, 85, 86] have adopted graph as the external knowledge to organize the information and relationships within documents, achieving improved overall retrieval

performance, which is extensively reviewed in this paper. Nevertheless, there is a lack of a comprehensive work comparison between all graph-based RAG methods in terms of accuracy and efficiency. We note that there exists an empirical study [26] that compares Microsoft's methods (LGraphRAG and GGraphRAG) with the standard Vani11aRAG, and a few survey papers on graph-based RAG systems [37, 92]. However, our work differs significantly from these in both scope and depth. First, our work focuses on systematically comparing the different graph-based RAG methods, and conduct a stage-wise comparison across a unified framework. This allows us to identify core design principles and enables the construction of a new state-of-the-art method through component recombination. Second, unlike survey papers that offer high-level overviews, our work provides deep empirical analysis and practical insights grounded in extensive experiments.

- RAG applications. Due to the wealth of developer experience captured in a vast array of database forum discussions, recent studies [7, 16, 23, 41, 48, 74, 78, 98, 99] have begun leveraging RAGs to enhance database performance. For instance, GPTuner [41] proposes to enhance database knob tuning using RAG by leveraging domain knowledge to identify important knobs and coarsely initialize their values for subsequent refinement. Besides, D-Bot [98] proposes an LLM-based database diagnosis system, which can retrieve relevant knowledge chunks and tools, and use them to identify typical root causes accurately. In addition, RAG-based SQL rewriting systems [48, 76, 78] have recently attracted significant attention. These methods retrieve domain-specific knowledge from database forums and official documentation to enhance SQL rewriting and optimization. The RAG-based data analysis systems have also been studied [3, 10, 49-53, 66]. For applications in other areas, we refer readers to recent RAG surveys [31, 93].

# 10 CONCLUSIONS

In this paper, we provide an in-depth experimental evaluation and comparison of existing graph-based Retrieval-Augmented Generation (RAG) methods. We first provide a novel unified framework, which can cover all the existing graph-based RAG methods, using an abstraction of a few key operations. We then thoroughly analyze and compare different graph-based RAG methods under our framework. We further systematically evaluate these methods from different angles using various datasets for both specific and abstract question-answering (QA) tasks, and also develop variations by combining existing techniques, which often outperform state-of-the-art methods. From extensive experimental results and analysis, we have identified several important findings and analyzed the critical components that affect the performance. In addition, we have summarized the lessons learned and proposed practical research opportunities that can facilitate future studies.

# REFERENCES


Table 11: Comparison RAPTOR and RAPTOR-K.


<table><tr><td rowspan="2">Method</td><td colspan="2">MultihopQA</td><td>Quality</td><td colspan="2">PopQA</td></tr><tr><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Accuracy</td><td>Recall</td></tr><tr><td>RAPTOR</td><td>56.064</td><td>44.832</td><td>56.997</td><td>62.545</td><td>27.304</td></tr><tr><td>RAPTOR-K</td><td>56.768</td><td>44.208</td><td>54.567</td><td>64.761</td><td>28.469</td></tr></table>

# A ADDITIONAL EXPERIMENTS

# A.1 Results on specific QA tasks

In this Section, we present the additional results on the specific QA tasks.

$\triangleright$  Exp.1. Comparison RAPTOR-K and RAPTOR. We compare RAPTOR-K with RAPTOR on the first three datasets, and present results in Table 11. We observe that RAPTOR-K achieves comparable or even better performance than RAPTOR.

$\triangleright$  Exp.2. Token costs of graph and index building. We report the token costs of building four types of graphs across HotpotQA and ALCE datasets in Figure 14. Recall that the token cost for an LLM call consists of two parts: the prompt token, which accounts for the tokens used in providing the input, and the completion part, which includes the tokens generated by the model as a response. Here, we report the token costs for prompt and completion on HotpotQA and ALCE in Figure 14(c) to (d), and show the results on other datasets in Figure 15. We conclude that, regardless of the graph type, the prompt part always incurs higher token costs than the completion part.

$\triangleright$  Exp.3. Evaluation of the generation costs. In this experiment, we evaluate the time and token costs for each method in specific QA tasks. Specifically, we report the average time and token costs for each query across all datasets in Table 12, the conclusions are consistent with those reported in our manuscript. As shown in Figure 16, we present the average token costs for prompt tokens and completion tokens across all questions in all specific QA datasets. We can observe that the running time of each method is highly proportional to the completion token costs, which aligns with the computational paradigm of the Transformer architecture.

$\triangleright$  Exp.4. Detailed analysis for RAPTOR and LGraphRAG. Our first analysis about RAPTOR aims to explain why RAPTOR outperforms VanillaRAG. Recall that in RAPTOR, for each question  $Q$ , it retrieves the top- $k$  items across the entire tree, meaning the retrieved items may originate from different layers. That is, we report the proportion of retrieved items across different tree layers in Table 13. As we shall see, for the MultihopQA and MusiqueQA datasets, the proportion of retrieved high-level information (i.e., items not from leaf nodes) is significantly higher than in other datasets. For datasets requiring multi-hop reasoning to answer questions, high-level information plays an essential role. This may explain why RAPTOR outperforms VanillaRAG on these two datasets.

We then conduct a detailed analysis of LGraphRAG on complex questions in specific QA datasets by modifying its retrieval methods or element types. By doing this, we create three variants of LGraphRAG, and we present the detailed descriptions for each variant in Table 14. Here, VGraphRAG-CC introduces a new retrieval strategy. Unlike LGraphRAG, it uses vector search to retrieve the top- $k$  elements (i.e., chunks or communities) from the vector database. Eventually, we evaluate their performance on the three complex QA datasets and present the results in Table 15.

$\triangleright$  Exp.5. Effect of the chunk size. Recall that our study includes some datasets that are pre-split by the export annotator. To

investigate this impact, we re-split the corpus into multiple chunks based on token size for these datasets instead of using their original chunks. Here, we create three new datasets from HotpotQA, PopQA, and ALCE, named HotpotAll, PopAll, and ALCEAll, respectively.

For each dataset, we use Original to denote its original version and New chunk to denote the version after re-splitting. We report the results of graph-based RAG methods on both the original and new version datasets in Figure 17, we can see that: (1) The performance of all methods declines, mainly because rule-based chunk splitting (i.e., by token size) fails to provide concise information as effectively as expert-annotated chunks. (2) Graph-based methods, especially those relying on TKG and RKG, are more sensitive to chunk quality. This is because the graphs they construct encapsulate richer information, and coarse-grained chunk splitting introduces potential noise within each chunk. Such noise can lead to inaccurate extraction of entities or relationships and their corresponding descriptions, significantly degrading the performance of these methods. (3) As for token costs, all methods that retrieve chunks incur a significant increase due to the larger chunk size in New chunk compared to Original, while other methods remain stable. These findings highlight that chunk segmentation quality is crucial for the overall performance of all RAG methods.

We evaluate all 12 RAG methods under chunk sizes of 600, 1200, and 2400 tokens, as shown in Table 16, and further select the top-performing eight methods to analyze how their performance varies with chunk size, as shown in Figure 18. We observe that the results across different settings remain largely consistent with the conclusions drawn using the default chunk size of 1200 in our submitted manuscript. Specifically, we make the following observations and analysis: (1) For simple QA datasets (e.g., PopAll and HotpotAll), smaller chunk sizes generally yield better performance. This is because such questions often require information that is directly available in a single chunk or two. Smaller chunks provide more focused and precise context, improving answer accuracy. (2) Across all chunk sizes, HippoRAG and RAPTOR perform best on simple QA tasks, while RAPTOR and LGraphRAG outperform others on complex QA datasets (e.g., MultihopQA, ALCEAll). These observations align with the results reported in our manuscript. (3) The effect of chunk size varies by task type: performance on simple QA tasks is highly sensitive to chunk size, while for complex QA tasks, performance remains relatively stable across different chunk sizes. This is because complex questions typically require reasoning across multiple chunks, making them less dependent on individual chunk granularity.

$\triangleright$  Exp.6. Effect of the LLM backbones. For each system, we evaluate multiple LLM backbones, including Llama-3-8B, Qwen-2.5-32B, Llama-3-70B, and GPT-4o-mini. These cover three open-source models ranging from small to large scales, as well as one proprietary yet strong GPT-family model. In this experiment, we fix the chunk size at 1200 tokens. As shown in Table 17, we evaluate each RAG method and the ZeroShot baseline on the MultihopQA and ALCEAll datasets using different LLM backbones. Based on the results, we can see that: (1) Stronger models generally yield better performance, especially in the ZeroShot setting, which most directly reflects the inherent capabilities of the underlying LLM. (2) We observe that the three variants of LightRAG, LLightRAG, GLightRAG, and HLightRAG as well as LGraphRAG, achieve significant performance improvements when using more powerful LLMs.

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/05abe193686b5c6375f37f55378d7fa0eb1392a10dd3fe5f08a122cdecaf815d.jpg)



(a) HotpotQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/7492363d688cf06f0d4b7de170df342cec85454e6a81fd48ceafbb28ddf1ba74.jpg)



(b) ALCE


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d192b9d3c7a85acb01c6f1b938feb37aaf120ddd9ac150bfbf905a593e0eb681.jpg)



(c) The token costs on HotpotQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/cc4fee02933b266345bbfb964771212e9a6f6ee513e5844d92c101674836dbb9.jpg)



(d) The token costs on ALCE



Figure 14: Token cost of graph building on specific QA datasets.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/6e63923d4bbc5e6d2b536f99a631bfdce5f8f9b3dbf4200d74ddad7262079c6a.jpg)



(a) MultihopQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/fc8277c5a9a7f26aa6ccaec41e2035195ae538e85c358cdb7c52524787ea9785.jpg)



(b) Quality


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/b5f890fc7bd7a48c11dc29d31da27a560d1a42e85c482632a241717113ee00fd.jpg)



(c) PopQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/e4bf996478a41b6fc8e2b5e07e025138653760fece56d8c781b26bcb4c3657f1.jpg)



(d) MusiqueQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/63a2f2cb0c2e82d6f5fc1aef8628ee41dd2a70ac528044a28741377d190293e9.jpg)



(e) Mix


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/95eaf72fcc394be9ef3b7235b7725fef1bce53c0576d27240e697a067984efd8.jpg)



(f) Agriculture


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/4dceb7d0c59449c75a01908e416d996caf270caf9d61656948d97795e5bfc1d7.jpg)



(g) CS


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/cae241a7feab64561a2ea5602bf42668215fb0b4c431ac3a22a169aa85db2c21.jpg)



(h) Legal



Figure 15: Proportion of the token costs for prompt and completion in graph building stage across all datasets.



Table 12: The average time and token costs of all methods on specific QA datasets.


<table><tr><td rowspan="2">Method</td><td colspan="2">MultihopQA</td><td colspan="2">Quality</td><td colspan="2">PopQA</td><td colspan="2">MusiqueQA</td><td colspan="2">HotpotQA</td><td colspan="2">ALCE</td></tr><tr><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td><td>time</td><td>token</td></tr><tr><td>ZeroShot</td><td>3.23 s</td><td>270.3</td><td>1.47 s</td><td>169.1</td><td>1.17 s</td><td>82.2</td><td>1.73 s</td><td>137.8</td><td>1.51 s</td><td>125.0</td><td>2.41 s</td><td>177.2</td></tr><tr><td>VanillaRAG</td><td>2.35 s</td><td>3,623.4</td><td>2.12 s</td><td>4,502.0</td><td>1.41 s</td><td>644.1</td><td>1.31 s</td><td>745.4</td><td>1.10 s</td><td>652.0</td><td>1.04 s</td><td>849.1</td></tr><tr><td>G-retriever</td><td>6.87 s</td><td>1,250.0</td><td>5.18 s</td><td>985.5</td><td>37.51 s</td><td>3,684.5</td><td>31.21 s</td><td>3,260.5</td><td>-</td><td>-</td><td>101.16 s</td><td>5,096.1</td></tr><tr><td>ToG</td><td>69.74 s</td><td>16,859.6</td><td>37.03 s</td><td>10,496.4</td><td>42.02 s</td><td>11,224.2</td><td>53.55 s</td><td>12,480.8</td><td>-</td><td>-</td><td>34.94 s</td><td>11,383.2</td></tr><tr><td>KGP</td><td>38.86 s</td><td>13,872.2</td><td>35.76 s</td><td>14,092.7</td><td>37.49 s</td><td>6,738.9</td><td>39.82 s</td><td>7,555.8</td><td>-</td><td>-</td><td>105.09 s</td><td>9,326.6</td></tr><tr><td>DALK</td><td>28.03 s</td><td>4,691.5</td><td>13.23 s</td><td>2,863.6</td><td>16.33 s</td><td>2,496.5</td><td>17.48 s</td><td>3,510.9</td><td>21.33 s</td><td>3,989.7</td><td>17.04 s</td><td>4,071.9</td></tr><tr><td>LLightRAG</td><td>19.28 s</td><td>5,774.1</td><td>15.76 s</td><td>5,054.5</td><td>10.71 s</td><td>2,447.5</td><td>13.95 s</td><td>3,267.6</td><td>13.94 s</td><td>3,074.2</td><td>10.34 s</td><td>4,427.9</td></tr><tr><td>GLightRAG</td><td>18.37 s</td><td>5,951.5</td><td>15.97 s</td><td>5,747.3</td><td>12.10 s</td><td>3,255.6</td><td>15.20 s</td><td>3,260.8</td><td>13.95 s</td><td>3,028.7</td><td>13.02 s</td><td>4,028.1</td></tr><tr><td>HLightRAG</td><td>19.31 s</td><td>7,163.2</td><td>21.49 s</td><td>6,492.5</td><td>17.71 s</td><td>5,075.8</td><td>20.93 s</td><td>5,695.3</td><td>19.58 s</td><td>4,921.7</td><td>16.55 s</td><td>6,232.3</td></tr><tr><td>FastGraphRAG</td><td>7.17 s</td><td>5,874.8</td><td>3.48 s</td><td>6,138.9</td><td>13.25 s</td><td>6,157.0</td><td>15.19 s</td><td>6,043.5</td><td>28.71 s</td><td>6,029.8</td><td>25.82 s</td><td>6,010.9</td></tr><tr><td>HippoRAG</td><td>3.46 s</td><td>3,261.1</td><td>3.03 s</td><td>3,877.6</td><td>2.32 s</td><td>721.3</td><td>2.69 s</td><td>828.4</td><td>3.12 s</td><td>726.4</td><td>2.94 s</td><td>858.2</td></tr><tr><td>LGraphRAG</td><td>2.98 s</td><td>6,154.9</td><td>3.77 s</td><td>6,113.7</td><td>1.72 s</td><td>4,325.2</td><td>2.66 s</td><td>4,675.7</td><td>2.05 s</td><td>4,806.2</td><td>2.11 s</td><td>5,441.1</td></tr><tr><td>RAPTOR</td><td>3.18 s</td><td>3,210.0</td><td>2.46 s</td><td>4,140.7</td><td>1.36 s</td><td>1,188.3</td><td>1.85 s</td><td>1,742.9</td><td>1.48 s</td><td>757.6</td><td>1.54 s</td><td>793.6</td></tr></table>


Table 14: Descriptions of the different variants of LGraphRAG.


<table><tr><td>Name</td><td>Retrieval elements</td><td>New retrieval strategy</td></tr><tr><td>LGraphRAG</td><td>Entity, Relationship, Community, Chunk</td><td>X</td></tr><tr><td>GraphRAG-ER</td><td>Entity, Relationship</td><td>X</td></tr><tr><td>GraphRAG-CC</td><td>Community, Chunk</td><td>X</td></tr><tr><td>VGraphRAG-CC</td><td>Community, Chunk</td><td>✓</td></tr><tr><td>VGraphRAG</td><td>Entity, Relationship, Community, Chunk</td><td>✓</td></tr></table>


Table 13: Proportion of retrieved nodes across tree layers.


<table><tr><td>Layer</td><td>MultihopQA</td><td>Quality</td><td>PopQA</td><td>MusiqueQA</td><td>HotpotQA</td><td>ALCE</td></tr><tr><td>0</td><td>59.3%</td><td>76.8%</td><td>76.1%</td><td>69.3%</td><td>89.7%</td><td>90.6%</td></tr><tr><td>1</td><td>27.5%</td><td>18.7%</td><td>16.5%</td><td>28.1%</td><td>9.5%</td><td>8.8%</td></tr><tr><td>&gt;1</td><td>13.2%</td><td>4.5%</td><td>7.4%</td><td>2.6%</td><td>0.8%</td><td>0.6%</td></tr></table>

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/56c2557eb1dac12f48024ff137d5f5d2ec09f64944cd2f7ae502e11afcbed783.jpg)



(a) MultihopQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/a41fd9314ba8575487ad5895c945d3a3250d61fca2635d5528ef51f9f3347654.jpg)



(b) Quality


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/df0c811ddfaecdabf74480bee5929494f18be2e92771f3e89dd6f1f8249b35ed.jpg)



(c) PopQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/adb07a095e14d37df76189ef964a4f4a42ffeb814694310ab87d6cf0953a9b3e.jpg)



(d) MusiqueQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8fc03f78d391468a40212d348d570447ecd6fa4d283e3588a85e8243e66142ce.jpg)



(e) HotpotQA


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f9cdc1fde0a3a25c3b4145ddf7777b8300696ff8bf524f75ced0449cd3439732.jpg)



(f) ALCE



Figure 16: Token costs for prompt and completion tokens in the generation stage across all datasets.



Table 15: Comparison of our newly designed methods on specific datasets with complex questions.


<table><tr><td>Dataset</td><td>Metric</td><td>ZeroShot</td><td>VanillaRAG</td><td>LGraphRAG</td><td>RAPTOR</td><td>GraphRAG-ER</td><td>GraphRAG-CC</td><td>VGraphRAG-CC</td><td>VGraphRAG</td></tr><tr><td rowspan="2">MultihopQA</td><td>Accuracy</td><td>49.022</td><td>50.626</td><td>55.360</td><td>56.064</td><td>52.739</td><td>52.113</td><td>55.203</td><td>59.664</td></tr><tr><td>Recall</td><td>34.526</td><td>36.918</td><td>50.429</td><td>44.832</td><td>45.113</td><td>43.770</td><td>46.750</td><td>50.893</td></tr><tr><td rowspan="2">MusiqueQA</td><td>Accuracy</td><td>1.833</td><td>17.233</td><td>12.467</td><td>24.133</td><td>11.200</td><td>13.767</td><td>22.400</td><td>26.933</td></tr><tr><td>Recall</td><td>5.072</td><td>27.874</td><td>23.996</td><td>35.595</td><td>22.374</td><td>25.707</td><td>35.444</td><td>40.026</td></tr><tr><td rowspan="3">ALCE</td><td>STRREC</td><td>15.454</td><td>34.283</td><td>28.448</td><td>35.255</td><td>26.774</td><td>35.366</td><td>37.820</td><td>41.023</td></tr><tr><td>STREM</td><td>3.692</td><td>11.181</td><td>8.544</td><td>11.076</td><td>7.5949</td><td>11.920</td><td>13.608</td><td>15.401</td></tr><tr><td>STRHIT</td><td>30.696</td><td>63.608</td><td>54.747</td><td>65.401</td><td>52.743</td><td>64.662</td><td>68.460</td><td>71.835</td></tr></table>

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/01dca332c10935b68db860a5099d1a8422f377c45946ccba035df9bdec21f94d.jpg)



(a) HotpotQA (Accuracy)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/851a37f9266c1eb0a337cb1b74a5b06330890cee2beb97533d9f2cc0043289cd.jpg)



(b) HotpotQA (Recall)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/56fa02b748e30f9f764005e2f75d430e9ba1fce9e612152d20548debfd3fc870.jpg)



(c) PopQA (Accuracy)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f09493ca8861f8a8a68ebdb95e8d3b0c4525976feadca1180695de8ea1ac1184.jpg)



(d) PopQA (Recall)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/e2b99f9a586ce2e0b3566573448689e2e75e09d821f7a3551cd61a46862e0e79.jpg)



(e) ALCE (STRREC)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/4fdfc709bea4e8213a67488ca74bc66b1e00952a8aa459a09689c51afb935c3d.jpg)



(f) ALCE (STREM)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/fa962c93256a181ec89c7123a704d00d65ea523ca7d26fbd7bb7b1689f502655.jpg)



(g) ALCE (STRHIT)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/1d26608df907ff90a56deb80e74d99c1c4354c22508110a40a9bb86b6dff1278.jpg)



(h) HotpotQA (Token)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/376daf15ec3177ad0790abcec02db35b476f489551cdceff0c48c052b41ee851.jpg)



(i) PopQA (Token)



Figure 17: Effect of chunk quality on the performance of specific QA tasks.



Table 16: Comparison of methods on different datasets under different chunk sizes, where Purple denotes the best result, and Orange denotes the best result excluding the best one.


<table><tr><td rowspan="2">Method</td><td rowspan="2">Chunk Size</td><td colspan="2">MultihopQA</td><td colspan="2">PopAll</td><td colspan="2">HotpotAll</td><td colspan="3">ALCEAll</td></tr><tr><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Recall</td><td>Accuracy</td><td>Recall</td><td>STRREC</td><td>STREM</td><td>STRHIT</td></tr><tr><td rowspan="3">VanillaRAG</td><td>600</td><td>54.421</td><td>42.740</td><td>57.255</td><td>24.171</td><td>49.190</td><td>56.935</td><td>30.174</td><td>8.333</td><td>57.911</td></tr><tr><td>1200</td><td>50.626</td><td>36.918</td><td>57.041</td><td>25.877</td><td>44.254</td><td>52.511</td><td>29.334</td><td>8.228</td><td>56.329</td></tr><tr><td>2400</td><td>50.665</td><td>37.172</td><td>47.677</td><td>19.122</td><td>27.553</td><td>34.293</td><td>26.350</td><td>7.490</td><td>51.371</td></tr><tr><td rowspan="3">G-retriever</td><td>600</td><td>44.953</td><td>47.322</td><td>19.014</td><td>6.895</td><td>18.882</td><td>27.041</td><td>10.506</td><td>2.532</td><td>21.414</td></tr><tr><td>1200</td><td>42.019</td><td>43.116</td><td>20.157</td><td>6.567</td><td>19.098</td><td>27.262</td><td>13.061</td><td>2.848</td><td>26.160</td></tr><tr><td>2400</td><td>41.667</td><td>36.611</td><td>20.229</td><td>6.763</td><td>27.958</td><td>36.940</td><td>14.822</td><td>2.954</td><td>30.591</td></tr><tr><td rowspan="3">ToG</td><td>600</td><td>42.214</td><td>37.823</td><td>49.035</td><td>22.642</td><td>-</td><td>-</td><td>16.240</td><td>3.376</td><td>33.439</td></tr><tr><td>1200</td><td>41.941</td><td>38.435</td><td>49.750</td><td>22.767</td><td>-</td><td>-</td><td>15.909</td><td>3.059</td><td>33.755</td></tr><tr><td>2400</td><td>41.667</td><td>36.611</td><td>44.961</td><td>20.374</td><td>-</td><td>-</td><td>14.822</td><td>2.954</td><td>30.591</td></tr><tr><td rowspan="3">KGP</td><td>600</td><td>46.831</td><td>34.714</td><td>41.101</td><td>18.064</td><td>-</td><td>-</td><td>26.799</td><td>7.806</td><td>51.793</td></tr><tr><td>1200</td><td>48.161</td><td>36.272</td><td>41.887</td><td>18.498</td><td>-</td><td>-</td><td>27.551</td><td>7.806</td><td>52.637</td></tr><tr><td>2400</td><td>48.083</td><td>36.486</td><td>40.815</td><td>18.060</td><td>-</td><td>-</td><td>26.370</td><td>6.540</td><td>51.477</td></tr><tr><td rowspan="3">DALK</td><td>600</td><td>55.986</td><td>48.202</td><td>41.243</td><td>16.131</td><td>32.766</td><td>41.737</td><td>21.734</td><td>4.536</td><td>44.304</td></tr><tr><td>1200</td><td>53.952</td><td>47.232</td><td>42.602</td><td>17.024</td><td>30.416</td><td>39.544</td><td>21.327</td><td>4.430</td><td>43.987</td></tr><tr><td>2400</td><td>53.208</td><td>46.829</td><td>45.318</td><td>18.651</td><td>28.633</td><td>37.826</td><td>20.350</td><td>4.430</td><td>41.456</td></tr><tr><td rowspan="3">LLightRAG</td><td>600</td><td>46.675</td><td>39.190</td><td>38.671</td><td>16.040</td><td>32.334</td><td>39.753</td><td>20.084</td><td>4.641</td><td>40.717</td></tr><tr><td>1200</td><td>44.053</td><td>35.528</td><td>36.312</td><td>14.947</td><td>29.876</td><td>37.258</td><td>20.594</td><td>5.169</td><td>40.506</td></tr><tr><td>2400</td><td>43.858</td><td>36.878</td><td>35.811</td><td>14.230</td><td>29.336</td><td>36.621</td><td>19.576</td><td>5.485</td><td>38.397</td></tr><tr><td rowspan="3">GLightRAG</td><td>600</td><td>47.222</td><td>36.885</td><td>20.801</td><td>6.860</td><td>24.419</td><td>31.852</td><td>18.319</td><td>5.063</td><td>36.814</td></tr><tr><td>1200</td><td>48.474</td><td>38.365</td><td>18.227</td><td>6.643</td><td>23.285</td><td>30.888</td><td>17.686</td><td>4.852</td><td>34.599</td></tr><tr><td>2400</td><td>48.592</td><td>41.213</td><td>14.653</td><td>5.890</td><td>19.665</td><td>27.566</td><td>13.493</td><td>3.376</td><td>26.688</td></tr><tr><td rowspan="3">HLightRAG</td><td>600</td><td>50.196</td><td>40.626</td><td>34.668</td><td>15.326</td><td>30.632</td><td>38.194</td><td>23.833</td><td>5.907</td><td>47.363</td></tr><tr><td>1200</td><td>50.313</td><td>41.613</td><td>31.594</td><td>12.812</td><td>27.796</td><td>36.010</td><td>22.475</td><td>6.329</td><td>43.776</td></tr><tr><td>2400</td><td>49.648</td><td>41.775</td><td>30.093</td><td>11.683</td><td>26.958</td><td>34.387</td><td>20.816</td><td>5.485</td><td>40.823</td></tr><tr><td rowspan="3">FastGraphRAG</td><td>600</td><td>50.000</td><td>44.736</td><td>49.392</td><td>22.326</td><td>35.467</td><td>43.534</td><td>30.116</td><td>9.705</td><td>55.907</td></tr><tr><td>1200</td><td>52.895</td><td>44.278</td><td>46.748</td><td>19.996</td><td>32.118</td><td>40.966</td><td>27.258</td><td>7.490</td><td>53.376</td></tr><tr><td>2400</td><td>47.261</td><td>46.251</td><td>32.809</td><td>12.879</td><td>26.445</td><td>34.800</td><td>22.020</td><td>6.435</td><td>42.300</td></tr><tr><td rowspan="3">HippoRAG</td><td>600</td><td>47.144</td><td>41.210</td><td>62.401</td><td>26.892</td><td>50.783</td><td>58.454</td><td>27.025</td><td>8.122</td><td>51.477</td></tr><tr><td>1200</td><td>53.760</td><td>47.671</td><td>60.472</td><td>25.041</td><td>55.267</td><td>62.862</td><td>21.633</td><td>5.696</td><td>41.561</td></tr><tr><td>2400</td><td>52.152</td><td>46.601</td><td>50.751</td><td>19.986</td><td>45.624</td><td>53.597</td><td>26.477</td><td>6.118</td><td>52.848</td></tr><tr><td rowspan="3">LGraphRAG</td><td>600</td><td>55.282</td><td>46.267</td><td>53.181</td><td>26.292</td><td>41.194</td><td>49.801</td><td>33.692</td><td>10.971</td><td>62.447</td></tr><tr><td>1200</td><td>55.360</td><td>50.429</td><td>39.814</td><td>17.998</td><td>30.686</td><td>38.824</td><td>27.785</td><td>8.017</td><td>52.954</td></tr><tr><td>2400</td><td>54.930</td><td>44.588</td><td>43.317</td><td>20.185</td><td>37.061</td><td>45.366</td><td>28.398</td><td>7.806</td><td>54.008</td></tr><tr><td rowspan="3">RAPTOR</td><td>600</td><td>56.729</td><td>46.358</td><td>61.830</td><td>28.176</td><td>56.132</td><td>63.584</td><td>35.111</td><td>12.236</td><td>63.186</td></tr><tr><td>1200</td><td>56.064</td><td>44.832</td><td>47.963</td><td>21.399</td><td>31.983</td><td>39.864</td><td>34.044</td><td>10.971</td><td>62.342</td></tr><tr><td>2400</td><td>56.299</td><td>44.610</td><td>48.177</td><td>21.289</td><td>31.983</td><td>39.122</td><td>33.432</td><td>10.654</td><td>61.181</td></tr></table>

This can be attributed to their reliance on Rich Knowledge Graphs and Textual Knowledge Graphs, where stronger LLMs contribute to the construction of higher-quality graphs. (3) HippoRAG shows notably superior performance when using GPT-4o-mini compared to other LLM backbones. We attribute this to GPT-4o-mini's ability to extract more accurate entities from the question and to construct higher-quality knowledge graphs, thereby improving the retrieval

of relevant chunks and the final answer accuracy. (4) Regardless of the LLM backbone, our proposed method VGraphRAG consistently achieves the best performance, demonstrating the advantages of our proposed unified framework.

$\triangleright$  Exp.7. The size of graph. For each dataset, we report the size of five types of graphs in Table 18. We observe that PG is typically denser than other types of graphs, as they connect nodes based on


Table 17: The specific QA performance comparison of graph-based RAG methods with different LLM backbones.


<table><tr><td rowspan="2">Method</td><td rowspan="2">LLM backbone</td><td colspan="2">MultihopQA</td><td colspan="3">ALCEAll</td></tr><tr><td>Accuracy</td><td>Recall</td><td>STRREC</td><td>STREM</td><td>STRHIT</td></tr><tr><td rowspan="4">ZeroShot</td><td>Llama-3-8B</td><td>49.022</td><td>34.256</td><td>15.454</td><td>3.692</td><td>30.696</td></tr><tr><td>Qwen-2.5-32B</td><td>45.070</td><td>33.332</td><td>30.512</td><td>10.127</td><td>56.118</td></tr><tr><td>Llama-3-70B</td><td>55.908</td><td>52.987</td><td>31.234</td><td>7.170</td><td>61.920</td></tr><tr><td>GPT-4o-mini</td><td>59.546</td><td>48.322</td><td>34.965</td><td>10.232</td><td>66.245</td></tr><tr><td rowspan="4">VanillaRAG</td><td>Llama-3-8B</td><td>50.626</td><td>36.918</td><td>29.334</td><td>8.228</td><td>56.329</td></tr><tr><td>Qwen-2.5-32B</td><td>56.299</td><td>47.660</td><td>39.490</td><td>14.873</td><td>69.937</td></tr><tr><td>Llama-3-70B</td><td>56.768</td><td>49.127</td><td>34.961</td><td>9.810</td><td>68.038</td></tr><tr><td>GPT-4o-mini</td><td>59.311</td><td>47.941</td><td>35.735</td><td>10.127</td><td>68.249</td></tr><tr><td rowspan="4">G-retriever</td><td>Llama-3-8B</td><td>42.019</td><td>43.116</td><td>13.061</td><td>2.848</td><td>26.160</td></tr><tr><td>Qwen-2.5-32B</td><td>43.075</td><td>33.864</td><td>34.678</td><td>13.608</td><td>60.338</td></tr><tr><td>Llama-3-70B</td><td>50.430</td><td>50.144</td><td>24.575</td><td>5.907</td><td>49.051</td></tr><tr><td>GPT-4o-mini</td><td>56.534</td><td>46.427</td><td>31.681</td><td>7.068</td><td>62.764</td></tr><tr><td rowspan="4">ToG</td><td>Llama-3-8B</td><td>41.941</td><td>38.435</td><td>15.909</td><td>3.059</td><td>33.755</td></tr><tr><td>Qwen-2.5-32B</td><td>34.390</td><td>35.566</td><td>19.167</td><td>4.430</td><td>39.662</td></tr><tr><td>Llama-3-70B</td><td>42.762</td><td>38.495</td><td>18.449</td><td>3.270</td><td>38.819</td></tr><tr><td>GPT-4o-mini</td><td>41.862</td><td>30.247</td><td>28.405</td><td>7.068</td><td>56.962</td></tr><tr><td rowspan="4">KGP</td><td>Llama-3-8B</td><td>48.161</td><td>36.272</td><td>27.551</td><td>7.806</td><td>52.637</td></tr><tr><td>Qwen-2.5-32B</td><td>61.463</td><td>57.340</td><td>40.608</td><td>14.873</td><td>71.097</td></tr><tr><td>Llama-3-70B</td><td>55.008</td><td>47.878</td><td>35.420</td><td>10.549</td><td>68.379</td></tr><tr><td>GPT-4o-mini</td><td>63.146</td><td>55.789</td><td>38.015</td><td>12.764</td><td>69.620</td></tr><tr><td rowspan="4">DALK</td><td>Llama-3-8B</td><td>53.952</td><td>47.232</td><td>21.327</td><td>4.430</td><td>43.987</td></tr><tr><td>Qwen-2.5-32B</td><td>32.003</td><td>20.158</td><td>16.653</td><td>4.430</td><td>33.333</td></tr><tr><td>Llama-3-70B</td><td>60.524</td><td>55.086</td><td>28.980</td><td>5.696</td><td>60.338</td></tr><tr><td>GPT-4o-mini</td><td>66.980</td><td>57.687</td><td>31.813</td><td>8.333</td><td>62.236</td></tr><tr><td rowspan="4">LLightRAG</td><td>Llama-3-8B</td><td>44.053</td><td>35.528</td><td>20.594</td><td>5.169</td><td>40.506</td></tr><tr><td>Qwen-2.5-32B</td><td>48.552</td><td>45.387</td><td>31.549</td><td>9.916</td><td>59.177</td></tr><tr><td>Llama-3-70B</td><td>57.081</td><td>54.510</td><td>28.636</td><td>8.228</td><td>56.013</td></tr><tr><td>GPT-4o-mini</td><td>52.113</td><td>38.923</td><td>38.446</td><td>15.084</td><td>33.456</td></tr><tr><td rowspan="4">GLightRAG</td><td>Llama-3-8B</td><td>48.474</td><td>38.365</td><td>17.686</td><td>4.852</td><td>34.599</td></tr><tr><td>Qwen-2.5-32B</td><td>52.582</td><td>48.236</td><td>27.961</td><td>9.599</td><td>53.165</td></tr><tr><td>Llama-3-70B</td><td>55.986</td><td>51.713</td><td>23.553</td><td>5.807</td><td>45.992</td></tr><tr><td>GPT-4o-mini</td><td>55.125</td><td>47.899</td><td>39.095</td><td>15.506</td><td>67.933</td></tr><tr><td rowspan="4">HLightRAG</td><td>Llama-3-8B</td><td>50.313</td><td>41.613</td><td>22.475</td><td>6.329</td><td>43.776</td></tr><tr><td>Qwen-2.5-32B</td><td>53.678</td><td>51.403</td><td>34.168</td><td>10.971</td><td>63.819</td></tr><tr><td>Llama-3-70B</td><td>57.081</td><td>54.510</td><td>29.548</td><td>8.228</td><td>57.911</td></tr><tr><td>GPT-4o-mini</td><td>55.829</td><td>46.424</td><td>41.334</td><td>15.506</td><td>71.730</td></tr><tr><td rowspan="4">FastGraphRAG</td><td>Llama-3-8B</td><td>52.895</td><td>44.278</td><td>27.258</td><td>7.490</td><td>53.376</td></tr><tr><td>Qwen-2.5-32B</td><td>46.088</td><td>50.370</td><td>31.387</td><td>10.021</td><td>59.388</td></tr><tr><td>Llama-3-70B</td><td>54.069</td><td>55.787</td><td>35.658</td><td>12.236</td><td>65.612</td></tr><tr><td>GPT-4o-mini</td><td>66.080</td><td>57.007</td><td>23.521</td><td>8.228</td><td>42.827</td></tr><tr><td rowspan="4">HippoRAG</td><td>Llama-3-8B</td><td>53.760</td><td>47.671</td><td>21.633</td><td>5.696</td><td>41.561</td></tr><tr><td>Qwen-2.5-32B</td><td>48.083</td><td>40.488</td><td>37.419</td><td>13.397</td><td>66.245</td></tr><tr><td>Llama-3-70B</td><td>57.277</td><td>57.736</td><td>32.904</td><td>9.916</td><td>32.534</td></tr><tr><td>GPT-4o-mini</td><td>67.723</td><td>55.482</td><td>39.274</td><td>12.447</td><td>72.046</td></tr><tr><td rowspan="4">LGraphRAG</td><td>Llama-3-8B</td><td>55.360</td><td>50.429</td><td>27.785</td><td>8.017</td><td>52.954</td></tr><tr><td>Qwen-2.5-32B</td><td>49.531</td><td>52.113</td><td>35.406</td><td>12.553</td><td>63.924</td></tr><tr><td>Llama-3-70B</td><td>58.060</td><td>55.390</td><td>34.256</td><td>10.232</td><td>66.561</td></tr><tr><td>GPT-4o-mini</td><td>65.415</td><td>50.216</td><td>36.890</td><td>11.287</td><td>69.304</td></tr><tr><td rowspan="4">RAPTOR</td><td>Llama-3-8B</td><td>56.064</td><td>44.832</td><td>34.044</td><td>10.971</td><td>62.342</td></tr><tr><td>Qwen-2.5-32B</td><td>60.485</td><td>56.359</td><td>39.267</td><td>13.924</td><td>70.359</td></tr><tr><td>Llama-3-70B</td><td>63.028</td><td>61.042</td><td>37.286</td><td>12.236</td><td>68.671</td></tr><tr><td>GPT-4o-mini</td><td>60.603</td><td>51.521</td><td>29.770</td><td>8.017</td><td>58.861</td></tr><tr><td rowspan="4">VGraphRAG</td><td>Llama-3-8B</td><td>59.664</td><td>50.893</td><td>35.213</td><td>11.603</td><td>64.030</td></tr><tr><td>Qwen-2.5-32B</td><td>57.277</td><td>55.151</td><td>39.234</td><td>14.557</td><td>69.831</td></tr><tr><td>Llama-3-70B</td><td>67.567</td><td>68.445</td><td>37.576</td><td>12.447</td><td>69.198</td></tr><tr><td>GPT-4o-mini</td><td>68.193</td><td>56.564</td><td>43.963</td><td>18.038</td><td>74.473</td></tr></table>

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/a538d232dffdfab7fe2ec7ec9976391e4d6dacdfa539a9ed0424e3e894797325.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/c16cffe5aaa73f75d094e284f0bc9a5570ac4abb2ef2bb0a0a0bf8ef9516f266.jpg)



(a) MultihopQA (Accuracy)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/9673d191b6b99995500538be2caceeca6e98a9ff1105f23a22e8c6708748f29c.jpg)



(b) MultihopQA (Recall)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8b8ab11dfbb8c9af61fd119522883721fb47d5413e09ea7e444d0dcfd660c541.jpg)



(c) PopAll (Accuracy)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/3cd7b02d2dfa64202f80b2406bd4c50bff2478bb7558c89df0a18663d1ec1900.jpg)



(d) PopAll (Recall)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/98bfa8f03c415410e79ab900c39ed3b269092d6317695108bd521f49cd3778b5.jpg)



(e) HotpotAll (Accuracy)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/33dac19a721c2106e7b50b13b956a00665fbe24c526cee204876bc3d08952390.jpg)



(f) HotpotAll (Recall)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f1ae45da3870980b6f1c5353c4eca5b4f0d7e9152e3f3d2d7faa2c3b69100581.jpg)



(g) ALCEAll (STRREC)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f3446289f2a74478a9af6c38c6511e3e0c038cc1650b2a350aafd4b0a1e7364e.jpg)



(h) ALCEAll (STREM)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/aca0a2a2fc641163543968655ba4478ada6aafca994b4b06ec2e61f59bec197e.jpg)



(i) ALCEAll (STRHIT)



Figure 18: Effect of chunk size.


shared entity relationships, where each node represents a chunk in PG. In fact, the probability of two chunks sharing at least a few entities is quite high, leading to a high graph density (i.e., the ratio of edges to nodes), sometimes approaching a clique (fully connected graph). In contrast, KG, TKG, and RKG are much sparser since they rely entirely on LLMs to extract nodes and edges. This sparsity is primarily due to the relatively short and incomplete outputs typically generated by LLMs, which miss considerable potential node-edge pairs. Interestingly, the size or density of the constructed graph has not shown a strong correlation with the final performance of graph-based RAG methods. This observation motivates us to explore a method for evaluating the quality of the constructed graph before using it for LLM-based question answering.

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/3ca4be4ed21e60e79d1fc7489b9aa79d2f242f1819d6d350a29adda4a967eff5.jpg)



If You Ever Get Lonely was covered by what Lyric Street Records-affiliated band?


Extracted Entities: [Lyric Street Records]

Miss Entity: [If You Ever Get Lonely ]

HippoRAG's Output

The answer is not provided in the text. The text only talks about Kevin Denney, his music, and paleontology in Kentucky, but does not mention a specific Lyric Street Records-affiliated band that covered the song.

(a) Miss key entities

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/585bc41943c728c5ea0f55b3b9870b12ccad5b15e5fab0953f3f5ea1f689d28b.jpg)



Grown-Ups starred the actor who was best known for which role on "Allo 'Allo!?"


# Extracted Entities: [Grown-Ups, 'Allo 'Allo!, actor]

Retrieved chunks

1. Grown-Ups is a 1980 British BBC television film devised and directed by Mike Leigh.

2. It stars Lesley Manville, Philip Davis, Brenda Blethyn, Janine Duvitski, Lindsay Duncan and Sam Kelly.

3. The following is a list of episodes for the British sitcom "Allo 'Allo!" that aired from 1982 to 1992.

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/7c29ed1cb1013a630c20c42401b6d91968ea247bfa7f0042033ae309dc394e18.jpg)


According to the text, Nicholas Frankau, who played the role of Flt. Lt. Carstairs in "Allo 'Allo!", is best known for that role.

Answer: [Captain Hans Geering]

(b) Irrelevant chunks


Figure 19: The failure cases of HippoRAG.


$\triangleright$  Exp.8. Failure cases of graph-based RAG methods. We would like to clarify that the results presented in our paper represent the average performance across all questions within each

dataset. Thus, not all graph-based RAG methods consistently outperform the baseline VanillaRAG on every question. We conduct a detailed failure case analysis focusing on the top-performing methods. Specifically, we examine why RAPTOR, HippoRAG, RAPTOR and LGraphRAG sometimes fall short in specific QA tasks. Please refer to the detailed analysis provided below.

# The key failure reasons of HippoRAG:

(1) Incorrect or incomplete entity extraction from the question. Consider the example in Figure 19(a), where HippoRAG extracts the entity "Lyric Street Records" from the question and then applies Personalized PageRank based on this entity to retrieve relevant chunks. However, to answer this question correctly, two key entities are required: "Lyric Street Records" and "If You Ever Get Lonely". Since HippoRAG fails to extract the latter, it retrieves chunks that are insufficient to provide a correct answer.

(2) Retrieval of irrelevant chunks by Personalized PageRank. In another example shown in Figure 19(b), HippoRAG correctly extracts the relevant entities ["Grown-ups", "Allo 'Allo!","actor"] from the question. However, its chunk retriever strategy—Personalized PageRank—tends to favor chunks where these entities appear frequently, regardless of whether the content is semantically relevant to the question. As a result, the retrieved chunks may not align with the actual intent of the question, leading to an incorrect final answer.

# The key failure reason of Raptor:

- Low-quality cluster summaries. As illustrated in Figure 20, Raptor retrieves cluster summaries generated from groups of similar chunks. However, chunks within the same cluster may mention various loosely related facts that are topically similar but not logically unified. For example, the summary "Top Scorers of 2023" in Figure 20 contains some loosely related facts about scorers in 2023, which are too general to provide a precise answer. When summarizing such content, the LLM tends to produce generic or fragmented summaries


Table 18: The size of each graph type across all datasets.


<table><tr><td rowspan="2">Dataset</td><td colspan="2">Tree</td><td colspan="2">PG</td><td colspan="2">KG</td><td colspan="2">TKG</td><td colspan="2">RKG</td></tr><tr><td># of vertices</td><td># of edges</td><td># of vertices</td><td># of edges</td><td># of vertices</td><td># of edges</td><td># of vertices</td><td># of edges</td><td># of vertices</td><td># of edges</td></tr><tr><td>MultihopQA</td><td>2,053</td><td>2,052</td><td>1,658</td><td>564,446</td><td>35,953</td><td>37,173</td><td>12,737</td><td>10,063</td><td>18,227</td><td>12,441</td></tr><tr><td>Quality</td><td>1,862</td><td>1,861</td><td>1,518</td><td>717,468</td><td>28,882</td><td>30,580</td><td>10,884</td><td>8,992</td><td>13,836</td><td>9,044</td></tr><tr><td>PopQA</td><td>38,325</td><td>38,324</td><td>32,157</td><td>3,085,232</td><td>260,202</td><td>336,676</td><td>179,680</td><td>205,199</td><td>188,946</td><td>215,623</td></tr><tr><td>MusiqueQA</td><td>33,216</td><td>33,215</td><td>29,898</td><td>3,704,201</td><td>228,914</td><td>295,629</td><td>153,392</td><td>183,703</td><td>149,125</td><td>188,149</td></tr><tr><td>HotpotQA</td><td>73,891</td><td>73,890</td><td>66,559</td><td>13,886,807</td><td>511,705</td><td>725,521</td><td>291,873</td><td>401,693</td><td>324,284</td><td>436,362</td></tr><tr><td>ALCE</td><td>99,303</td><td>99,302</td><td>89,376</td><td>22,109,289</td><td>610,925</td><td>918,499</td><td>306,821</td><td>475,018</td><td>353,989</td><td>526,486</td></tr><tr><td>Mix</td><td>719</td><td>718</td><td>1,778</td><td>1,225,815</td><td>28,793</td><td>34,693</td><td>7,464</td><td>2,819</td><td>7,701</td><td>3,336</td></tr><tr><td>MultihopSum</td><td>2,053</td><td>2,052</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td><td>12,737</td><td>10,063</td><td>18,227</td><td>12,441</td></tr><tr><td>Agriculture</td><td>2,156</td><td>2,155</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td><td>15,772</td><td>7,333</td><td>17,793</td><td>12,600</td></tr><tr><td>CS</td><td>2,244</td><td>2,243</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td><td>10,175</td><td>6,560</td><td>12,340</td><td>8,692</td></tr><tr><td>Legal</td><td>5,380</td><td>5,379</td><td>N/A</td><td>N/A</td><td>N/A</td><td>N/A</td><td>15,034</td><td>10,920</td><td>16,565</td><td>17,633</td></tr></table>

# MultihopQA

Which rugby team, featured in articles from 'The Independent - Sports' and 'The Roar | Sports Writers Blog', faced home defeats to Ireland, South Africa, and Argentina, aimed to utilize a numerical advantage by kicking for the corner, and has players striving to conclude their careers on a high note, while also having lost to Argentina both in Christchurch and previously in Sydney?

Retrieved summaries

1. Top Scorers of 2023.

2. Australian Davis Cup Team Advances to Final.

3. West Indies vs England T20 International Cricket Match.

4. CONCACAF Nations League Quarterfinal Second Leg.

5. France vs Italy Rugby World Cup Match.

France defeated Italy 40-0 in a Rugby World Cup match, securing their spot in the quarterfinals.

France's top spot in Pool A is secured, and they will face either Ireland, South Africa, or Scotland

6. England Cricket Team Struggles.

7. Australian Women's Cricket Team.

Raptor's Output

Overall, based on the articles, it is clear that France is the team that ...

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/b956252e9dc3b050837747fd463533cd646d50b8d7ee363533c0214692e93c5c.jpg)


Answer: [All Blacks]


Figure 20: The failure case of Raptor.


# MultihopQA

What entity, discussed in articles from both The Verge and Fortune, was involved in implementing a system to prevent liquidation due to software issues, took on losses to maintain another company's balance sheet, and claimed to have acted legally in its business practices as a customer, payment processor, and market maker?

Retrieved Entities: [the verge, Google, mastercard, ...]

Retrieved communities

Google Community: Influence, Innovation, and Ethical Concerns

> Google's Influence in the Technology Industry

Google's AI Capabilities

Google's Partnerships and Collaborations

Google's Impact on the Technology Industry

Google's Potential for Bias and Misuse

LGraphRAG's Output

Output: [Google]

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/272e20f34b6ef838bbb21c47b5c6bb885f737506e4a999b31238001105972d3d.jpg)


Answer: [Alameda Research]


Figure 21: The failure case of LGraphRAG (I).


# MultihopQA

Which company, featured in articles from both Wired and Cnbc | World Business News Leader, introduced an invite-only deal system during a summer event for its members and is also considered to provide a life-changing opportunity for its sellers?

Retrieved Relationships: [(OpenAI, pricing schema), (eater, wine), (green monday, newegg)]

Retrieved chunks

# The chunks contain the (OpenAI, pricing schema)

Will that fact lead startups building modern AI tools to pursue more traditional SaaS pricing? (The OpenAI pricing schema based on tokens and usage led us to this question.) The trajectory of usage-based pricing has organically aligned with the needs of large language models, given that there is significant variation in prompt/output sizes and resource utilization per user. OpenAI itself racks upward of $700,000 per day on compute, so to achieve profitability, these operation costs ...

LGraphRAG's Output

Output: [OpenAI]

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/bcc76326d2e2089e1430f04b7f05578b53ba07ab32aec9c077ebafb4126a967b.jpg)


Answer: [Amazon]


Figure 22: The failure case of LGraphRAG (II).


that fail to capture the key information required to answer the question.

# The key failure reasons of LGraphRAG:

- Irrelevant community reports retrieved by Entity operator. Consider the example in Figure 21, where LGraphRAG first extracts entities such as ["The Verge", "Google", "Mastercard", ...] from the question. It then applies the Entity operator to retrieve communities whose reports contain these entities. Among them, communities with frequent mentions of "Google" are prioritized. However, these retrieved communities turn out to be irrelevant to the actual question, as the method relies solely on surface-level entity frequency while ignoring semantic relevance.

- Irrelevant chunks retrieved by Occurrence operator. Consider the example in Figure 22, where LGraphRAG extracts relationships such as ["OpenAI", "pricing schema"], ("Eater", "wine"), ("greenmonday", "newegg")] from the question. It then applies the Occurrence operator to retrieve chunks that contain the relationship ("OpenAI", "pricing schema") with high frequency. Based on these chunks, LGraphRAG generates the incorrect answer "OpenAI". The key reason is that the retrieved chunks, despite their frequent mentions of certain relationships, are not semantically relevant to the question. The method relies on co-occurrence frequency rather than actual contextual relevance.

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/73b7e8e02bc5fa0e5c1a4c4725882b2447d78841be1e3dbbb792538da5e4de91.jpg)



(a) Mix


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8df17db7f5ab5142c91ffc0620319bad8894464c6671bc9825eaaf8967325747.jpg)



(b) MultihopSum


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/e64d065ae1146dba2d813417911d0194aee6dc0d1ab1ea8eefc7a2e18454d483.jpg)



(c) Agriculture


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/61872dbf615eab351a15125c4cd02c353d0121e1913c730ec89682a1e8072243.jpg)



(d) CS


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/74ee6ff60ad0b32bd64acc79760219a5b6f77bb9631ac49b96560a0b06ac9b06.jpg)



(e) Legal



Figure 23: Token cost of the graph building on abstract QA datasets.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/c1fdceffa77c45dfeb6a7d5088cc9f4e6c1359cba08be3dd1ba9640bc71bf3f2.jpg)



Figure 24: Token cost of index construction in abstract QA.


# A.2 Results on abstract QA tasks

In this subsection, we present the addition results on abstract QA tasks.

$\triangleright$  Exp.1. Token costs of graph and index building. The token costs of the graph and index building across all abstract QA datasets are shown in Figures 23 and 24 respectively. The conclusions are highly similar to the Exp.2 in Section 7.2.

$\triangleright$  Exp.2. Effect of chunk size. We report the performance of various RAG methods on abstract QA tasks under different chunk sizes in Figures 25 to 27. Our key observations are as follows: (1) The performance of GGraphRAG remains stable across different chunk sizes, likely due to its use of the Map-Reduce strategy for final answer synthesis, which mitigates the influence of chunk granularity. (2) In contrast, methods like FastGraphRAG and VaniillaRAG show greater variance across chunk sizes, as their performance relies heavily on the granularity of individual chunks—smaller chunks tend to provide more precise information, directly impacting retrieval and generation quality. (3) Regardless of chunk size, RAPTOR and GGraphRAG consistently achieve the best performance, reaffirming our earlier conclusion that high-level structural information is essential for abstract QA tasks.

Additionally, we evaluate our newly proposed method CheapRAG across different chunk sizes. As shown in Figure 28, CheapRAG generally outperforms the five baselines. Notably, under the 600-token setting, CheapRAG surpasses GGraphRAG in more cases. We attribute this to the higher precision of smaller chunks, which enhances the effectiveness of semantic similarity-based retrieval in CheapRAG, compared to the entity frequency-based retrieval strategy used in GGraphRAG.

$\triangleright$  Exp.3. Effect of LLM backbone. We evaluate all methods that support abstract QA on the MultihopSum dataset, using different LLM backbones. Results for Llama-3-8B are shown in Figure 26, while Figures 29 to 31 present results for the other models. We observe that, across different backbones, the performance of each method on abstract QA tasks remains relatively stable—especially when compared to the fluctuations seen in specific QA tasks. We note that all methods still lag behind GGraphRAG, further highlighting that community-level information is particularly beneficial for abstract QA tasks. Moreover, we compare our newly proposed method, CheapRAG, with five strong baselines under different LLM backbones. As shown in Figure 32, CheapRAG exhibits remarkable

performance improvements as the model capacity increases. Notably, under the GPT-4o-mini backbone, CheapRAG achieves near-universal wins across all evaluated cases, clearly demonstrating its strong generalization ability and effectiveness.

$\triangleright$  Exp.4. More analysis. We have further analyzed the per-. metric results across different methods, and summarize the key insights as follows:

- Comprehensiveness: GGraphRAG consistently achieves the highest scores, highlighting the strength of community-level retrieval in capturing global context. By grouping semantically related content, communities help reduce fragmented evidence and support more holistic answers.

- Diversity: Both RAPTOR and GGraphRAG perform strongly by aggregating information across multiple clusters or communities. This enables the generation of responses that span diverse subtopics while maintaining relevance.

- Empowerment: GGraphRAG and LightRAG jointly lead on this metric. Their retrieval strategies incorporate structured elements—entities, relations, and keywords—that provide concrete grounding for the model to generate actionable, role-relevant responses. This better supports practical decision-making in activity-centered QA.

- Overall: GGraphRAG consistently ranks first, with RAPTOR typically second. This highlights the advantage of leveraging high-level summarized information—such as community reports and cluster-level chunks—with the former generally proving more effective. Additionally, the results support the effectiveness of the Map-Reduce mechanism in filtering out irrelevant information during retrieval.

# A.3 Evaluation metrics

This section outlines the metrics used for evaluation.

- Metrics for specific QA Tasks. We use accuracy as the evaluation metric, based on whether the gold answers appear in the model's generated outputs, rather than requiring an exact match, following the approach in [4, 57, 73]. This choice is motivated by the uncontrollable nature of LLM outputs, which often makes it difficult to achieve exact matches with standard answers. Similarly, we prefer recall over precision as it better reflects the accuracy of the generated responses.

- Metrics for abstract QA Tasks. Building on existing work, we use an LLM to generate abstract questions, as shown in Figure 34. We adopt 125 questions following the prior works, such as GraphRAG [15], LightRAG [24], and FastGraphRAG [19]. In their setup, the number 125 comes from generating  $N = 5$  user roles, each with  $N$  associated tasks, and for each (user, task) pair,  $N$  abstract questions—yielding  $5 \times 5 \times 5 = 125$  questions per dataset. We follow this standard for consistency and comparability across studies. The reasons of selecting GPT-40 are twofold: (1) at the time

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/6bedb5e1bac4342cfb5e44bf07353595ca83025b2db91346d849a9337215a284.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/a8b838d7b385d90c584fa52a9f7544898e164b97e7d3b4b768dcfd81ba0de035.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/6a5a6bbd6719540205637f3a4db916681c28c4e66d86299547ffb6241a9b72c5.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/1d694cb5cc8f43de71e670e8e66bae22e0ec71afdda7ce19a7489c56faddc888.jpg)



(d) Overall



Figure 25: The abstract QA results on the MultihopSum dataset (chunk size = 600).


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d7f7de4c0c5da6efc276fb8156f424e8579e5e5076614794fafd14398fa9ecac.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/cd462faa5f261980603235f671691e25b31d2abcfda3d8739ac50bd44b50fa7e.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/3b284214eca439e9e7150f11428c70eaa34b291db460819b2e8ae449f8337ea2.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/9c61bc839026336682379c19db7b3ebfff387f98f159d646122e976a74844e52.jpg)



(d) Overall



Figure 26: The abstract QA results on the MultihopSum dataset (chunk size = 1200).


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/a56f9dd6aa6c1fb6fa6dad55352a5aeee271842e7696ff317c7c8fd376645a0e.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8a86ea9193e4a3893880b267e7ef021f95045961f46420f652e02a801f6e1b77.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/c295e744d6c143c63b7ab2b8f0e97813106e7ed6c43c3c2f7c901ef26a415a85.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/a2372d101731a475c0fda54b8870031807046c81c65638d2186f7234df7fd217.jpg)



(d) Overall



Figure 27: The abstract QA results on the MultihopSum dataset (chunk size = 2400).


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/3d445c3eeb14631796b4fa12a7994ec28d64722f124276c8999e3ff101461ae3.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/17c6453c79a4edfbeaaeada0be976e042256f41b6a155b65dfaab00030fc8783.jpg)


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f3ef734bc17c55edf827fd3f85d2f640ebaa9bec95b6fe4eaee880b209e37cbb.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/33fdb23ddd791a32edf59bebcaaa334fef3431f25ecc8ec9873a825ed8c35b5d.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/be6c812e6bac2e7dce61f19befd0af30bd728414a6d33c28fb3d35db83c34ab8.jpg)



(d) Overall



Figure 28: Comparison of CheapRAG and other methods under different chunk sizes on the MultihopSum dataset.


when conducted our experiments, GPT-4o was one of the most advanced LLM, demonstrating strong zero-shot capabilities and superior performance in long-context understanding compared to other models, and (2) it provides the highest fluency, coherence, and factual consistency, ensuring that the generated questions are both challenging and realistic. This effectively supports our exploration of real-world data sensemaking scenarios.

Defining ground truth for abstract questions, especially those involving complex high-level semantics, presents significant challenges. To address this, we adopt an LLM-based multi-dimensional comparison method, inspired by [15, 24], which evaluates comprehensiveness, diversity, empowerment, and overall quality. We use a robust LLM, specifically GPT-4o, to rank each baseline in comparison to our method. The evaluation prompt used is shown in Figure 35. These four metrics are defined [15, 19, 24] as follows:

- Comprehensiveness. How much detail does the answer provide to cover all aspects and details of the question?

- Diversity. How varied and rich is the answer in providing different perspectives and insights on the question?

- Empowerment. How well does the answer help the reader understand and make informed judgments about the topic?

- Overall. Select an overall winner based on these categories. To better illustrate these dimensions, Figure 36 presents examples of both good and bad answers with respect to comprehensiveness, diversity, and empowerment.

Head-to-head comparison. To evaluate abstract QA tasks by head-to-head comparison using an LLM evaluator, selecting four target metrics capturing qualities that are desirable for abstract questions. The answer to an abstract question is not a collection of details from specific texts, but rather a high-level understanding of the dataset's contents relevant to the query. A good response to an abstract question should perform well across the following four metrics, including "Comprehensiveness", "Diversity", "Empowerment", and "Overall".

Head-to-head win results illustrate the relative performance among different methods. Each value indicates the percentage of test cases where the row method outperforms the column method - higher values indicate better performance. For example, Figure 37 demonstrates an example head-to-head result under the "comprehensive" dimension on the Mix dataset. The value 30 in the first row and third column indicates that VanillaRAG outperforms GGraphRAG in  $30\%$  of cases, suggesting that VanillaRAG performs

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/bca11fc595b436e8ce46dbcccad33c563baab369b14e98ea271733a4bab34668.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8b5f25d79f403a1d23ad947e702c61cb262b4fe25e22f6c3414a2ef6cafee220.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/888d1fe74e264bc3024c68eb8cec88c544724900adeeb1e229313c1a72bab861.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/26767439d4f3761bf524a63052c16d8283385557755b0c87867170439c9035ee.jpg)



(d) Overall



Figure 29: The abstract QA results on the MultihopSum dataset (LLM backbone = Qwen-2.5-32B).


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/841978427c8dac6b7529b046d22876d3e2affea3fdebb56640acbe6a1fe7cf41.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/b6d757b1e53d7ea8d1777d3d70ae376e49395f26a43bb97161950e19e2e11f01.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/63bf6783e7cec0d73fccb60183d915f36e782fb833a9059bf71d043201b4e8f1.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/846fa8fdcc2d865b8cba4661c068528f7e48e645b094f847faf5a6dc255cc5f5.jpg)



(d) Overall



Figure 30: The abstract QA results on the MultihopSum dataset (LLM backbone = Llama-3-70B).


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/8a23641adc4490f0da24d068060c46f2e6a10ca57603c2dde0ca9a303d5721e4.jpg)



(a) Comprehensiveness


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/be835f6190ee5fe31432b00203ddf07b2c05d432648a1c495459eb309d7d679c.jpg)



(b) Diversity


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/d19d21086ca3827f767299e3ff9ee7b6ea6587a5c1a9b4ec5ff77266ae73dff8.jpg)



(c) Empowerment


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/29930b3a3ec366bc06948cf1b88766634fd2740341360403d9ac8ea28cea414f.jpg)



(d) Overall



Figure 31: The abstract QA results on the MultihopSum dataset (LLM backbone = GPT-4o-mini).


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/0ea7e810fc58eebe41125063864259023a3fa5ce3b340db2c7d27a08a1e05724.jpg)



(a) LLM backbone  $=$  Llama-3-8B


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/4ccc35292996406a4810329c5a6b2094ea3e9c25af668698caa30f4672bed868.jpg)



(b) LLM backbone  $=$  Qwen-2.5-32B


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/6ac1603967642e9d15dd9d0ba4810de961dc073f575117867d2583a6bd0a2e2b.jpg)



(c) LLM backbone = Llama-3-70B


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/47dcae909596f781fd90a374f633f9cc3671745bc84c8fc857229ef5d0d4b26a.jpg)



(d) LLM backbone = GPT-4o-mini



Figure 32: Comparison of our newly designed method on MultihopSum dataset.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/6a6f8b8ef5c1918187902843f8f0fd57482618c2ad1d0bd6b4f3d4d86fe9d536.jpg)



Figure 33: Workflow of our empirical study.


worse than GGraphRAG on this metric. Based on the overall comparison in the figure, the relative ranking of the five methods is: 1. HLightRAG (LR), 2. GGraphRAG (GS), 3. VanillaRAG (VR), 4. RAPTOR (RA), 5. FastGraphRAG (FG).

# A.4 Implementation details

In this subsection, we present more details about our system implementation. Specifically, we use HNSW [56] from Llama-index [55] (a well-known open-source project) as the default vector database for efficient vector search. In addition, for each method, we optimize efficiency by batching or parallelizing operations such as encoding nodes or chunks, and computing personalized page rank, among others, during the retrieval stage.

Why Llama-3-8B? Beyond the widespread use of Llama-3-8B in existing works, our choice is further motivated by the following considerations:

(1) Strong Capability: Llama-3-8B exhibits solid language understanding and reasoning abilities [14], which are crucial for RAG workflows. Its effectiveness in integrating retrieved content with internal knowledge enables accurate and contextually relevant response generation.

(2) Practical Efficiency: The 8B variant offers a favorable tradeoff between performance and resource efficiency. It supports FP16 inference within 20 GB of GPU memory, allowing deployment on widely available hardware (e.g., a single 24 GB GPU).

(3) Open source LLM: As an open-source LLM, it can be deployed locally, saving the costs of paying for API calls required by proprietary models such as GPT-4o.

Workflow of our evaluation. We present the first open-source testbed for graph-based RAG methods, which (1) collects and reimplements 12 representative methods within a unified framework (as depicted in Section 3). (2) supports a fine-grained comparison over the building blocks of the retrieval stage with up to  $100+$  variants, and (3) provides a comprehensive evaluation over 11 datasets with various metrics in different scenarios, we summarize the workflow of our empirical study in Figure 33.

# A.5 Criteria of selection dataset

Our work aims to systematically analyze various graph-based RAG methods and provide in-depth insights. To this end, we select datasets based on the following criteria:

(1) Widely used in the existing works: All selected datasets are extensively used in the RAG and LLM research communities. For example, the HotpotQA dataset has been cited more than 2,800 times.

(2) Diverse corpus domains: Our selected datasets cover a broad range of corpus domains. For instance, MultihopRAG consists of long English news articles; HotpotQA includes short passages from Wikipedia; and Quality comprises a diverse mixture of sources such as fiction from Project Gutenberg and articles from Slate magazine, with each document containing at least 2,000 tokens. For abstract questions, we include datasets spanning various domains such as agriculture, computer science, and legal texts.

(3) Diverse in task types: Question answering (QA) tasks are typically categorized into abstract and specific questions [24], in which the specific questions can be further divided by complexity into simple and complex types [4, 72]. Specifically, simple questions typically require only one or two text chunks for an answer, without the need for multi-hop reasoning. In contrast, complex questions necessitate reasoning across multiple chunks, understanding implicit relations, and synthesizing information.

# B MORE DISCUSSIONS.

# B.1 New operators

Here, we introduce the operators that are not used in existing graph-based RAG methods but are employed in our newly designed state-of-the-art methods.

Chunk type. We include a new operator VDB of chunk type, which is used in our VGraphRAG method. This operator is the same as the chunk retrieval strategy of VanillaRAG.

Community type. We also include a new operator VDB of community type, retrieving the top- $k$  communities by vector searching, where the embedding of each community is generated by encoding its community report.

# B.2 More Lessons and Opportunities

In this subsection, we show the more lessons and opportunities learned from our study.

# Lessons

$\triangleright$  L6. For large datasets, both versions of the GraphRAG methods incur unacceptable token costs, as they contain a large number of communities, leading to high costs for generating community reports.

$\triangleright$  L7. Regardless of whether the questions are specific or abstract, they all rely on an external corpus (i.e., documents). For such questions, merely using graph-structure information (nodes, edges, or subgraphs) is insufficient to achieve good performance.

$\triangleright$  L8. Methods designed for knowledge reasoning tasks, such as DALK, ToG, and G-retriever, do not perform well on document-based QA tasks. This is because these methods are better suited for extracting reasoning rules or paths from well-constructed KGs. However, when KGs are built from raw text corpora, they may not

accurately capture the correct reasoning rules, leading to suboptimal performance in document-based QA tasks.

$\triangleright$  L9. The effectiveness of RAG methods is highly impacted by the relevance of the retrieved elements to the given question. That is, if the retrieved information is irrelevant or noisy, it may degrade the LLM's performance. When designing new graph-based RAG methods, it is crucial to evaluate whether the retrieval strategy effectively retrieves relevant information for the given question.

# Opportunities

$\triangleright$  O5. In real applications, external knowledge sources are not limited to text corpora; they may also include PDFs, HTML pages, tables, and other structured or semi-structured data. A promising future research direction is to explore graph-based RAG methods for heterogeneous knowledge sources.

$\triangleright$  O6. An interesting future research direction is to explore more graph-based RAG applications. For example, applying graph-based RAG to scientific literature retrieval can help researchers efficiently extract relevant studies and discover hidden relationships between concepts. Another potential application is legal document analysis, where graph structures can capture case precedents and legal interpretations to assist in legal reasoning.

$\triangleright$  O7. The users may request multiple questions simultaneously, but existing graph-based RAG methods process them sequentially. Hence, a promising future direction is to explore efficient scheduling strategies that optimize multi-query handling. This could involve batching similar questions or parallelizing retrieval.

$\triangleright$  O8. Different types of questions require different levels of information, yet all existing graph-based RAG methods rely on fixed, predefined rules. How to design an adaptive mechanism that can address these varying needs remains an open question.

$\triangleright$  O9. Existing methods do not fully leverage the graph structure; they typically rely on simple graph patterns (e.g., nodes, edges, or  $k$ -hop paths). Although GraphRAG adopts a hierarchical community structure (detecting by the Leiden algorithm), this approach does not consider node attributes, potentially compromising the quality of the communities. That is, determining which graph structures are superior remains an open question.

$\triangleright$  O10. The well-known graph database systems, such as Neo4j [61] and Nebula [60], support transferring the corpus into a knowledge graph via LLM. However, enabling these popular systems to support the diverse operators required by various graph-based RAG methods presents an exciting opportunity.

# B.3 Benefit of our framework

Our framework offers exceptional flexibility by enabling the combination of different methods at various stages. This modular design allows different algorithms to be seamlessly integrated, ensuring that each stage—such as graph building, and retrieval&generation—can be independently optimized and recombined. For example, methods like HippoRAG, which typically rely on KG, can easily be adapted to use RKG instead, based on specific domain needs.

In addition, our operator design allows for simple modifications—often just a few lines of code—to create entirely new graph-based RAG methods. By adjusting the retrieval stage or swapping components, researchers can quickly test and implement new strategies, significantly accelerating the development cycle of graph-based RAG methods.

The modular nature of our framework is further reinforced by the use of retrieval elements (such as node, relationship, or subgraph)

coupled with retrieval operators. This combination enables us to easily design new operators tailored to specific tasks. For example, by modifying the strategy for retrieving given elements, we can create customized operators that suit different application scenarios.

By systematically evaluating the effectiveness of various retrieval components under our unified framework, we can identify the most efficient combinations of graph construction, indexing, and retrieval strategies. This approach enables us to optimize retrieval performance across a range of use cases, allowing for both the enhancement of existing methods and the creation of novel, state-of-the-art techniques.

Finally, our framework contributes to the broader research community by providing a standardized methodology to assess graph-based RAG approaches. The introduction of a unified evaluation testbed ensures reproducibility, promotes fair a benchmark, and facilitates future innovations in RAG-based LLM applications.

# B.4 Limitations

In our empirical study, we put considerable effort into evaluating the performance of existing graph-based RAG methods from various angles. However, our study still has some limitations, primarily due to resource constraints. (1) Token Length Limitation: The primary experiments are conducted using Llama-3-8B with a token window size of 8k. This limitation on token length restricted the model's ability to process longer input sequences, which could potentially impact the overall performance of the methods, particularly in tasks that require extensive context. Larger models with larger token windows could better capture long-range dependencies and deliver more robust results. This constraint is a significant factor that may affect the generalizability of our findings. (2) Limited Knowledge Datasets: Our study did not include domain-specific knowledge datasets, which are crucial for certain applications. Incorporating such datasets could provide more nuanced insights and allow for a better evaluation of how these methods perform in specialized settings. (3) Resource Constraints: Due to resource limitations, the largest model we utilized is Llama-3-70B, and the entire paper consumes nearly 10 billion tokens. Running larger models, such as GPT-4o (175B parameters or beyond), would incur significantly higher costs, potentially reaching several hundred thousand dollars depending on usage. While we admit that introducing more powerful models could further enhance performance, the 70B model is already a strong choice, balancing performance and resource feasibility. That is to say, exploring the potential of even larger models in future work could offer valuable insights and further refine the findings. (4) Prompt Sensitivity: The performance of each method is highly affected by its prompt design. Due to resource limitations, we did not conduct prompt ablation studies and instead used the available prompts from the respective papers. Actually, a fairer comparison would mitigate this impact by using prompt tuning tools, such as DSPy [38], to customize the prompts and optimize the performance of each method.

These limitations highlight areas for future exploration, and overcoming these constraints would enable a more thorough and reliable evaluation of graph-based RAG methods, strengthening the findings and advancing the research.

# B.5 Necessity of chunk splitting in RAG systems

Splitting the input corpus into smaller chunks is a necessary step for all RAG methods, including both non-graph and graph-based variants. The reasons can be summarized in three aspects below:

(1) Input length limit of LLMs. Every LLM has its own input length limitation. For example, ChatGPT-3.5 supports up to 4,096 tokens, while Llama-3-8B allows up to 8,192 tokens. A token is a basic unit of text (roughly a word or subword). However, real-world corpora often contain tens of thousands to millions of tokens—e.g., the ALCE dataset exceeds 13 million tokens—far beyond the processing capability of any existing LLM. Therefore, it is essential to split the corpus into smaller chunks.

(2) Relevance filtering and noise reduction. Even if the full corpus could fit into the LLM, chunking is still necessary because most queries only relate to a small part of the content. That is, given a query  $Q$ , inputting the entire corpus into the LLM introduces unnecessary noise. To alleviate this, RAG systems retrieve only the top- $k$  relevant chunks, which helps filter out irrelevant content and improves both accuracy and efficiency.

(3) Graph construction in graph-based RAG. Chunking is equally essential and plays a critical role in all graph-based RAG methods. Below, we outline how different types of graphs rely on chunking:

- Knowledge graph (KG), Textual Knowledge graph (TKG), and Rich Knowledge graph (RKG): These graphs use LLMs to extract entities and relationships from the input corpus. Due to the token limitation of the LLM, the corpus must first be split into chunks. The LLM is then applied independently to each chunk, and the resulting outputs are aggregated to construct the complete graph. This follows a divide-and-conquer paradigm.

- Passage graph (PG): In the passage graph, each chunk is treated as a node, and an edge is added between two nodes if their corresponding chunks share at least a certain number of common entities. The graph is constructed by comparing entity overlap across all pairs of chunks.

In summary, chunking is not only necessary due to token limits but also integral to the design of RAG systems.

# B.6 Comparison of graphs and indices

Indeed, it is difficult to define a single "best" graph, as each type of graph has its own advantages and disadvantages. To help clarify this, we summarize the key characteristics of each graph type in Table 19. For example, although tree can be constructed with minimal cost, it carries limited information. Methods such as RAPOTR, which are based on tree, demonstrate competitive performance under lightweight settings. However, they may fall short in complex QA and abstract QA tasks due to limited semantic coverage. In contrast, methods such as VGraphRAG and GGraphRAG, which are built upon TKG, benefit from richer entity and relationship representations. This enhanced expressiveness enables more accurate reasoning in information-intensive tasks. However, these advantages come at the cost of increased token consumption and longer construction time. Additionally, while PG avoids token usage during construction, it incurs significant time overhead due to exhaustive pairwise chunk comparisons.

# Prompt for generating abstract questions

# Prompt:

Given the following description of a dataset:

{description}

Please identify 5 potential users who would engage with this dataset. For each user, list 5 tasks they would perform with this dataset. Then, for each (user, task) combination, generate 5 questions that require a high-level understanding of the entire dataset.

Output the results in the following structure:

- User 1: [user description]

- Task 1: [task description]

-Question1:

-Question2:

-Question3:

-Question4:

-Question5:

- Task 2: [task description]

- Task 5: [task description]

- User 2: [user description]

- User 5: [user description]

Note that there are 5 users and 5 tasks for each user, resulting in 25 tasks in total. Each task should have 5 questions, resulting in 125 questions in total. The Output should present the whole tasks and questions for each user.

Output:

Figure 34: The prompt for generating abstract questions.


Table 19: Comparison of different types of graph.


<table><tr><td>Graph</td><td>Entity Name</td><td>Entity Type</td><td>Entity Description</td><td>Relationship Name</td><td>Relationship Keyword</td><td>Relationship Description</td><td>Edge Weight</td><td>Token Consuming</td><td>Graph Size</td><td>Information Richness</td><td>Construction Time</td></tr><tr><td>Tree</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>★</td><td>★</td><td>★★</td><td>★</td></tr><tr><td>PG</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>✘</td><td>N/A</td><td>★★★</td><td>★</td><td>★★★</td></tr><tr><td>KG</td><td>✓</td><td>✘</td><td>✘</td><td>✓</td><td>✘</td><td>✘</td><td>✓</td><td>★★</td><td>★★</td><td>★★★</td><td>★★</td></tr><tr><td>TKG</td><td>✓</td><td>✓</td><td>✓</td><td>✘</td><td>✘</td><td>✓</td><td>✓</td><td>★★★</td><td>★★★</td><td>★★★</td><td>★★★</td></tr><tr><td>RKG</td><td>✓</td><td>✓</td><td>✓</td><td>✘</td><td>✓</td><td>✓</td><td>✓</td><td>★★★</td><td>★★★</td><td>★★★★★</td><td>★★★</td></tr></table>


Table 20: Comparison of different types of index.


<table><tr><td>Index</td><td>Index Size</td><td>Token Consuming</td><td>Construction Time</td></tr><tr><td>Node Index</td><td>★★</td><td>N/A</td><td>★</td></tr><tr><td>Relationship Index</td><td>★★★</td><td>N/A</td><td>★★</td></tr><tr><td>Community Index</td><td>★</td><td>★★★★</td><td>★★★★</td></tr></table>

Similar to the comparison of graphs, it is also challenging to identify a universally "best" index. Instead, we summarize the characteristics of different indices in Table 20. We can see that the relationship index tends to have a larger size, whereas the community index is more compact but incurs the highest construction cost in terms of tokens and time. Indeed, in our experiments, we report the token costs associated with constructing the community index for each dataset. Notably, for some datasets, such as HotpotQA and ALCE, this cost is comparable to that of building the graph itself, exceeding  $10^{8}$  tokens. Despite their differences, all indices share a

common goal of facilitating fast and effective retrieval within graph-based RAG systems. The selection of a specific index should align with the retrieval strategy and the demands of the downstream QA task. For instance, to answer abstract questions that rely on some high-level summaries, it is better to use the community-based indexes (e.g., the index of GraphRAG) to retrieve relevant information since they often provide the summary reports for the communities.

# B.7 Relevance to the data management community

We agree that graph-based RAG is very relevant to the information retrieval and NLP communities, but we also believe that it is highly relevant to the graph data management community, since it has received growing interest from both industry and academia. In the industrial area, Ant-Group recently proposed Chat2Graph [6], a graph-native agent system that incorporates graph-based RAG as a core component. Similarly, modern graph database systems such as

# Prompt for LLM-based multi-dimensional comparison

# Prompt:

You will evaluate two answers to the same question based on three criteria: Comprehensiveness, Diversity, Empowerment, and Directness.

- Comprehensiveness: How much detail does the answer provide to cover all aspects and details of the question?

- Diversity: How varied and rich is the answer in providing different perspectives and insights on the question?

- Empowerment: How well does the answer help the reader understand and make informed judgments about the topic?

- Directness: How specifically and clearly does the answer address the question?

For each criterion, choose the better answer (either Answer 1 or Answer 2) and explain why. Then, select an overall winner based on these four categories.

# Here is the question:

Question: {query}

Here are the two answers:

Answer 1: {answer1}

Answer 2: {answer2}

Evaluate both answers using the four criteria listed above and provide detailed explanations for each criterion. Output your evaluation in the following JSON format:

```txt
{ "Comprehensiveness": { "Winner": ["Answer 1 or Answer 2"], "Explanation": ["Provide one sentence explanation here"] }, "Diversity": { "Winner": ["Answer 1 or Answer 2"], "Explanation": ["Provide one sentence explanation here"] }, "Empowerment": { "Winner": ["Answer 1 or Answer 2"], "Explanation": ["Provide one sentence explanation here"] }, "Overall Winner": { "Winner": ["Answer 1 or Answer 2"], "Explanation": ["Briefly summarize why this answer is the overall winner"] }   
}   
Output:
```

Figure 35: The prompt for the evaluation of abstract QA.

Neo4j [62], NebulaGraph [60], and PostgreSQL [68] are beginning to support graph-based RAG methods, further reinforcing the growing intersection between AI and graph data management. In the academia area, interest in RAG is also rising within the data management field, as demonstrated by recent work such as Chameleon [36] (VLDB 2025) and Cache-Craft [2] (SIGMOD 2025).

The core retrieval stage in graph-based RAG systems can be naturally framed as a query optimization process over graph databases, where the goal is to identify the most relevant subgraphs, paths, nodes, or relationships from a large graph  $G$  given a natural language query  $Q$ . This introduces new challenges for graph query processing and indexing, as many modern graph databases lack native support for the complex retrieval operators required by

graph-based RAG workflows. For instance, while retrieving  $k$ -hop neighbors is commonly supported, operators such as efficiently identifying communities containing specific entities, computing Steiner trees, or finding  $k$ -hop semantically relevant paths to the query  $Q$  remain largely unsupported. Moreover, retrieval operators that rely on LLM-based reasoning or semantic similarity are fundamentally beyond the capabilities of existing graph data systems. Our work highlights these limitations and identifies opportunities for extending graph databases to such operators over large graph data—an emerging direction highly relevant to the graph data management community.

Lastly, our work has garnered significant attention from both academic and industrial areas. Our open-source project has attracted

Question: How do the syntactic and semantic differences between functional and object-oriented paradigms affect program design?

# Responses of different methods

# Comprehensiveness:

$\triangleright$  Why it matters: A comprehensive answer should mention key differences and explain their design implications.

$\triangleright$  Comprehensive Answer: Functional programming emphasizes pure functions, immutability, and recursion, reducing side effects and improving testability. Object-oriented programming (OOP) uses classes, encapsulation, and mutable state, supporting modularity and reuse. These paradigms shape program design in syntax (e.g., method chaining vs. composition) and semantics (e.g., stateful vs. stateless logic). For example, FP promotes declarative flows and better concurrency, while OOP mirrors real-world models. Understanding both helps in choosing suitable architecture patterns.

Incomprehensive Answer: Functional programming focuses on using functions, and object-oriented programming uses objects and classes. These differences change how you write code, but both are just different ways to program. Most people use OOP because it's more common. Functional programming is used sometimes, but not always necessary. It depends on what you're doing, but overall, they just represent two styles.

$\triangleright$  Explanation: The second response omits key distinctions like mutability and side effects, and lacks detail on how such differences influence program structure or architecture.

# Diversity:

$\triangleright$  Why it matters: A diverse answer should present multiple angles, use cases, and comparisons.

$\triangleright$  Diverse Answer: Functional and object-oriented paradigms differ across many dimensions. Syntactically, FP uses higher-order functions and expressions, while OOP relies on method calls and class hierarchies. Semantically, FP enforces immutability and stateless computation, whereas OOP supports encapsulated state and side effects. These lead to varied design strategies: FP suits parallel computation, mathematical modeling, and data transformation; OOP works well for user interfaces, simulations, and domain modeling. Hybrid designs are also common in modern software.

$\triangleright$  Low Diversity Answer: Functional programming is good for parallelism because it doesn't use shared state. Object-oriented programming helps organize code using classes. In general, most developers stick to OOP because it's easier and more practical. Functional programming is more theoretical. While they work differently, the main thing to know is that functional is more mathematical, and object-oriented is more practical for apps.

$\triangleright$  Explanation: The second answer focuses on only one or two differences and lacks variety in perspectives, missing concrete use cases and deeper design implications.

# Empowerment

$\triangleright$  Why it matters: An empowering answer helps readers apply the concepts to make better design decisions.

$\triangleright$  Empowerment Answer: Understanding the core trade-offs between functional and object-oriented paradigms equips developers to design more robust systems. For instance, choosing functional principles like immutability can minimize bugs in concurrent applications. OOP's modeling of real-world entities simplifies maintenance in large systems. Awareness of these options enables informed architectural decisions, such as using a functional core within an object-oriented shell. This empowers developers to select the right paradigm or blend based on project needs.

$\triangleright$  Low Empowerment Answer: Object-oriented programming is the standard approach, so you should usually stick to that. Functional programming is more academic and harder to understand. Unless you're working on something very technical, like machine learning or math-heavy software, it's not really useful. Most beginners don't need to worry about it. Just learn OOP and you'll be fine for most jobs or projects.

$\triangleright$  Explanation: The second answer discourages understanding by dismissing functional programming as impractical, instead of helping the reader see when and why each paradigm is appropriate.

Figure 36: Representative good and bad answers across three evaluation dimensions. Cyan italics highlight informative content in good answers; gray italics indicate vague or unhelpful points in bad answers.


VanillaRAG outperforms GGraphRAG on  $30\%$  of cases


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/4a820b8f0d4adb4f01f246aef426248f456af56976fc158aeb3551bbe2fbdcf4.jpg)



Figure 37: An example head-to-head comparison result.


significant attention (e.g., 1.3k+ GitHub stars $^{1}$ ) and has been successfully adopted by Huawei Cloud for domain-specific QA, thanks to its modular architecture and ability to handle complex retrieval workflows efficiently. In summary, as noted in the meta-review, we believe that with the increasing importance of graphs and the growing adoption of AI techniques such as RAG, it is both timely and relevant to the graph data management community.

# B.8 More examples

- An example of building graph. As shown in Figure 38, we consider a corpus from the IT domain, which is segmented into six chunks. We then illustrate how to construct different types of graphs based on this corpus:

- Tree: We first apply the Gaussian Mixture clustering algorithm to group the six chunks into two clusters: (chunk 1, chunk 2, chunk 3) and (chunk 4, chunk 5, chunk 6). Each cluster forms a parent node in the second layer, where an LLM is used to summarize the content of all associated chunks. These two parent nodes are then clustered into a single root node (third layer), whose content is also summarized via LLM. The resulting structure is a three-layer tree with 6 leaf nodes (original chunks), 2 intermediate cluster nodes, and 1 root node.

- Passage Graph: We construct a passage graph where each chunk is treated as a node, and an edge is added between two nodes if their corresponding chunks share at least  $\tau$  common entities. For example, an edge is added between chunk 4 and chunk 6 since they both contain the same entities, e.g., "ChatGPT" and "OpenAI".

- Knowledge Graph: We use an LLM to extract entity-relation triples from each chunk. Each entity includes a name, while each relationship is represented by a name and an associated weight indicating how frequently it appears within the given chunk. For example, from chunk 1, we extract the entity "Elon Musk" and its relationship "Founder of".

- Textural & Rich Knowledge Graph: The two types of graphs are constructed in a similar way: for each chunk, we use an LLM to extract entities and their relationships. Each entity is represented with three attributes—name, type, and description—while each relationship includes a name, description, and weight. The key difference lies in that the Rich Knowledge Graph further annotates each relationship with a set of keywords, providing more semantic cues for retrieval.

- Details of operators. Specifically, we abstract three operators under the Chunk type: ① Aggregator, ② FromRel, and ③ Occurrence.

- Aggregator: This operator relies on two matrices: a score vector  $\mathcal{R} \in \mathbb{R}^{1 \times m}$  and an interaction matrix  $\mathcal{M} \in \mathbb{R}^{m \times c}$ , where  $m$  is the number of relationships and  $c$  is the number of chunks. Specifically, the  $i$ -th entry in  $\mathcal{R}$  represents the score of the  $i$ -th relationship, while  $\mathcal{M}_{i,j} = 1$  if the  $i$ -th relationship is extracted from the  $j$ -th chunk, and 0 otherwise. Afterwards, the aggregated score of each chunk is computed via matrix multiplication:

$$
\Psi = \mathcal {R} \times \mathcal {M},
$$

where each entry in  $\Psi \in \mathbb{R}^{1\times c}$  represents the aggregated relationship score of a chunk. Based on  $\Psi$ , the top- $k$  chunks with the highest scores are selected for retrieval.

- FromRel: For each relationship in the graph, we maintain a mapping to the set of chunks from which it is extracted. This allows us to efficiently retrieve relevant chunks given a set of relationships by computing the union of all chunks associated with these relationships.

- Occurrence: For every relationship, we identify its two associated entities. For each entity, we maintain a mapping to the set of chunks from which it is extracted, since an entity can appear in multiple chunks. If a chunk contains both entities of a given relationship, its score (initially set to 0) is incremented by 1. After processing all relationships, we obtain a score for each chunk, and select the top- $k$  chunks based on these scores.

Besides, there are two operators under the Community type: 1 Entity, and 2 Layer:

- Entity: This operator retrieves communities that contain the specified entities. Each community maintains a list of associated entities. Retrieved communities are then ranked based on their relevance scores (generated by the LLM), and the top- $k$  communities are returned.

- Layer: In GGraphRAG, communities are detected using the Leiden algorithm, resulting in a hierarchical structure where higher layers represent more abstract and coarse-grained information. The Layer operator retrieves all communities at or below a specified layer, allowing access to more fine-grained community information.

- An example of Map-Reduce strategy. In the Map-Reduce phase of GGraphRAG, each retrieved community is individually used to answer the question. Specifically, for each community, the LLM is prompted to generate a partial answer along with a confidence score (ranging from 0 to 100), reflecting how well the community summary addresses the query. After processing all communities, we obtain a set of partial answers, each represented as a pair: (answer, score). These partial answers are then ranked in descending order by score and sequentially appended to the prompt for final answer generation. We also provide an example to illustrate this.

EXAMPLE 1. Figure 39 illustrates how the partial answers are generated and used in GGraphRAG. Consider an abstract question: "What are the socio-economic impacts of artificial intelligence on the global labor market?" In this example, three communities are retrieved, and GGraphRAG generates partial answers from each one. For instance, using the first community, it produces a partial answer discussing the impact of AI on the job landscape, which receives a relevance score of

![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/afbbafe0d7203a2b41ca1a3dd1f017e8e0d9bff4bb21ba417e484c674ebc32d2.jpg)



Figure 38: Examples of five types of graphs.


![image](https://cdn-mineru.openxlab.org.cn/result/2026-01-15/08522393-17b6-4925-a2fb-b1b5bf259c8d/f3a544e4f074fdc039630589b9731ac81a9be2c4307bfcc7211f394aa8429a27.jpg)



Figure 39: An illustrative example of GGraphRAG's Map-Reduce generation process. The analysis presents partial answers derived from each community, with the portions incorporated into the final answer highlighted in green.


85. These partial answers are then aggregated, allowing GGraphRAG to generate a final, comprehensive response.