---
name: codex-model-routing
description: >-
  Use when choosing a Codex-selectable OpenAI model and reasoning effort for a task, or when routing
  Codex subagents, to minimize expected cost to correct verified completion. Covers GPT-5.6 Sol,
  Terra, and Luna across none through max effort; Codex coding-agent and general-task cost-per-task
  evidence; the GPT-5.4 Mini bounded-worker lane; stakes, reversibility, verification, context,
  latency, caching, escalation, conditional models, native subagent routing, and evidence-based
  overrides. Triggers when asked which Codex model or
  effort to use, whether to escalate or down-route, how to assign a Codex worker, or how to control
  Codex model-routing cost.
---

# Codex Model Routing

Choose the cheapest **model + effort configuration** likely to reach a correct, verified result.
Optimize the whole run, not the apparent price of one call:

```text
expected total cost = measured cost per attempt × expected attempts to verified completion
```

Numbers and availability change faster than the framework. Use the dated evidence in
[references/empirical-basis.md](references/empirical-basis.md), and verify the live model picker or
rate card when availability or pricing affects the decision.

## Route in this order

1. **Classify the task.** Is it mechanical, bounded, ambiguous, long-horizon, latency-bound, or
   failure-costly?
2. **Assess verification.** Cheap deterministic tests make a lower-cost first attempt safer. Weak or
   subjective verification raises the required first-pass quality.
3. **Adjust for stakes and reversibility.** Easy-but-irreversible work can deserve a stronger route
   than hard-but-disposable work.
4. **Choose a model and effort together.** Compare neighboring measured configurations; do not pick
   a tier first and blindly turn effort upward.
5. **Check overrides.** Context size, cache behavior, latency, plan availability, or specialized
   access can change the pick.
6. **Escalate on outcomes.** Failed verification, repeated correction, wandering, or context loss
   justify escalation. Model self-confidence does not.

## Prefer native Codex routing

For subagents, describe the task shape, permissions, verifier, and expected output precisely, then
leave model and effort unpinned by default. Codex can assign a built-in role and select a suitable
configuration. Treat the matrix below as an audit and override tool, not a replacement router.

Pin a subagent model or create a custom agent only when stakes require a known route, latency is a
hard constraint, or repeated session evidence shows a stable native misroute. Custom agents live in
`~/.codex/agents/` globally or `.codex/agents/` per trusted project; omitted model/effort fields can
inherit the parent. Verify named-agent selection in a fresh task before claiming a pin is enforced.

Keep recommendations and observations separate. An unpinned task may be *suitable for* Luna low or
Mini medium without actually running either route. Claim the model, effort, or role Codex used only
after checking session metadata; otherwise say the route was left native and unpinned.

## Configuration frontier

OpenAI defines Luna, Terra, and Sol as durable capability tiers. They overlap substantially once
effort changes, so they are not rigid task classes.

| Tier | Start here when | Move away when |
|---|---|---|
| **Luna** | Default cost-to-correct family. Use `low` for cheap direct work, `medium`/`high` for routine verified coding, and `xhigh`/`max` for hard bounded work. | Verification is weak, failure is expensive, or runtime/token volume matters more than API cost. |
| **Terra** | A measured intermediate configuration is faster or uses fewer tokens than the neighboring Luna route, Free/Go makes it the available tier, or `max` is the desired bridge between Luna and Sol. | A Luna configuration meets the quality bar more cheaply, or Sol is justified by stakes. |
| **Sol** | Ambiguous architecture, difficult debugging, long-horizon work, weak verifiers, expensive failure, or final judgment. | The task is bounded and a cheaper configuration clears the quality bar. |

Do not force a Haiku/Sonnet/Opus analogy. It is useful shorthand for price bands, not an empirical
one-to-one mapping.

Artificial Analysis currently places Luna and Sol, not Terra, on its broad intelligence/cost Pareto
frontier. Do not turn product-tier names such as "balanced" into routing evidence.

## Current coding frontier

Use Codex coding-agent evidence before general intelligence scores for software work. Current
high-value anchors are:

| Configuration | Coding index | Measured cost/task | Use as |
|---|---:|---:|---|
| Luna `medium` | 59 | $0.47 | cheap bounded attempt |
| Terra `medium` | 64 | $0.90 | lower-runtime/token alternative |
| Luna `high` | 68 | $0.96 | stronger cheap worker |
| Luna `xhigh` | 71 | $1.26 | quality/value route |
| Terra `high` | 72 | $1.59 | faster near-Luna-xhigh route |
| Terra `xhigh` | 73 | $1.90 | token-efficient near-Luna-max route |
| Luna `max` | 75 | $1.57 | high capability with extra tokens |
| Terra `max` | 77 | $2.76 | capability bridge below Sol |
| Sol `max` | 80 | $7.08 | quality ceiling before multi-agent |

