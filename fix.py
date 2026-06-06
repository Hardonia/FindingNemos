with open("nemoclaw-blueprint/router/llm-router/src/model_router_toolkit/adapters/litellm/review.py", "r") as f:
    content = f.read()

import re

# Add import asyncio
if "import asyncio" not in content:
    content = content.replace("import json", "import asyncio\nimport json")

old_code = """        any_correct = False
        for model_name in other_models:
            model_params = _get_litellm_params(litellm_router, model_name)
            if not model_params:
                continue

            display = config.get_model(model_name)
            display_name = display.display_name if display else model_name

            try:
                model_resp = await _call_model(
                    model_params,
                    [{"role": "user", "content": req.question}],
                    temperature=0.7,
                    max_tokens=2048,
                )
                model_answer = model_resp.choices[0].message.content or ""

                compare_prompt = COMPARE_PROMPT.format(
                    question=req.question,
                    model=model_name,
                    answer=model_answer[:2000],
                )
                judge_resp = await _call_model(
                    judge_params,
                    [{"role": "user", "content": compare_prompt}],
                    temperature=0.1,
                    max_tokens=150,
                )
                judge_text = judge_resp.choices[0].message.content or ""
                model_verdict = _parse_json_response(judge_text)

                if model_verdict.get("correct"):
                    any_correct = True

                yield _sse_event(
                    "model-result",
                    {
                        "model": model_name,
                        "display_name": display_name,
                        "correct": model_verdict.get("correct"),
                        "explanation": model_verdict.get("explanation", ""),
                    },
                )
            except Exception as e:
                yield _sse_event(
                    "model-result",
                    {
                        "model": model_name,
                        "display_name": display_name,
                        "correct": None,
                        "explanation": f"Error: {str(e)[:100]}",
                    },
                )"""

new_code = """        async def _eval_other_model(model_name: str) -> dict | None:
            model_params = _get_litellm_params(litellm_router, model_name)
            if not model_params:
                return None

            display = config.get_model(model_name)
            display_name = display.display_name if display else model_name

            try:
                model_resp = await _call_model(
                    model_params,
                    [{"role": "user", "content": req.question}],
                    temperature=0.7,
                    max_tokens=2048,
                )
                model_answer = model_resp.choices[0].message.content or ""

                compare_prompt = COMPARE_PROMPT.format(
                    question=req.question,
                    model=model_name,
                    answer=model_answer[:2000],
                )
                judge_resp = await _call_model(
                    judge_params,
                    [{"role": "user", "content": compare_prompt}],
                    temperature=0.1,
                    max_tokens=150,
                )
                judge_text = judge_resp.choices[0].message.content or ""
                model_verdict = _parse_json_response(judge_text)

                return {
                    "model": model_name,
                    "display_name": display_name,
                    "correct": model_verdict.get("correct"),
                    "explanation": model_verdict.get("explanation", ""),
                }
            except Exception as e:
                return {
                    "model": model_name,
                    "display_name": display_name,
                    "correct": None,
                    "explanation": f"Error: {str(e)[:100]}",
                }

        tasks = [_eval_other_model(m) for m in other_models]
        results = await asyncio.gather(*tasks)

        any_correct = False
        for res in results:
            if res is not None:
                if res.get("correct"):
                    any_correct = True
                yield _sse_event("model-result", res)"""

content = content.replace(old_code, new_code)

with open("nemoclaw-blueprint/router/llm-router/src/model_router_toolkit/adapters/litellm/review.py", "w") as f:
    f.write(content)
