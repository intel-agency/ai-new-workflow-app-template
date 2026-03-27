# Agent Model Assignments

Reference table for all agents in `.opencode/agents/`, their current model configuration,
the traits that matter most for their role, and the best available model from `opencode.json`.

**Available models** (as of 2026-03-27):

| Provider | Models | Context | Notes |
|---|---|---|---|
| `zai-coding-plan` | `glm-5`, `glm-4.7`, `glm-4.7-flash`, `glm-4.7-flashx` | 200k | Fast, cost-effective for code tasks |
| `google` | `gemini-3.1-pro-preview`, `gemini-3-pro-preview`, `gemini-3-flash-preview`, `gemini-3.1-flash-lite-preview` | 2M / 1M | Largest context, strong reasoning |
| `openai` | `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.3-codex` | 1M | Excellent structured output, reasoning |
| `kimi-for-coding` | `kimi-k2-thinking`, `k2p5` | 262k | Reasoning models, coding-optimized |

---

## Agent Table

| Agent | Current Model | Key Required Traits | Best Model | Rationale |
|---|---|---|---|---|
| **orchestrator** | `zai-coding-plan/glm-5` | Long context (reads all event + plan docs), strong instruction-following, reliable delegation, structured output | `google/gemini-3.1-pro-preview` | 2M context handles full event JSON + plan_docs; superior instruction-following for delegation chains |
| **planner** | `google/gemini-3.1-pro-preview` ✓ | Longest context (reads all plan_docs), strong reasoning, structured output (milestones/dependencies) | `google/gemini-3.1-pro-preview` | 2M context essential; best at synthesizing large docs into structured roadmaps |
| **researcher** | `google/gemini-3.1-pro-preview` ✓ | Long context (reads many sources), synthesis, citation accuracy | `google/gemini-3.1-pro-preview` | 2M context handles many simultaneous sources; excels at distillation |
| **agent-instructions-expert** | `google/gemini-3.1-pro-preview` ✓ | Long context (reads remote instruction repos), accurate retrieval, minimal hallucination | `google/gemini-3.1-pro-preview` | Needs to retrieve and summarize large instruction docs accurately |
| **code-reviewer** | `google/gemini-3.1-pro-preview` ✓ | Large context (full diffs + history), security awareness, precise critique | `google/gemini-3.1-pro-preview` | Large diffs + OWASP reasoning; Gemini Pro handles large context reviews well |
| **documentation-expert** | `google/gemini-3.1-pro-preview` ✓ | Large context (reads whole codebase sections), clear prose, accurate API description | `google/gemini-3.1-pro-preview` | Needs to read large source sections and produce accurate, clear prose |
| **developer** | `zai-coding-plan/glm-5` | Fast code generation, tool-call reliability, follows existing patterns | `kimi-for-coding/kimi-k2-thinking` | Better reasoning for complex implementations; 262k context; code-optimized |
| **backend-developer** | `zai-coding-plan/glm-5` | API design, security patterns, test generation, complex multi-file edits | `kimi-for-coding/kimi-k2-thinking` | Reasoning model handles complex service design; strong tool-call reliability |
| **frontend-developer** | `zai-coding-plan/glm-5` | Component patterns, accessibility, CSS/TS generation, design system alignment | `openai/gpt-5.4` | Best for structured UI output; strong at design patterns and accessibility rules |
| **devops-engineer** | `zai-coding-plan/glm-5` | YAML/pipeline authoring, shell scripting, security scanning, reproducibility | `kimi-for-coding/kimi-k2-thinking` | Reasoning helps debug complex CI/CD chains; strong code generation for scripts |
| **cloud-infra-expert** | `zai-coding-plan/glm-5` (default) | Long context (IaC files + architecture docs), security reasoning, multi-cloud patterns | `google/gemini-3.1-pro-preview` | Reads large IaC codebases; needs strong security/architecture reasoning |
| **database-admin** | `zai-coding-plan/glm-5` (default) | Schema reasoning, query optimization, multi-table context, migration safety | `kimi-for-coding/kimi-k2-thinking` | Reasoning model for query analysis; strong structured output for migrations |
| **debugger** | `zai-coding-plan/glm-5` (default) | Logical reasoning, root cause analysis, hypothesis generation, stack trace parsing | `kimi-for-coding/kimi-k2-thinking` | Thinking/reasoning model is the best fit for systematic debugging |
| **github-expert** | `zai-coding-plan/glm-5` (default) | GitHub API knowledge, YAML workflow authoring, tool-call reliability | `zai-coding-plan/glm-5` | Current model is adequate; fast and reliable for well-defined GH operations |
| **product-manager** | `zai-coding-plan/glm-5` | Business reasoning, structured PRDs, stakeholder language | `google/gemini-3.1-pro-preview` | Better long-form structured output; reads large plan_docs to align on goals |
| **qa-test-engineer** | `zai-coding-plan/glm-5` | Test strategy generation, edge case reasoning, coverage analysis | `kimi-for-coding/kimi-k2-thinking` | Reasoning helps find edge cases; strong at generating comprehensive test plans |
| **ux-ui-designer** | `zai-coding-plan/glm-5` (default) | Design pattern knowledge, accessibility standards, structured spec output | `openai/gpt-5.4` | Best at structured design specs; strong knowledge of design systems and a11y |
| **odbplusplus-expert** | `google/gemini-3.1-pro-preview` ✓ | Very long context (ODB++ PDF spec ~1000 pages), technical precision | `google/gemini-3.1-pro-preview` | 2M context required for PDF spec; no other model competes here |

---

## Summary of Recommended Changes

| Agent | Change |
|---|---|
| **orchestrator** | `glm-5` → `google/gemini-3.1-pro-preview` |
| **developer** | `glm-5` → `kimi-for-coding/kimi-k2-thinking` |
| **backend-developer** | `glm-5` → `kimi-for-coding/kimi-k2-thinking` |
| **frontend-developer** | `glm-5` → `openai/gpt-5.4` |
| **devops-engineer** | `glm-5` → `kimi-for-coding/kimi-k2-thinking` |
| **cloud-infra-expert** | (default `glm-5`) → `google/gemini-3.1-pro-preview` |
| **database-admin** | (default `glm-5`) → `kimi-for-coding/kimi-k2-thinking` |
| **debugger** | (default `glm-5`) → `kimi-for-coding/kimi-k2-thinking` |
| **product-manager** | `glm-5` → `google/gemini-3.1-pro-preview` |
| **qa-test-engineer** | `glm-5` → `kimi-for-coding/kimi-k2-thinking` |
| **ux-ui-designer** | (default `glm-5`) → `openai/gpt-5.4` |
| **github-expert** | keep `glm-5` — adequate for well-defined GH operations |

> ✓ = already on recommended model, no change needed
