#模型下载
# from modelscope import snapshot_download
# model_dir = snapshot_download('LLM-Research/Meta-Llama-3-8B-Instruct', cache_dir='/root/model')
# print(f"模型下载完成，保存路径：{model_dir}")

from modelscope import snapshot_download
model_dir = snapshot_download('BAAI/bge-m3', cache_dir='/root/model')
print(f"模型下载完成，保存路径：{model_dir}")