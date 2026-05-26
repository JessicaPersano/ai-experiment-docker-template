#!/usr/bin/env python3
"""
Minimal demonstrator orchestrator. Replace this with your actual experimental
session-orchestration code.

What this demonstrator does:
- Verifies the workspace mounts are accessible (/workspace/data, /workspace/run)
- Confirms ANTHROPIC_API_KEY is set
- Makes a trivial API call to prove end-to-end works
- Writes a small transcript file to /workspace/run/ to prove the writable mount works

What your real orchestrator should do (instead of this):
- Implement the conversation flow specific to your experiment
- Deliver experimental signal through in-task content (manager emails, file drops),
  NEVER through metaprompts about being in a study — Docker doesn't fix that side
- Capture a full transcript of the agent's actions for later analysis
"""

from __future__ import annotations

import os
import sys
import time
from pathlib import Path

try:
    from anthropic import Anthropic
except ImportError:
    print("ERROR: anthropic SDK not installed. Add to requirements.txt and rebuild.", file=sys.stderr)
    sys.exit(1)


WORKSPACE_ROOT = Path("/workspace")
DATA_ROOT = WORKSPACE_ROOT / "data"
RUN_ROOT = WORKSPACE_ROOT / "run"


def main() -> int:
    print(f"[demo] Container starting at {time.ctime()}")
    print(f"[demo] DATA_ROOT exists: {DATA_ROOT.exists()}")
    print(f"[demo] RUN_ROOT exists: {RUN_ROOT.exists()}")
    print(f"[demo] ANTHROPIC_API_KEY set: {'yes' if os.environ.get('ANTHROPIC_API_KEY') else 'no'}")
    print(f"[demo] CLAUDE_CODE_DISABLE_AUTO_MEMORY: {os.environ.get('CLAUDE_CODE_DISABLE_AUTO_MEMORY', 'unset')}")

    # Show what's in the mounted data directory
    if DATA_ROOT.exists():
        entries = sorted(DATA_ROOT.iterdir())
        print(f"[demo] /workspace/data contains {len(entries)} entries: {[e.name for e in entries]}")

    if not os.environ.get("ANTHROPIC_API_KEY"):
        print("[demo] no ANTHROPIC_API_KEY — skipping API call")
        return 1

    # Trivial API call to confirm the container can reach the API
    client = Anthropic()
    model = os.environ.get("MODEL", "claude-haiku-4-5-20251001")
    print(f"[demo] calling model: {model}")

    msg = client.messages.create(
        model=model,
        max_tokens=80,
        messages=[
            {
                "role": "user",
                "content": "In one sentence: what is a Docker container?",
            }
        ],
    )
    response_text = "".join(b.text for b in msg.content if hasattr(b, "text"))
    print(f"[demo] API response: {response_text}")

    # Write a transcript to the run mount to prove the writable workspace works
    transcript_path = RUN_ROOT / "transcript.txt"
    transcript_path.write_text(
        f"Container demonstrator run at {time.ctime()}\n"
        f"Model: {model}\n"
        f"Prompt tokens: {msg.usage.input_tokens}\n"
        f"Output tokens: {msg.usage.output_tokens}\n"
        f"---\n"
        f"Response: {response_text}\n"
    )
    print(f"[demo] wrote transcript to {transcript_path}")
    print(f"[demo] Container exiting at {time.ctime()}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
