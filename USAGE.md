1. 部署vllm
```sh
./start_services.sh
```

2. 运行数据集
```sh
/root/anaconda3/envs/rag/bin/python main.py -opt Option/Method/RAPTOR.yaml -dataset_name hotpotqa
```