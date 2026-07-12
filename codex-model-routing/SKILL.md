---
name: codex-model-routing
description: Use when choosing a Codex-selectable OpenAI model or reasoning effort, assigning Codex subagents, deciding whether to pin or escalate a route, or controlling model-routing and delegation cost.
---

# Codex Model Routing

Choose the cheapest model and effort likely to reach correct, verified completion. Optimize expected
cost across retries, not the apparent price of one call.

## Route

1. Classify the task: mechanical, bounded, ambiguous, long-horizon, latency-bound, or failure-costly.
2. Assess verification. Cheap deterministic checks support a cheaper first attempt; weak or subjective
   verification requires stronger first-pass judgment.
3. Account for stakes and reversibility. Easy but destructive work can deserve a stronger route than
   difficult disposable analysis.
4. Leave native Codex routing unpinned by default. Pin only for high stakes, a hard latency constraint,
   or repeated metadata-confirmed misrouting.
5. Escalate after failed verification, repeated correction, wandering, or context loss. Never escalate
   from model self-confidence.

## Subagent task capsule

Start every worker with only:

- objective and expected output;
- working directory and relevant source paths;
- constraints and permissions;
- verifier or acceptance check;
- `Do not spawn subagents`.

Use zero inherited turns when the surface supports it. If the worker truly needs prior conversation,
pass the smallest positive number of turns; never pass the whole parent thread by default. Keep depth
at one unless the user explicitly authorizes recursion. Leave the worker model and effort unpinned so
Codex can assign a native role. Check session metadata before claiming what actually ran.

## Quick route

| Task shape | Starting route |
|---|---|
| Search, extraction, inventory | GPT-5.4 Mini low or Luna low |
| Bounded mechanical worker | GPT-5.4 Mini medium or Luna medium |
| Routine verified coding | Luna medium/high |
| Hard bounded coding | Luna xhigh/max |
| Runtime or token-volume sensitive | Compare Terra medium/high/xhigh |
| Ambiguous, long-horizon, weak verifier, expensive failure | Terra max or Sol high/max |
| Final judgment or quality ceiling | Sol max |

Mini is a bounded worker, not an architecture authority. Terra needs a measured latency, token-volume,
availability, or capability reason; do not select it merely because its product label says balanced.

## Effort and special modes

Use low for recoverable direct work, medium for normal agentic work, high for consequential multistep
reasoning, and xhigh/max only where marginal quality justifies the added tokens and latency. Current
Codex TOML documents effort through xhigh; Max and Ultra are app modes rather than custom-agent TOML
values unless current schema evidence says otherwise.

Ultra is outside this skill's measured cost frontier. Do not select it automatically or invent a fixed
agent count. Treat it only as an explicit user-selected experiment.

## Evidence

For ordinary native delegation, stop here. Read
[references/empirical-basis.md](references/empirical-basis.md) only when the user requests a pinned
route, explicit model comparison, benchmark or pricing justification, conditional/preview model, or
current availability claim. Recheck live documentation when model availability or pricing can drift.
