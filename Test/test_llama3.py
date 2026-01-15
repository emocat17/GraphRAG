import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
import os

# Model path
model_id = "/root/model/LLM-Research/Meta-Llama-3-8B-Instruct"

def test_model():
    # Check if model path exists
    if not os.path.exists(model_id):
        print(f"Error: Model path '{model_id}' does not exist.")
        return

    print(f"Loading model from {model_id}...")
    try:
        # Load tokenizer
        tokenizer = AutoTokenizer.from_pretrained(model_id)
        
        # Load model
        # using bfloat16 for efficiency if supported, otherwise float16 or float32
        dtype = torch.bfloat16 if torch.cuda.is_bf16_supported() else torch.float16
        
        model = AutoModelForCausalLM.from_pretrained(
            model_id,
            dtype=dtype,
            # device_map="auto", # Requires accelerate, removing to avoid dependency
        )
        
        # Manually move model to device
        device = "cuda" if torch.cuda.is_available() else "cpu"
        print(f"Moving model to {device}...")
        model.to(device)
        
        # Set pad_token_id to eos_token_id if not set, to avoid warnings
        if tokenizer.pad_token_id is None:
            tokenizer.pad_token_id = tokenizer.eos_token_id
            model.config.pad_token_id = tokenizer.eos_token_id

    except Exception as e:
        print(f"Error loading model: {e}")
        print("Ensure 'transformers', 'torch', and 'accelerate' are installed.")
        return

    # Prepare input
    messages = [
        {"role": "system", "content": "You are a helpful AI assistant."},
        {"role": "user", "content": "Hello! Can you introduce yourself?"},
    ]

    # Apply chat template
    try:
        input_ids = tokenizer.apply_chat_template(
            messages,
            add_generation_prompt=True,
            return_tensors="pt"
        ).to(model.device)
    except AttributeError:
        # Fallback if apply_chat_template is not available or model config issue
        print("Warning: apply_chat_template failed, using simple text input.")
        text = "System: You are a helpful AI assistant.\nUser: Hello! Can you introduce yourself?\nAssistant:"
        input_ids = tokenizer(text, return_tensors="pt").input_ids.to(model.device)

    terminators = [
        tokenizer.eos_token_id,
        tokenizer.convert_tokens_to_ids("<|eot_id|>")
    ]

    print("Generating response...")
    with torch.no_grad():
        outputs = model.generate(
            input_ids,
            attention_mask=input_ids.ne(tokenizer.pad_token_id), # Explicitly set attention mask
            max_new_tokens=256,
            eos_token_id=terminators,
            do_sample=True,
            temperature=0.6,
            top_p=0.9,
            pad_token_id=tokenizer.pad_token_id, # Ensure pad_token_id is passed
        )

    # Decode and print response
    response = outputs[0][input_ids.shape[-1]:]
    print("-" * 20)
    print(tokenizer.decode(response, skip_special_tokens=True))
    print("-" * 20)

if __name__ == "__main__":
    test_model()
