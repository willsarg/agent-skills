# Codex Model Routing Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and expose a validated `codex-model-routing` skill that routes Codex-selectable OpenAI model and effort configurations by expected cost to correct, verified completion, using the full GPT-5.6 configuration frontier plus the evidence-backed GPT-5.4 Mini worker lane.

**Architecture:** Keep the reusable workflow and safety invariants in a concise `SKILL.md`, and put dated prices, benchmark matrices, availability, and source links in `references/empirical-basis.md`. Generate Codex UI metadata with the skill-creator tooling, update the repository index, and expose the repository-owned skill through a user-level symlink.

**Tech Stack:** Markdown, YAML, Python-based skill-creator utilities, Git, filesystem symlink.

---

### Task 1: Initialize the Skill Skeleton

**Files:**
- Create: `codex-model-routing/SKILL.md`
- Create: `codex-model-routing/agents/openai.yaml`
- Create: `codex-model-routing/references/`

- [x] **Step 1: Confirm the destination is absent and the worktree is clean**

Run: `test ! -e codex-model-routing && git status --short`

Expected: exit 0 and no output.

- [x] **Step 2: Initialize the skill with generated interface metadata**

Run:

```bash
python /Users/will/.codex/skills/.system/skill-creator/scripts/init_skill.py codex-model-routing \
  --path /Users/will/Documents/Github/willsarg/agent-skills \
  --resources references \
  --interface 'display_name=Codex Model Routing' \
  --interface 'short_description=Route Codex models and effort by verified task economics' \
  --interface 'default_prompt=Use $codex-model-routing to choose the Codex model and reasoning effort for this task.'
```

Expected: a new `codex-model-routing` directory containing `SKILL.md`, `agents/openai.yaml`, and `references/`.

- [x] **Step 3: Verify the generated file set**

Run: `find codex-model-routing -maxdepth 2 -type f -print | sort`

Expected:

```text
codex-model-routing/SKILL.md
codex-model-routing/agents/openai.yaml
```

The empty `references/` directory will not appear in `find -type f` output.

### Task 2: Write the Dated Empirical Reference

**Files:**
- Create: `codex-model-routing/references/empirical-basis.md`

- [x] **Step 1: Add source hierarchy and evidence labels**

Write sections that state:

```markdown
## Source hierarchy

- Use official OpenAI sources for model availability, Codex controls, supported effort levels, context, and pricing.
- Use Artificial Analysis for independent intelligence, coding-agent, latency, token-use, and cost-per-task measurements.
- Label every benchmark as measured, estimated, OpenAI-reported, unavailable, or defective.
- Keep Codex coding-agent evidence separate from the broader Intelligence Index.
```

- [x] **Step 2: Add the GPT-5.6 capability, pricing, and availability tables**

Include Sol, Terra, and Luna; `none` through `max`; current API and Codex-credit prices; 1.05M API context; plan availability; CLI/app minimum versions; the 272K long-context price cliff; 1.25x cache-write cost; and 90% cache-read discount.

- [x] **Step 3: Add the Codex coding-agent matrix**

Record the published rows for Sol, Terra, and Luna across available effort levels, including index, benchmark subscores, task cost, runtime, turns, and token use. Mark the current `$0.00` Sol cost rows as defective/unavailable rather than zero-cost.

- [x] **Step 4: Add the broader Intelligence Index matrix and interpretation**

Record the published effort-level scores and cost evidence needed to explain the Luna/Sol Pareto frontier, Terra's broad-index position, and why that result does not erase Terra's Codex-specific strength.

- [x] **Step 5: Add comparison and conditional lanes**

Document GPT-5.4 Mini `low`/`medium` as active bounded-worker choices. Document GPT-5.5, GPT-5.4,
GPT-5.3-Codex, Spark, and GPT-5.5 Cyber as dated conditional choices. State that Spark pricing is
not final, code review uses GPT-5.3-Codex, and Cyber is entitlement-dependent.

- [x] **Step 6: Add direct source links and verify them textually**

Run: `rg -n 'https://(openai.com|help.openai.com|developers.openai.com|artificialanalysis.ai)' codex-model-routing/references/empirical-basis.md`

Expected: source links for every numeric table and product-control claim.

### Task 3: Write the Routing Workflow and Safety Invariants

**Files:**
- Modify: `codex-model-routing/SKILL.md`

- [x] **Step 1: Replace generated frontmatter**

Use only:

```yaml
---
name: codex-model-routing
description: >-
  Use when choosing a Codex-selectable OpenAI model and reasoning effort for a task, or when routing Codex subagents, to minimize expected cost to correct verified completion. Covers GPT-5.6 Sol, Terra, and Luna across none through max effort; Codex coding-agent and general-task cost-per-task evidence; stakes, reversibility, verification, context, latency, caching, escalation, legacy and conditional models, and guarded ultra multi-agent use. Triggers when asked which Codex model or effort to use, whether to escalate or down-route, how to assign a Codex worker, or how to control Codex model-routing cost.
---
```

