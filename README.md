# Agent Experimental Harness — Docker Template

Bare-bones template for running an agent inside a Docker container with the situational-awareness mitigations adapted from the persona drift / sycophancy harness setup.

## What this template demonstrates

- **Per-session container isolation.** Each `docker run` gets a fresh filesystem and process namespace.
- **Three-mount pattern.** Data read-only, run workspace writable, fresh `~/.claude/` per session.
- **Three-layer blank-slate enforcement.** Empty `/home/runner/.claude/` mount + `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` env var + (optional) `--no-memory` CLI flag on the Claude Code invocation.
- **Minimal demonstrator orchestrator.** Verifies the container is wired up correctly. You replace this with your actual experimental code.

## What Docker does (and doesn't) help with

**Helps with:**
- Session isolation between runs — no state leakage between sessions
- Repeated runs without detection — each session boots looking like the first and only run
- Controlled tool access — define exactly what the agent can do
- Blank-slate enforcement via the three layers above

**Doesn't help with:**
- *Within-session* situational awareness — if your prompts or experimental framing have a "designed feel" inside the conversation, the agent can still notice. That's a prompt-design issue, not an infrastructure issue. Docker controls what surrounds the conversation, not what's inside it.
- Model priors about deployment environments — frontier models have intuitions about what real production looks like

## Quick start

```bash
# 1) Build the image (from this directory)
docker build -t agent-harness-demo .

# 2) Set your Anthropic API key
export ANTHROPIC_API_KEY=sk-ant-...

# 3) Run a demo session
./run_session.sh
```

Each run creates a fresh directory under `runs/run_<timestamp>/`. The demonstrator orchestrator inside the container:

- Confirms the workspace mounts are accessible
- Makes a trivial API call to Claude Haiku
- Writes a `transcript.txt` to the writable workspace

Output should land in something like `runs/run_20260512_143022/transcript.txt`.

## Files

| File | What it is |
|---|---|
| `Dockerfile` | Image definition. Adapt the base image and system deps to your task. |
| `requirements.txt` | Python deps inside the image. Add whatever your orchestrator needs. |
| `orchestrator/run_session.py` | Minimal demonstrator. **Replace with your actual experimental orchestrator.** |
| `run_session.sh` | Example wrapper showing the `docker run` invocation. Adapt paths and image name for your project. |

## Adapting for your project

1. **Swap the base image** if you need R (`rocker/tidyverse`), Node + Claude Code CLI (see the sycophancy paper's Dockerfile), or other runtimes.
2. **Replace `orchestrator/run_session.py`** with your actual session-orchestration code. The demonstrator is intentionally trivial — it just proves the container is wired up correctly. Your orchestrator implements the conversation flow for your experiment.
3. **Adjust `run_session.sh`** paths to point at your data and run directories.
4. **If using Claude Code CLI** inside the container, pass `--no-memory` on the claude invocation as the third layer of blank-slate enforcement (the env var is the second; the fresh `.claude` mount is the first).

## Important: the orchestrator is the harder half

The Dockerfile is ~30 lines and is the easy part. The harder half is the code that runs inside it — the script that talks to the API, implements your experimental protocol, and crucially delivers your experimental signal through in-task content rather than through metaprompts about being in a study. That's where the actual design lives, and that's project-specific.

The demonstrator orchestrator in this template is meant only to prove the container infrastructure works end-to-end. Don't ship anything based on it.
