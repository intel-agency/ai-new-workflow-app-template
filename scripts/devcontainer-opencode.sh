#!/usr/bin/env bash
set -euo pipefail

# devcontainer-opencode.sh
#
# Thin CLI wrapper around devcontainer for the opencode server workflow.
# Shared defaults mean callers only specify what differs.
#
# Commands:
#   up      Start (or reconnect to) the devcontainer
#   start   Ensure opencode serve is running inside the container
#   prompt  Dispatch a prompt to the agent via opencode run --attach
#
# Shared options (env or flag, all commands):
#   -c <config>   devcontainer.json path  (env: DEVCONTAINER_CONFIG,  default: .devcontainer/devcontainer.json)
#   -w <dir>      workspace folder        (env: WORKSPACE_FOLDER,     default: .)
#
# prompt-only options:
#   -f <file>     assembled prompt file path (required)
#   -u <url>      opencode server URL        (env: OPENCODE_SERVER_URL, default: http://127.0.0.1:4096)

DEVCONTAINER_CONFIG="${DEVCONTAINER_CONFIG:-.devcontainer/devcontainer.json}"
WORKSPACE_FOLDER="${WORKSPACE_FOLDER:-.}"
OPENCODE_SERVER_URL="${OPENCODE_SERVER_URL:-http://127.0.0.1:4096}"
PROMPT_FILE=""

usage() {
    cat >&2 <<'EOF'
Usage: devcontainer-opencode.sh <command> [options]

Commands:
  up      Start (or reconnect to) the devcontainer
  start   Ensure opencode serve is running inside the container
  prompt  Dispatch a prompt file to the agent via opencode run --attach

Shared options:
  -c <config>   Path to devcontainer.json (default: .devcontainer/devcontainer.json)
  -w <dir>      Workspace folder          (default: .)

'prompt' options:
  -f <file>     Assembled prompt file path (required)
  -u <url>      opencode server URL        (default: http://127.0.0.1:4096)

Environment variables:
  DEVCONTAINER_CONFIG, WORKSPACE_FOLDER, OPENCODE_SERVER_URL
  ZHIPU_API_KEY, KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY, GITHUB_TOKEN  (required for 'prompt')
EOF
    exit 1
}

if [[ $# -lt 1 ]]; then
    usage
fi

COMMAND="$1"
shift

while getopts ":c:w:f:u:" opt; do
    case $opt in
        c) DEVCONTAINER_CONFIG="$OPTARG" ;;
        w) WORKSPACE_FOLDER="$OPTARG" ;;
        f) PROMPT_FILE="$OPTARG" ;;
        u) OPENCODE_SERVER_URL="$OPTARG" ;;
        *) usage ;;
    esac
done

shared_args=(
    --workspace-folder "$WORKSPACE_FOLDER"
    --config "$DEVCONTAINER_CONFIG"
)

case "$COMMAND" in
    up)
        devcontainer up "${shared_args[@]}"
        ;;

    start)
        devcontainer exec "${shared_args[@]}" \
            -- bash ./scripts/start-opencode-server.sh
        ;;

    prompt)
        if [[ -z "$PROMPT_FILE" ]]; then
            echo "error: -f <prompt-file> is required for the 'prompt' command" >&2
            usage
        fi
        for var in ZHIPU_API_KEY KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY GITHUB_TOKEN; do
            if [[ -z "${!var:-}" ]]; then
                echo "::error::${var} is not set" >&2
                exit 1
            fi
        done
        devcontainer exec "${shared_args[@]}" \
            --remote-env ZHIPU_API_KEY="$ZHIPU_API_KEY" \
            --remote-env KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY="$KIMI_CODE_ORCHESTRATOR_AGENT_API_KEY" \
            --remote-env GITHUB_TOKEN="$GITHUB_TOKEN" \
            --remote-env GITHUB_PERSONAL_ACCESS_TOKEN="$GITHUB_TOKEN" \
            -- bash ./run_opencode_prompt.sh -a "$OPENCODE_SERVER_URL" -f "$PROMPT_FILE"
        ;;

    *)
        echo "error: unknown command '${COMMAND}'" >&2
        usage
        ;;
esac