These are benchmark averages, not quotes for a user's task. Read the complete matrix and caveats in
the empirical reference. In particular, current `$0.00` costs shown for Sol `low` through `xhigh`
are defective/missing data, not free inference.

### Apply measured dominance first

- Prefer Luna `low` over Luna `none`: it measured both cheaper and stronger.
- Prefer Luna `medium` over Terra `low`: it measured cheaper and stronger.
- Prefer Luna `high` over Terra `medium` when quality matters; their measured task costs are close.
- Prefer Luna `max` over Terra `high` or `xhigh` when cost and coding score dominate. Choose those
  Terra routes only when their shorter runtime or lower token volume is itself valuable.
- Use Terra `max` as the measured capability bridge: it scores above Luna `max` and costs far less
  than Sol `max`.
- Prefer Luna `medium` over Sol `none` for coding; it measured stronger at one-third the task cost.

Do not infer unknown Sol costs from `$0.00` cells. If a Sol route below `max` is under consideration,
select it because first-pass quality or stakes justify it, not because its comparative cost is known.

## Task routing matrix

Use the cheapest column only when failure is detectable and cleanup is cheap. Use the strong column
when verification is weak, retry latency is expensive, or a bad attempt can cause damage.

| Task shape | Cheapest sensible route | Normal route | Strong route |
|---|---|---|---|
| Exact extraction or reformatting | Luna `low` | Luna `low` | Luna `medium` |
| Repository search and inventory | Mini `low` | Luna `low` | Luna `medium` |
| Read-only research worker | Mini `low` | Luna `low` | Terra `medium` for synthesis |
| Mechanical rename or repetitive edit | Mini `medium` | Luna `low` | Luna `medium` |
| Small patch with deterministic tests | Mini `medium` | Luna `medium` | Luna `high` |
| Bounded bug fix or test writing | Luna `medium` | Luna `high` | Luna `xhigh` |
| Routine refactor | Luna `medium` | Luna `high` | Luna `xhigh` |
| Multi-file implementation | Luna `high` | Luna `xhigh` | Luna `max` |
| Difficult bounded algorithm | Luna `xhigh` | Luna `max` | Terra `max` |
| Complex debugging | Luna `xhigh` | Luna `max` | Terra `max` or Sol `high` |
| Terminal-heavy autonomous work | Luna `high` | Luna `xhigh`/`max` | Terra `max` or Sol |
| Runtime-sensitive agent work | Luna `medium` | Terra `medium` | Terra `high` |
| Token-volume-sensitive work | Terra `medium` | Terra `high` | Terra `xhigh` |
| Long-horizon implementation | Luna `max` | Terra `max` | Sol `high`/`max` |
| Architecture or ambiguous requirements | Luna `max` | Terra `max` | Sol `high`/`max` |
| Weak or subjective verifier | Terra `max` | Sol `high` | Sol `max` |
| Irreversible migration or expensive cleanup | Terra `max` | Sol `high` | Sol `max` |
| Computer/tool operation | Luna `high` | Luna `max` or Terra `max` | Sol `high` |
| Authorized security reasoning | Luna `max` | Terra `max` | Sol `high`/`max` |
| Final synthesis of conflicting worker findings | Luna `max` | Terra `max` | Sol `high` |

For non-coding professional work, use the same verifier/stakes logic but consult the broad
Intelligence Index rather than assuming the coding matrix transfers. Luna and Sol currently define
that measured cost/intelligence frontier; Terra requires a latency, token-use, availability, or
workload-specific reason.

## Pick effort by marginal return

GPT-5.6 model/API surfaces support effort through `max`, but Codex configuration is
surface-specific: current `model_reasoning_effort` config documents `minimal`, `low`, `medium`,
`high`, and `xhigh`. Max and Ultra are app modes; do not write them into custom-agent TOML without
current config-schema evidence.

- Use **`none`** for direct, latency-sensitive work with strong verification.
- Use **`low`** for simple, recoverable tasks that need light reasoning.
- Use **`medium`** as the first serious agentic setting.
- Use **`high`** when multi-step reasoning or judgment materially affects success.
- Use **`xhigh`** for hard bounded work where extra reasoning has measured value.
- Use **`max`** deliberately for the quality ceiling; it can multiply tokens and latency for a small
  score gain.

There is no universal "raise effort before changing model" rule. Examples from the current Codex
matrix show why: Luna `max` scores above Terra `xhigh` at lower measured task cost, while Terra
`max` approaches Sol `max` at much lower cost. Compare configurations, not labels.

