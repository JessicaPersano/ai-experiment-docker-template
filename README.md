# Agent Experimental Harness — Docker Template

Bare-bones template for running an agent inside a Docker container with the situational-awareness mitigations adapted from the persona drift / sycophancy harness setup.

## What this template demonstrates

- **Per-session container isolation.** Each `docker run` gets a fresh filesystem and process namespace.
- **Three-mount pattern.** Data read-only, run workspace writable, fresh `~/.claude/` per session.
- **Two-layer blank-slate enforcement.** Empty `/home/runner/.claude/` mount + `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` env var.
- **Minimal demonstrator orchestrator.** Verifies the container is wired up correctly. You replace this with your actual experimental code.

## What Docker does (and doesn't) help with

**Helps with:**
- Session isolation between runs — no state leakage between sessions
- Repeated runs without detection — each session boots looking like the first and only run
- Controlled tool access — define exactly what the agent can do
- Blank-slate enforcement via the two layers above

**Doesn't help with:**
- *Within-session* situational awareness — if your prompts or experimental framing have a "designed feel" inside the conversation, the agent can still notice. That's a prompt-design issue, not an infrastructure issue. Docker controls what surrounds the conversation, not what's inside it.
- Model priors about deployment environments — frontier models have intuitions about what real production looks like

## Prerequisites — install Docker

Everything below assumes Docker Desktop is installed and its daemon is running. If you already have it, skip to Quick start.

**macOS (Homebrew):**
```bash
brew install --cask docker
```

**Windows:** download the installer from https://www.docker.com/products/docker-desktop/ and run it. Select the **WSL 2 backend** when prompted. You may also need to enable hardware virtualization in your BIOS.

Then open Docker Desktop and wait for the whale icon (menu bar on macOS, system tray on Windows) to show the daemon is up. Confirm with:

```bash
docker run --rm hello-world
```

If that prints a greeting, you are ready. If it complains it cannot connect to the daemon, Docker Desktop is not running yet.

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
4. **If using Claude Code CLI** inside the container, restrict tools explicitly on the `claude` invocation. The sycophancy harness uses `--tools Read,Write,Edit,Glob,Grep,Bash,Task` — note that `WebSearch` and `WebFetch` are simply left out, which is how web access is withheld from the agent.

   Older versions of this template referenced a `--no-memory` flag as a third blank-slate layer. **That flag no longer exists in Claude Code.** The two layers above (fresh `.claude` mount + `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1`) are what actually enforce the blank slate. The closest current equivalent is `--bare`, which skips auto-memory and `CLAUDE.md` auto-discovery — but `--bare` reads auth strictly from `ANTHROPIC_API_KEY` or an `apiKeyHelper` and never from OAuth or the keychain, so it will break a subscription-based login. Don't reach for it unless you are already using an API key.

5. **Withholding the tool is not the same as blocking the network.** The container in this template has full outbound access, and if the agent has `Bash` it can still reach the internet by other means (`curl`, `install.packages()` hitting CRAN). If you need the run to be genuinely offline, add `--network none` to the `docker run` in `run_session.sh`. Note that this also blocks the orchestrator's own API calls, so it only applies to harnesses where the model is reached some other way — otherwise use a firewall/proxy allowlist that permits only the API endpoint.

## Troubleshooting

**"Cannot connect to the Docker daemon"** — Docker Desktop is not running. Open the app and wait for the whale icon.

**"docker: command not found"** — Docker Desktop is installed but not on your PATH. On macOS, reopen the terminal after installing. On Windows, use a terminal opened after installation.

**Image not found** — build it first: `docker build -t agent-harness-demo .` from the repo root. Rebuild whenever the `Dockerfile` changes.

**Scripts fail with carriage-return errors (Windows)** — the shell scripts were checked out with CRLF line endings. Fix with:
```bash
git config core.autocrlf input
git checkout -- .
```

**Environment variable not visible inside the container** — variables must be exported in the shell *before* `docker run`, and passed through with `-e`. On Windows, user environment variables set through System Settings are only picked up by terminals opened afterwards.

**Permission errors writing to the run directory** — the container runs as the non-root `runner` user. Make sure the host directory you mount at `/workspace/run` is writable, or `chown` it to match.

## Important: the orchestrator is the harder half

The Dockerfile is ~30 lines and is the easy part. The harder half is the code that runs inside it — the script that talks to the API, implements your experimental protocol, and crucially delivers your experimental signal through in-task content rather than through metaprompts about being in a study. That's where the actual design lives, and that's project-specific.

The demonstrator orchestrator in this template is meant only to prove the container infrastructure works end-to-end. Don't ship anything based on it.
