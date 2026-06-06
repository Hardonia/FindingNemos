import asyncio
import time
from unittest.mock import MagicMock
from fastapi import Request
from model_router_toolkit.adapters.litellm.review import _review_stream, ReviewRequest, _get_litellm_params
import model_router_toolkit.adapters.litellm.review as review_module

async def mock_call_model(params, messages, **kwargs):
    await asyncio.sleep(0.5)
    mock_resp = MagicMock()
    mock_resp.choices = [MagicMock()]
    mock_resp.choices[0].message.content = '{"correct": true, "explanation": "test"}'
    return mock_resp

review_module._call_model = mock_call_model

class MockConfig:
    class Model:
        def __init__(self, name, cost):
            self.name = name
            self.display_name = name
            self.cost_per_m_output_tokens = cost

    models = [Model("model1", 1), Model("model2", 2), Model("model3", 3), Model("model4", 4), Model("model5", 5)]

    def get_model(self, name):
        for m in self.models:
            if m.name == name:
                return m
        return None

class MockLitellmRouter:
    model_list = [
        {"model_name": "model1", "litellm_params": {"model": "m1"}},
        {"model_name": "model2", "litellm_params": {"model": "m2"}},
        {"model_name": "model3", "litellm_params": {"model": "m3"}},
        {"model_name": "model4", "litellm_params": {"model": "m4"}},
        {"model_name": "model5", "litellm_params": {"model": "m5"}},
    ]

async def run_benchmark():
    request = MagicMock(spec=Request)
    request.app.state.config = MockConfig()
    request.app.state.litellm_router = MockLitellmRouter()

    req = ReviewRequest(
        question="What is 2+2?",
        answer="4",
        selected_model="model1",
        enabled_models=["model1", "model2", "model3", "model4", "model5"]
    )

    start_time = time.time()

    # We need to set judge correct to False so it proceeds to check other models
    original_parse = review_module._parse_json_response

    call_count = 0
    def mock_parse(text):
        nonlocal call_count
        call_count += 1
        if call_count == 1:
            return {"correct": False, "explanation": "wrong"} # First is judge
        return {"correct": True, "explanation": "test"} # Models & judge on models

    review_module._parse_json_response = mock_parse

    async for event in _review_stream(request, req):
        #print(event)
        pass

    duration = time.time() - start_time
    print(f"Time taken: {duration:.2f} seconds")

if __name__ == "__main__":
    asyncio.run(run_benchmark())