## Escalation and cascades

Cascade only when failure is cheap **and detectable**.

- If verification fails once, inspect whether the cause is missing context, insufficient effort, or
  insufficient model capability.
- Raise effort when the model understood the task but reasoning depth was insufficient.
- Change tier when the attempt wandered, misunderstood boundaries, lost context, or repeatedly
  failed judgment-heavy work.
- Start strong when the action is irreversible, the verifier is weak, or cleanup would be costly.
- Stop a cascade when accumulated retries make the stronger initial route cheaper.

## Context, caching, and speed

- GPT-5.6 API requests above 272K input tokens incur 2× input and 1.5× output pricing for the whole
  request. Treat very large context as a cost override, not merely a capability check.
- Cache reads receive a 90% discount; GPT-5.6 cache writes cost 1.25× uncached input. Stable reused
  prefixes can make a stronger tier economical.
- Fast mode trades more usage for lower latency. Its Codex-specific numeric multiplier is not
  currently established in the cited public rate card; verify live before quoting it.
- Avoid carrying irrelevant history. A smaller, well-scoped prompt often saves more than a tier
  change.

## Delegation safety invariant

Model routing never grants delegation authority.

- Only the root orchestrator may spawn subagents by default.
- Put `Do not spawn subagents` in every worker prompt.
- Keep Codex's default nesting depth of one unless the user explicitly authorizes recursive
  delegation.
- Before another worker wave, confirm earlier workers produced useful results and that the next
  tasks are independent.
- Stop the subtree and report any unexpected recursive spawning.
- Never infer delegation permission from "parallelize," "do not stop," or a high-end model choice.

### `ultra`

Ultra is an app-level multi-agent mode that uses subagents for separable complex work. Current
cost-to-correct evidence in this skill does not measure it, and OpenAI says most tasks do not need
Max or Ultra. Do not route to Ultra automatically or invent a fixed agent count. Treat it only as an
explicit user-selected experiment until task-level quality, token, and latency evidence exists.

## GPT-5.4 Mini worker lane

GPT-5.4 Mini remains a live economical option rather than a generic legacy fallback. It is cheaper
per token than Luna but has a 400K context limit and lower hard-agent capability.

- Use Mini `low` for search, inventory, large-file review, mechanical edits, and other work with a
  cheap deterministic verifier.
- Use Mini `medium` as the normal bounded subagent or targeted implementation route. In JetBrains'
  repository-task evaluation, `medium` solved more tasks than `low` across Java, C#, and Python.
- Normally switch to Luna or Terra instead of raising Mini to `high` or `xhigh`; require direct
  workload evidence for those settings.
- Do not use Mini as the sole authority for architecture, weakly verified work, long-horizon
  implementation, or expensive-to-clean-up failures.

## Comparison and conditional lanes

- GPT-5.5 and GPT-5.4 are compatibility, explicit-comparison, or workload-proven exception lanes.
  Current evidence does not make either a general default over GPT-5.6.
- Codex code review currently uses GPT-5.3-Codex; do not generalize that product routing into a
  default for local work.
- GPT-5.3-Codex-Spark is a preview latency lane with non-final credit pricing. Use it only when the
  user sees it and rapid focused iteration is the task.
- GPT-5.5 Cyber requires Trusted Access. Use it only for authorized advanced cybersecurity work;
  normal GPT-5.5 or the GPT-5.6 family remains the starting point for most defensive work.

## Quick reference

```text
search/mechanical     → GPT-5.4 Mini low or Luna low
bounded worker        → GPT-5.4 Mini medium or Luna medium
routine coding        → Luna medium/high
hard bounded coding   → Luna xhigh/max
runtime/token bound   → compare Terra medium/high/xhigh
bridge below Sol      → Terra max
ambiguous/high stakes → Sol high/xhigh/max
quality ceiling       → Sol max
subagents              → native routing first; pin only for stakes or demonstrated misrouting
multi-agent ultra      → outside the evidence-backed router; explicit experiment only

escalate on failed verification, repeated correction, wandering, or context loss
never escalate on self-reported confidence
never treat missing $0.00 benchmark cells as free
```

## Evidence discipline

- Use disclosed, task-relevant independent benchmarks before general aggregate scores.
- Use official OpenAI results for capabilities and product facts, while accounting for vendor
  selection bias.
- Use local or personal benchmark runs as exploratory evidence only. They can motivate a targeted
  evaluation but cannot establish a default route.
- Recheck the dated [empirical basis](references/empirical-basis.md) when model snapshots or prices
  may have changed.
