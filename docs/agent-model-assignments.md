# Agent Model Assignments

Reference table for all agents in `.opencode/agents/`, their current model configuration,
the traits that matter most for their role, and the best available model from `opencode.json`.

**Available models** (as of 2026-03-27):

| Provider | Models | Context | Notes |
|---|---|---|---|
| `zai-coding-plan` | `glm-5`, `glm-4.7`, `glm-4.7-flash`, `glm-4.7-flashx` | 200k | Fast, cost-effective for code tasks |
| `google` | `gemini-3.1-pro-preview`, `gemini-3-pro-preview`, `gemini-3-flash-preview`, `gemini-3.1-flash-lite-preview` | 2M / 1M | Largest context, strong reasoning |
| `openai` | `gpt-5.4`, `gpt-5.4-mini`, `gpt-5.4-nano`, `gpt-5.3-codex` | 1M | Excellent structured output, reasoning |
| `kimi-for-coding` | `kimi-k2-thinking`, `k2p5` | 262k | Reasoning models, coding-optimized. Note: empirically, `glm-5` outperforms k2.5 on complex tasks |

---

## Agent Table

| Agent | Current Model | Key Required Traits | Best Model | Rationale | Optimal? |
|---|---|---|---|---|:---:|
| **orchestrator** | `zai-coding-plan/glm-5` | Long context (reads all event + plan docs), strong instruction-following, reliable delegation, structured output | `google/gemini-3.1-pro-preview` | 2M context handles full event JSON + plan_docs; superior instruction-following for delegation chains | ❌ |
| **planner** | `google/gemini-3.1-pro-preview` | Longest context (reads all plan_docs), strong reasoning, structured output (milestones/dependencies) | `google/gemini-3.1-pro-preview` | 2M context essential; best at synthesizing large docs into structured roadmaps | ✅ |
| **researcher** | `google/gemini-3.1-pro-preview` | Long context (reads many sources), synthesis, citation accuracy | `google/gemini-3.1-pro-preview` | 2M context handles many simultaneous sources; excels at distillation | ✅ |
| **agent-instructions-expert** | `google/gemini-3.1-pro-preview` | Long context (reads remote instruction repos), accurate retrieval, minimal hallucination | `google/gemini-3.1-pro-preview` | Needs to retrieve and summarize large instruction docs accurately | ✅ |
| **code-reviewer** | `google/gemini-3.1-pro-preview` | Large context (full diffs + history), security awareness, precise critique | `google/gemini-3.1-pro-preview` | Large diffs + OWASP reasoning; Gemini Pro handles large context reviews well | ✅ |
| **documentation-expert** | `google/gemini-3.1-pro-preview` | Large context (reads whole codebase sections), clear prose, accurate API description | `google/gemini-3.1-pro-preview` | Needs to read large source sections and produce accurate, clear prose | ✅ |
| **developer** | `zai-coding-plan/glm-5` | Fast code generation, tool-call reliability, follows existing patterns | `zai-coding-plan/glm-5` | Empirically outperforms kimi on complex tasks; proven reliable for coding | ✅ |
| **backend-developer** | `zai-coding-plan/glm-5` | API design, security patterns, test generation, complex multi-file edits | `zai-coding-plan/glm-5` | Empirically outperforms kimi on complex tasks; proven reliable for coding | ✅ |
| **frontend-developer** | `zai-coding-plan/glm-5` | Component patterns, accessibility, CSS/TS generation, design system alignment | `openai/gpt-5.4` | Best for structured UI output; strong at design patterns and accessibility rules | ❌ |
| **devops-engineer** | `zai-coding-plan/glm-5` | YAML/pipeline authoring, shell scripting, security scanning, reproducibility | `zai-coding-plan/glm-5` | Empirically outperforms kimi; fast and reliable for scripting/CI tasks | ✅ |
| **cloud-infra-expert** | `zai-coding-plan/glm-5` (default) | Long context (IaC files + architecture docs), security reasoning, multi-cloud patterns | `google/gemini-3.1-pro-preview` | Reads large IaC codebases; 2M context is the key advantage over glm-5 here | ❌ |
| **database-admin** | `zai-coding-plan/glm-5` (default) | Schema reasoning, query optimization, multi-table context, migration safety | `zai-coding-plan/glm-5` | Empirically outperforms kimi on complex tasks; adequate for schema/query work | ✅ |
| **debugger** | `zai-coding-plan/glm-5` (default) | Logical reasoning, root cause analysis, hypothesis generation, stack trace parsing | `zai-coding-plan/glm-5` | Empirically handles complex tasks better than kimi; reliable for debugging | ✅ |
| **github-expert** | `zai-coding-plan/glm-5` (default) | GitHub API knowledge, YAML workflow authoring, tool-call reliability | `zai-coding-plan/glm-5` | Current model is adequate; fast and reliable for well-defined GH operations | ✅ |
| **product-manager** | `zai-coding-plan/glm-5` | Business reasoning, structured PRDs, stakeholder language | `google/gemini-3.1-pro-preview` | Better long-form structured output; reads large plan_docs to align on goals | ❌ |
| **qa-test-engineer** | `zai-coding-plan/glm-5` | Test strategy generation, edge case reasoning, coverage analysis | `zai-coding-plan/glm-5` | Empirically outperforms kimi on complex tasks; proven for test generation | ✅ |
| **ux-ui-designer** | `zai-coding-plan/glm-5` (default) | Design pattern knowledge, accessibility standards, structured spec output | `openai/gpt-5.4` | Best at structured design specs; strong knowledge of design systems and a11y | ❌ |
| **odbplusplus-expert** | `google/gemini-3.1-pro-preview` | Very long context (ODB++ PDF spec ~1000 pages), technical precision | `google/gemini-3.1-pro-preview` | 2M context required for PDF spec; no other model competes here | ✅ |

---

## Summary of Recommended Changes

| Agent | Change |
|---|---|
| **orchestrator** | `glm-5` → `google/gemini-3.1-pro-preview` |
| **frontend-developer** | `glm-5` → `openai/gpt-5.4` |
| **cloud-infra-expert** | (default `glm-5`) → `google/gemini-3.1-pro-preview` |
| **product-manager** | `glm-5` → `google/gemini-3.1-pro-preview` |
| **ux-ui-designer** | (default `glm-5`) → `openai/gpt-5.4` |
| **developer** | keep `glm-5` — empirically outperforms kimi on complex tasks |
| **backend-developer** | keep `glm-5` — empirically outperforms kimi on complex tasks |
| **devops-engineer** | keep `glm-5` — empirically outperforms kimi on complex tasks |
| **database-admin** | keep `glm-5` — empirically outperforms kimi on complex tasks |
| **debugger** | keep `glm-5` — empirically outperforms kimi on complex tasks |
| **qa-test-engineer** | keep `glm-5` — empirically outperforms kimi on complex tasks |
| **github-expert** | keep `glm-5` — adequate for well-defined GH operations |

> ✅ = currently using the best available model · ❌ = change recommended
