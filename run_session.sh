#!/bin/bash
# Example invocation of the agent-harness container.
#
# Demonstrates the four things that matter for situational-awareness control:
#   1. data mounted READ-ONLY      — agent can't modify source materials
#   2. run mounted READ-WRITE      — agent's working directory
#   3. fresh /home/runner/.claude  — empty per-session, enforces blank slate
#   4. CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 — disables Claude Code auto-memory
#
# Adapt IMAGE_NAME and the data/run paths for your project. If you use the
# Claude Code CLI inside the container, restrict tools explicitly, e.g.
#   --tools Read,Write,Edit,Glob,Grep,Bash,Task
# Leaving WebSearch/WebFetch out of that list is how web access is withheld.
#
# NOTE: earlier versions of this file suggested a --no-memory flag as a third
# blank-slate layer. That flag no longer exists in Claude Code; items 3 and 4
# above are what actually enforce the blank slate.
#
# This container has full network access. To make a run genuinely offline,
# add --network none below — but that also blocks the orchestrator's own API
# calls, so it suits only harnesses that reach the model some other way.

set -e

# ─── Configurable ──────────────────────────────────────────────────────────
IMAGE_NAME="${IMAGE_NAME:-agent-harness-demo}"
DATA_DIR="${DATA_DIR:-$(pwd)/data}"
RUNS_BASE="${RUNS_BASE:-$(pwd)/runs}"

# ─── Per-session setup ─────────────────────────────────────────────────────
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RUN_DIR="$RUNS_BASE/run_$TIMESTAMP"
mkdir -p "$DATA_DIR" "$RUN_DIR"

# Auth check
if [[ -z "$ANTHROPIC_API_KEY" ]]; then
    echo "ERROR: ANTHROPIC_API_KEY is not set in the environment."
    echo "       export ANTHROPIC_API_KEY=sk-ant-..."
    exit 1
fi

# Fresh, empty /home/runner/.claude mount — created per session, removed on exit.
# This is the load-bearing piece for blank-slate enforcement.
CLAUDE_TMP=$(mktemp -d)
trap "rm -rf $CLAUDE_TMP" EXIT

echo "Image:    $IMAGE_NAME"
echo "Data:     $DATA_DIR  (read-only)"
echo "Run:      $RUN_DIR    (read-write)"
echo "Claude:   $CLAUDE_TMP (fresh, ephemeral)"
echo ""

# ─── Run the container ─────────────────────────────────────────────────────
docker run --rm \
    -v "$DATA_DIR:/workspace/data:ro" \
    -v "$RUN_DIR:/workspace/run" \
    -v "$CLAUDE_TMP:/home/runner/.claude" \
    -e ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY" \
    -e CLAUDE_CODE_DISABLE_AUTO_MEMORY=1 \
    "$IMAGE_NAME"

echo ""
echo "Container exited cleanly. Output in: $RUN_DIR"
