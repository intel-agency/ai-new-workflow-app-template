#!/usr/bin/env python3
"""
OS-APOW Subagent Trace Extractor
Isolates subagent execution threads from the main OpenCode rotating logs.
Usage: python3 extract_subagent_trace.py --sentinel-id <id>
"""

import os
import json
import argparse
from pathlib import Path

def extract_trace(log_path, sentinel_id=None):
    if not os.path.exists(log_path):
        print(f"Error: Log file {log_path} not found.")
        return

    subagent_sessions = {}
    
    with open(log_path, 'r') as f:
        for line in f:
            try:
                entry = json.loads(line)
                
                # Filter by Sentinel ID if provided
                if sentinel_id and entry.get("sentinel_id") != sentinel_id:
                    continue

                # Detect Task tool calls (delegation)
                if entry.get("tool") == "Task":
                    task_args = entry.get("args", {})
                    sub_id = entry.get("childSessionId")
                    agent_name = task_args.get("agent", "unknown")
                    subagent_sessions[sub_id] = {
                        "agent": agent_name,
                        "objective": task_args.get("prompt", ""),
                        "logs": []
                    }

                # Associate log lines with subagent sessions
                sid = entry.get("sessionId")
                if sid in subagent_sessions:
                    subagent_sessions[sid]["logs"].append(entry)

            except json.JSONDecodeError:
                continue

    # Output distilled traces
    for sid, data in subagent_sessions.items():
        print(f"\n{'='*60}")
        print(f"SUBAGENT TRACE: {data['agent']} (ID: {sid})")
        print(f"OBJECTIVE: {data['objective'][:100]}...")
        print(f"{'='*60}")
        for log in data["logs"]:
            ts = log.get("timestamp", "")
            msg = log.get("message", "")
            print(f"[{ts}] {msg}")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--log", help="Path to log file")
    parser.add_argument("--sentinel-id", help="Filter by Sentinel instance ID")
    args = parser.parse_args()

    log_dir = Path.home() / ".local/share/opencode/log"
    target_log = args.log or sorted(log_dir.glob("*.log"))[-1]
    
    extract_trace(target_log, args.sentinel_id)