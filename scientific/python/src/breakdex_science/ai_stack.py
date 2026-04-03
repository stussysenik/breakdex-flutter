from __future__ import annotations

import importlib.metadata
import os


def ai_stack_summary() -> dict[str, object]:
    return {
        "packages": {
            "dspy": importlib.metadata.version("dspy"),
            "langchain": importlib.metadata.version("langchain"),
            "langsmith": importlib.metadata.version("langsmith"),
            "numpy": importlib.metadata.version("numpy"),
            "pandas": importlib.metadata.version("pandas"),
            "scipy": importlib.metadata.version("scipy"),
        },
        "langsmith": {
            "tracingEnabled": os.getenv("LANGSMITH_TRACING", "").lower()
            in {"1", "true", "yes"},
            "project": os.getenv("LANGSMITH_PROJECT"),
            "hasApiKey": bool(os.getenv("LANGSMITH_API_KEY")),
        },
        "providers": {
            "openaiConfigured": bool(os.getenv("OPENAI_API_KEY")),
            "nimConfigured": bool(os.getenv("NIM_API_KEY")),
        },
    }