- [x] **Step 2: Add the core decision procedure**

Define the objective as:

```text
expected total cost = measured cost per attempt x expected attempts to verified completion
```

Require routing by task shape, stakes, reversibility, verifier strength, coding-agent evidence, general-task evidence, latency, context, caching, and availability. Explicitly reject self-reported confidence and the unconditional rule to raise effort before switching tiers.

- [x] **Step 3: Add configuration-frontier guidance**

Describe Luna as the cost-to-correct center, Terra as a runtime/token-sensitive alternative and `max`
bridge, and Sol as the flagship for ambiguity and expensive failure. Include explicit dominated-route
rules and a task matrix. Do not call Terra the automatic workhorse.

- [x] **Step 4: Add escalation and cost controls**

Cover observable failure signals, context-price cliffs, cache economics, live verification for Fast-mode pricing, legacy and conditional lanes, and the rule that benchmark task cost is comparative rather than a production quote.

- [x] **Step 5: Add the hard delegation invariant**

Include these exact requirements:

```markdown
- Only the root orchestrator may spawn subagents by default.
- Put `Do not spawn subagents` in every worker prompt.
- Allow at most four total subagent launches per user request.
- Require explicit user authorization for nested delegation.
- Treat model selection and delegation authority as separate decisions.
- Stop and report any unexpected recursive spawning.
- Never select `ultra` automatically.
- Use `ultra` only with explicit authorization, the default four-agent configuration, and no other root or nested workers.
- Prohibit 16-agent or otherwise expanded `ultra` configurations.
```

- [x] **Step 6: Add a quick reference and reference link**

End with a compact decision table and a direct relative link to `[references/empirical-basis.md](references/empirical-basis.md)`.

### Task 4: Generate Metadata and Update Discovery

**Files:**
- Modify: `codex-model-routing/agents/openai.yaml`
- Modify: `README.md`
- Create: `/Users/will/.agents/skills/codex-model-routing` symlink

- [x] **Step 1: Read metadata requirements and regenerate metadata**

Run:

```bash
python /Users/will/.codex/skills/.system/skill-creator/scripts/generate_openai_yaml.py \
  codex-model-routing \
  --interface 'display_name=Codex Model Routing' \
  --interface 'short_description=Route Codex models and effort by verified task economics' \
  --interface 'default_prompt=Use $codex-model-routing to choose the Codex model and reasoning effort for this task.'
```

Expected: `codex-model-routing/agents/openai.yaml` is regenerated successfully.

- [x] **Step 2: Add the skill to the README table**

Add a row after `claude-model-routing` describing GPT-5.6 model/effort routing, cost to verified completion, empirical cost-per-task evidence, and the four-agent delegation safeguard.

- [x] **Step 3: Create the discovery symlink**

Run: `ln -s /Users/will/Documents/Github/willsarg/agent-skills/codex-model-routing /Users/will/.agents/skills/codex-model-routing`

Expected: the symlink is created without replacing any existing path.

- [x] **Step 4: Verify the symlink target**

Run: `test "$(readlink /Users/will/.agents/skills/codex-model-routing)" = '/Users/will/Documents/Github/willsarg/agent-skills/codex-model-routing'`

Expected: exit 0.

### Task 5: Validate, Audit, and Commit

**Files:**
- Verify: `codex-model-routing/SKILL.md`
- Verify: `codex-model-routing/references/empirical-basis.md`
- Verify: `codex-model-routing/agents/openai.yaml`
- Verify: `README.md`

- [x] **Step 1: Run the official skill validator**

Run: `python /Users/will/.codex/skills/.system/skill-creator/scripts/quick_validate.py codex-model-routing`

Expected: validation success.

- [x] **Step 2: Run structural and placeholder checks**

Run:

```bash
rg -n 'TBD|TODO|PLACEHOLDER|implement later|fill in' codex-model-routing README.md
git diff --check
```

Expected: no placeholder matches and no whitespace errors.

- [x] **Step 3: Audit every explicit requirement**

Run:

```bash
rg -n 'Sol|Terra|Luna|none|low|medium|high|xhigh|max|ultra|four|Do not spawn subagents|272K|cache|Fast|Spark|Cyber|cost per task|verified completion' codex-model-routing README.md
```

Expected: every required concept appears in the appropriate workflow or reference section.

- [x] **Step 4: Inspect the final diff and repository status**

Run: `git diff --stat && git diff -- codex-model-routing README.md && git status --short`

Expected: only the planned skill and README changes are present.

- [x] **Step 5: Commit the implementation**

Run:

```bash
git add codex-model-routing README.md
git commit -m 'feat: add Codex model routing skill'
```

Expected: a commit containing the complete skill implementation and repository discovery update.
