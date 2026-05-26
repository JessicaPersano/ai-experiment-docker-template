# Agent Experimental Harness — Template Dockerfile
#
# Adapted from the persona drift project (which itself derives from the
# sycophancy paper harness). Builds a container that runs one agent session
# in isolation, with the three-layer "blank slate" enforcement that prevents
# session-to-session memory leakage.
#
# Build (from this directory):
#   docker build -t agent-harness-demo .
#
# Run (see run_session.sh for the full invocation with mounts/env):
#   ./run_session.sh

FROM python:3.11-slim

# ─── 1) System dependencies ─────────────────────────────────────────────────
# Add whatever your task needs (jq for parsing JSON output, ca-certificates
# for HTTPS, etc.). If you need R, swap the base image to rocker/tidyverse.
# If you need Node + Claude Code CLI, add the nodesource setup like the
# sycophancy Dockerfile does.
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates jq \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# ─── 2) Project dependencies ────────────────────────────────────────────────
COPY requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir -r /tmp/requirements.txt

# ─── 3) Non-root user ───────────────────────────────────────────────────────
# Required if your harness uses Claude Code CLI with --dangerously-skip-permissions
# (Claude Code refuses to run as root). Even if you don't use Claude Code CLI,
# running as non-root is good practice.
RUN useradd -m -s /bin/bash runner && \
    mkdir -p /workspace/run /workspace/data && \
    chown -R runner:runner /workspace

# ─── 4) Copy your orchestrator / harness code into the image ────────────────
# This is the code that talks to the API, manages the conversation, and
# implements your experimental protocol. The container's entrypoint runs it.
COPY orchestrator/ /opt/orchestrator/
RUN chmod -R a+rX /opt/orchestrator/

# ─── 5) IMPORTANT: do NOT create /home/runner/.claude here ──────────────────
# It gets mounted FRESH at runtime (see run_session.sh). That fresh empty mount
# is what prevents session-to-session memory leakage. If you create or populate
# .claude/ here, you defeat the blank-slate enforcement.

WORKDIR /workspace/run
USER runner

ENTRYPOINT ["python", "/opt/orchestrator/run_session.py"]
