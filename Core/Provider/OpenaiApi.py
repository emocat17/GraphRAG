from __future__ import annotations

import numpy as np
from typing import Optional, Union
import asyncio
import tiktoken

from openai import APIConnectionError, AsyncOpenAI, AsyncStream
from openai._base_client import AsyncHttpxClientWrapper
from openai.types import CompletionUsage
from openai.types.chat import ChatCompletion, ChatCompletionChunk
from tenacity import (
    after_log,
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_random_exponential,
)

from Config.LLMConfig import LLMConfig, LLMType
from Core.Common.Constants import USE_CONFIG_TIMEOUT
from Core.Common.Logger import log_llm_stream, logger
from Core.Provider.BaseLLM import BaseLLM
from Core.Provider.LLMProviderRegister import register_provider
from Core.Common.Utils import  log_and_reraise,prase_json_from_response
from Core.Common.CostManager import CostManager
from Core.Utils.Exceptions import handle_exception
from Core.Utils.TokenCounter import (
    count_input_tokens,
    count_output_tokens,
    get_max_completion_tokens,
)


@register_provider(
    [
        LLMType.OPENAI,
        LLMType.FIREWORKS,
        LLMType.OPEN_LLM,
    ]
)
class OpenAILLM(BaseLLM):
    """Check https://platform.openai.com/examples for examples"""

    def __init__(self, config: LLMConfig):
        self.config = config
        self._init_client()
        self.auto_max_tokens = False
        self.cost_manager: Optional[CostManager] = None
        self.semaphore = asyncio.Semaphore(config.max_concurrent)
    def _init_client(self):
        """https://github.com/openai/openai-python#async-usage"""
        self.model = self.config.model  # Used in _calc_usage & _cons_kwargs
        self.pricing_plan = self.config.pricing_plan or self.model
        kwargs = self._make_client_kwargs()
        self.aclient = AsyncOpenAI(**kwargs)

    def _make_client_kwargs(self) -> dict:
        kwargs = {"api_key": self.config.api_key, "base_url": self.config.base_url}

        # to use proxy, openai v1 needs http_client
        if proxy_params := self._get_proxy_params():
            kwargs["http_client"] = AsyncHttpxClientWrapper(**proxy_params)

        return kwargs

    def _get_proxy_params(self) -> dict:
        params = {}
        if self.config.proxy:
            params = {"proxies": self.config.proxy}
            if self.config.base_url:
                params["base_url"] = self.config.base_url

        return params

    async def _achat_completion_stream(self, messages: list[dict], timeout=USE_CONFIG_TIMEOUT, max_tokens = None) -> str:
        response: AsyncStream[ChatCompletionChunk] = await self.aclient.chat.completions.create(
            **self._cons_kwargs(messages, timeout=self.get_timeout(timeout), max_tokens = max_tokens), stream=True
        )
        usage = None
        collected_messages = []
        has_finished = False
        async for chunk in response:
            chunk_message = chunk.choices[0].delta.content or "" if chunk.choices else ""  # extract the message
            finish_reason = (
                chunk.choices[0].finish_reason if chunk.choices and hasattr(chunk.choices[0], "finish_reason") else None
            )
            log_llm_stream(chunk_message)
            collected_messages.append(chunk_message)
            chunk_has_usage = hasattr(chunk, "usage") and chunk.usage
            if has_finished:
                # for oneapi, there has a usage chunk after finish_reason not none chunk
                if chunk_has_usage:
                    usage = CompletionUsage(**chunk.usage) if isinstance(chunk.usage, dict) else chunk.usage
            if finish_reason:
                if chunk_has_usage:
                    # Some services have usage as an attribute of the chunk, such as Fireworks
                    if isinstance(chunk.usage, CompletionUsage):
                        usage = chunk.usage
                    else:
                        usage = CompletionUsage(**chunk.usage)
                elif hasattr(chunk.choices[0], "usage"):
                    # The usage of some services is an attribute of chunk.choices[0], such as Moonshot
                    usage = CompletionUsage(**chunk.choices[0].usage)
                has_finished = True

        log_llm_stream("\n")
        full_reply_content = "".join(collected_messages)
        if not usage:
            # Some services do not provide the usage attribute, such as OpenAI or OpenLLM
            usage = self._calc_usage(messages, full_reply_content)

        self._update_costs(usage)
        return full_reply_content

    def _cons_kwargs(self, messages: list[dict], timeout=USE_CONFIG_TIMEOUT, max_tokens = None, **extra_kwargs) -> dict:
        kwargs = {
            "messages": messages,
            "max_tokens": self._get_max_tokens(messages),
            # "n": 1,  # Some services do not provide this parameter, such as mistral
            "stop": ["[/INST]", "<<SYS>>"] ,  # default it's None and gpt4-v can't have this one
            "temperature": self.config.temperature,
            "model": self.model,
            "timeout": self.get_timeout(timeout),
        }
        if "o1-" in self.model:
            # compatible to openai o1-series
            kwargs["temperature"] = 1
            kwargs.pop("max_tokens")
        if max_tokens != None:
            kwargs["max_tokens"] = max_tokens
        
        # FIX: Llama-3-8B Context Window Overflow
        # Error: 'max_tokens' (4096) > 8192 - input_tokens (e.g. 4832)
        # We need to dynamically adjust max_tokens if the input is too long.
        if "Llama-3-8B" in self.model:
             # Calculate approximate input tokens to adjust max_tokens
             try:
                 from Core.Utils.TokenCounter import count_input_tokens
                 input_tokens = count_input_tokens(messages, self.model)
                 model_max_context = 8192
                 safe_buffer = 100 # Buffer for safety
                 min_output_tokens = 512 # Ensure at least some output
                 
                 # 1. First check if we can just reduce max_tokens
                 available_for_output = model_max_context - input_tokens - safe_buffer
                 current_max_tokens = kwargs.get("max_tokens", 4096)
                 
                 if available_for_output < current_max_tokens:
                     if available_for_output >= min_output_tokens:
                         # Case 1: Input fits, but output needs reduction
                         logger.warning(f"Adjusting max_tokens from {current_max_tokens} to {available_for_output} for Llama-3-8B.")
                         kwargs["max_tokens"] = available_for_output
                     else:
                         # Case 2: Input is too long, need to truncate input
                         # NOTE: Splitting logic is handled in acompletion_text, but we keep this as a fallback/warning
                         # If we reach here, it means splitting didn't happen or wasn't enough?
                         # Actually, we should rely on acompletion_text for splitting.
                         # If we are here, we just clamp to min_output_tokens to avoid API error,
                         # assuming the input might still be processed or fail gracefully.
                         logger.warning(f"Input tokens {input_tokens} exceed limit. Splitting should have happened. Clamping max_tokens.")
                         kwargs["max_tokens"] = min_output_tokens
             except Exception as e:
                 logger.warning(f"Failed to calculate token count for dynamic adjustment: {e}")

        if extra_kwargs:
            kwargs.update(extra_kwargs)
        return kwargs

    async def _achat_completion(self, messages: list[dict], timeout=USE_CONFIG_TIMEOUT, max_tokens = None) -> ChatCompletion:
        kwargs = self._cons_kwargs(messages, timeout=self.get_timeout(timeout), max_tokens=max_tokens)

        rsp: ChatCompletion = await self.aclient.chat.completions.create(**kwargs)
        self._update_costs(rsp.usage)
        return rsp

    async def acompletion(self, messages: list[dict], timeout=USE_CONFIG_TIMEOUT) -> ChatCompletion:
        return await self._achat_completion(messages, timeout=self.get_timeout(timeout))

    @retry(
        wait=wait_random_exponential(min=1, max=60),
        stop=stop_after_attempt(6),
        after=after_log(logger, logger.level("WARNING").name),
        retry=retry_if_exception_type(Exception),
        retry_error_callback=log_and_reraise,
    )
    async def acompletion_text(self, messages: list[dict], stream=False, timeout=USE_CONFIG_TIMEOUT, max_tokens = None, format = "text") -> str:
        """when streaming, print each token in place."""
        # FIX: Handle Long Input by Splitting for Llama-3-8B
        if "Llama-3-8B" in self.model:
            try:
                from Core.Utils.TokenCounter import count_input_tokens
                input_tokens = count_input_tokens(messages, self.model)
                model_max_context = 8192
                safe_buffer = 100
                min_output_tokens = 512 # Reserve for output
                
                # If input + min_output > context, we need to split
                if input_tokens + min_output_tokens + safe_buffer > model_max_context:
                    logger.warning(f"Input tokens {input_tokens} exceed context limit. Splitting input into chunks...")
                    
                    # 1. Identify User Message (usually the long one)
                    user_msg_idx = -1
                    for i, msg in enumerate(messages):
                        if msg["role"] == "user":
                            user_msg_idx = i
                            break
                    
                    if user_msg_idx != -1:
                        # 2. Calculate chunk size
                        # We need to subtract system prompt tokens from available space
                        # To keep it simple, we assume system prompt is small and just use a safe chunk size.
                        # 6000 tokens for input chunk seems safe (leaves ~2k for system + output)
                        chunk_size = 6000 
                        
                        import tiktoken
                        enc = tiktoken.get_encoding("cl100k_base")
                        content = messages[user_msg_idx]["content"]
                        tokenized_content = enc.encode(content)
                        
                        # 3. Split content
                        chunks = []
                        for i in range(0, len(tokenized_content), chunk_size):
                            chunk_tokens = tokenized_content[i : i + chunk_size]
                            chunks.append(enc.decode(chunk_tokens))
                        
                        logger.info(f"Split user message into {len(chunks)} chunks.")
                        
                        # 4. Process each chunk
                        full_response = ""
                        for idx, chunk_content in enumerate(chunks):
                            logger.info(f"Processing chunk {idx+1}/{len(chunks)}...")
                            # Construct new messages list for this chunk
                            chunk_messages = messages.copy() # Shallow copy is fine
                            chunk_messages[user_msg_idx] = {"role": "user", "content": chunk_content}
                            
                            # Call API for this chunk
                            if stream:
                                chunk_response = await self._achat_completion_stream(chunk_messages, timeout=self.get_timeout(timeout), max_tokens=max_tokens)
                            else:
                                rsp = await self._achat_completion(chunk_messages, timeout=self.get_timeout(timeout), max_tokens=max_tokens)
                                chunk_response = self.get_choice_text(rsp)
                            
                            full_response += chunk_response + "\n" # Append with newline
                        
                        if format == "json":
                             # Attempt to merge JSONs? Or just return concatenated string?
                             # For now, just return concatenated string, let caller handle.
                             # If caller expects valid JSON, this might break. 
                             # But usually splitting implies extraction, where results are lists.
                             return full_response 
                        
                        return full_response

            except Exception as e:
                logger.error(f"Failed to split input: {e}. Proceeding with original input.")

        if stream:
            return await self._achat_completion_stream(messages, timeout=timeout, max_tokens = max_tokens)

        rsp = await self._achat_completion(messages, timeout=self.get_timeout(timeout), max_tokens = max_tokens)

        rsp_text = self.get_choice_text(rsp)
        if format == "json":
            return prase_json_from_response(rsp_text)
        return rsp_text


 

    def get_choice_text(self, rsp: ChatCompletion) -> str:
        """Required to provide the first text of choice"""
        return rsp.choices[0].message.content if rsp.choices else ""

    def _calc_usage(self, messages: list[dict], rsp: str) -> CompletionUsage:
        usage = CompletionUsage(prompt_tokens=0, completion_tokens=0, total_tokens=0)
        if not self.config.calc_usage:
            return usage

        try:
            usage.prompt_tokens = count_input_tokens(messages, self.pricing_plan)
            usage.completion_tokens = count_output_tokens(rsp, self.pricing_plan)
        except Exception as e:
            logger.warning(f"usage calculation failed: {e}")

        return usage

    def _get_max_tokens(self, messages: list[dict]):
        if not self.auto_max_tokens:
            return self.config.max_token
        # FIXME
        # https://community.openai.com/t/why-is-gpt-3-5-turbo-1106-max-tokens-limited-to-4096/494973/3
        return min(get_max_completion_tokens(messages, self.model, self.config.max_token), 4096)


   
    def get_maxtokens(self) -> int:
       return ['max_tokens']

    async def openai_embedding(self, text):
        response = await self.aclient.embeddings.create(
            model = model, input = text, encoding_format = "float"
        )
        return np.array([dp.embedding for dp in response.data])