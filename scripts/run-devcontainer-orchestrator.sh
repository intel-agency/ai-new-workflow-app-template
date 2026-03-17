#!/usr/bin/env bash
set -euo pipefail

# run-devcontainer-orchestrator.sh
#
# Brings up the consumer devcontainer, ensures the opencode serve backend is
# running inside it, then executes the orchestrator agent with the given prompt.
#
# Typical usage (matches the GitHub Actions workflow):
#   ZHIPU_API_KEY=... KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY=... GITHUB_TOKEN=... \
#     bash ./scripts/run-devcontainer-orchestrator.sh -f .assembled-orchestrator-prompt.md
#
# Optional usage with a custom devcontainer config (e.g. build-time config):
#   bash ./scripts/run-devcontainer-orchestrator.sh \
#     -f .assembled-orchestrator-prompt.md \
#     -c .github/.devcontainer/devcontainer.json

usage() {
    echo "Usage: $0 -f <prompt-file> [-c <devcontainer-config>] [-w <workspace-folder>]" >&2
    echo "  -f <file>   Assembled prompt file path inside the workspace (required)" >&2
    echo "  -c <config> Path to devcontainer.json (default: .devcontainer/devcontainer.json)" >&2
    echo "  -w <dir>    Workspace folder for devcontainer CLI (default: .)" >&2
    exit 1
}

PROMPT_FILE=""
DEVCONTAINER_CONFIG=".devcontainer/devcontainer.json"
WORKSPACE_FOLDER="."

while getopts ":f:c:w:" opt; do
    case $opt in
        f) PROMPT_FILE="$OPTARG" ;;
        c) DEVCONTAINER_CONFIG="$OPTARG" ;;
        w) WORKSPACE_FOLDER="$OPTARG" ;;
        *) usage ;;
    esac
done

if [[ -z "$PROMPT_FILE" ]]; then
    usage
fi

# Validate required env vars before touching Docker
for var in ZHIPU_API_KEY KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY GITHUB_TOKEN; do
    if [[ -z "${!var:-}" ]]; then
        echo "::error::${var} is not set" >&2
        exit 1
    fi
done

echo "--- Step 1: Starting devcontainer ---"
devcontainer up \
    --workspace-folder "$WORKSPACE_FOLDER" \
    --config "$DEVCONTAINER_CONFIG"

echo "--- Step 2: Ensuring opencode server is running ---"
devcontainer exec \
    --workspace-folder "$WORKSPACE_FOLDER" \
    --config "$DEVCONTAINER_CONFIG" \
    -- bash ./scripts/start-opencode-server.sh

echo "--- Step 3: Running orchestrator agent ---"
devcontainer exec \
    --workspace-folder "$WORKSPACE_FOLDER" \
    --config "$DEVCONTAINER_CONFIG" \
    --remote-env ZHIPU_API_KEY="$ZHIPU_API_KEY" \
    --remote-env KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY="$KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY" \
    --remote-env GITHUB_TOKEN="$GITHUB_TOKEN" \
    --remote-env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN" \
    -- bash ./run_opencode_prompt.sh -a "http://127.0.0.1:4096" -f "$PROMPT_FILE"
