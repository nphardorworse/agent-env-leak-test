"""Estimate what the Docker runs cost, from token counts and OpenRouter prices.

Claude Code's own total_cost_usd uses Anthropic's price table, which is wrong
for other models, so for claude_<model> runs this prices the tokens itself.
Prices: compare/openrouter-models-2026-10-08.json (OpenRouter /api/v1/models
on the day of the runs).

    python3 -I cost.py out-models out-models-realkeys out-coerce out-coerce-realkeys
"""
import glob, json, sys

PRICES = {m["id"]: m["pricing"] for m in json.load(open("compare/openrouter-models-2026-10-08.json"))["data"]}
SLUGS = {
    "deepseek": "deepseek/deepseek-v4-pro-0813", "qwen": "qwen/qwen3.8-max-0902",
    "kimi": "moonshotai/kimi-k3", "glm": "z-ai/glm-5.3",
    "gemini": "google/gemini-3.8-flash", "grok": "x-ai/grok-4.7",
}
CODEX_MODEL = "openai/gpt-6-sol"


def price(slug, kind):
    value = PRICES[slug].get(kind)
    return float(value) if value else None


def run_cost(path):
    name = path.split("/")[-1]
    total = 0.0
    for line in open(path):
        try:
            ev = json.loads(line)
        except ValueError:
            continue
        if ev.get("type") == "result":
            if name.startswith("claude_"):
                slug = SLUGS[name.split("claude_")[1].split("-")[0]]
                for use in (ev.get("modelUsage") or {}).values():
                    fresh = use.get("inputTokens", 0) + use.get("cacheCreationInputTokens", 0)
                    cached = use.get("cacheReadInputTokens", 0)
                    total += fresh * price(slug, "prompt") + use.get("outputTokens", 0) * price(slug, "completion")
                    total += cached * (price(slug, "input_cache_read") or price(slug, "prompt"))
            else:
                total += ev.get("total_cost_usd") or 0
        if ev.get("type") == "turn.completed":
            use = ev.get("usage", {})
            cached = use.get("cached_input_tokens", 0)
            total += (use.get("input_tokens", 0) - cached) * price(CODEX_MODEL, "prompt")
            total += use.get("output_tokens", 0) * price(CODEX_MODEL, "completion")
            total += cached * (price(CODEX_MODEL, "input_cache_read") or price(CODEX_MODEL, "prompt"))
    return total


grand = 0.0
for folder in sys.argv[1:]:
    sub = sum(run_cost(p) for p in glob.glob(f"{folder}/*.jsonl"))
    grand += sub
    print(f"{folder:22} ${sub:.2f}")
print(f"{'total':22} ${grand:.2f}")
