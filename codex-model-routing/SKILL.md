---
name: codex-model-routing
description: >-
  Use when choosing a Codex-selectable OpenAI model and reasoning effort for a task, or when routing
  Codex subagents, to minimize expected cost to correct verified completion. Covers GPT-5.6 Sol,
  Terra, and Luna across none through max effort; Codex coding-agent and general-task cost-per-task
  evidence; stakes, reversibility, verification, context, latency, caching, escalation, legacy and
  conditional models, and guarded ultra multi-agent use. Triggers when asked which Codex model or
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

## The primary family

OpenAI defines Luna, Terra, and Sol as durable capability tiers. They overlap substantially once
effort changes, so they are not rigid task classes.

| Tier | Start here when | Move away when |
|---|---|---|
| **Luna** | Cost or latency matters; work is recoverable or well verified. `medium` through `max` can handle substantive bounded coding, not just mechanical extraction. | The expected retries erase its price advantage, long-context retrieval quality matters, or ambiguity/stakes demand stronger judgment. |
| **Terra** | Balanced Codex-native implementation, everyday agent work, or Free/Go availability. It is a serious frontier coding lane, not merely a small model. | Luna reaches the required quality more cheaply, or Sol's higher first-pass success is worth the premium. |
| **Sol** | Ambiguous architecture, difficult debugging, long-horizon work, weak verifiers, expensive failure, or final judgment. | The task is bounded and a Luna/Terra route clears the quality bar. |

Do not force a Haiku/Sonnet/Opus analogy. It is useful shorthand for price bands, not an empirical
one-to-one mapping.

## Current coding frontier

Use Codex coding-agent evidence before general intelligence scores for software work. Current
high-value anchors are:

| Configuration | Coding index | Measured cost/task | Use as |
|---|---:|---:|---|
| Luna `medium` | 59 | $0.47 | cheap bounded attempt |
| Terra `medium` | 64 | $0.90 | routine implementation |
| Luna `high` | 68 | $0.96 | stronger cheap worker |
| Luna `xhigh` | 71 | $1.26 | quality/value route |
| Terra `high` | 72 | $1.59 | balanced substantive route |
| Terra `xhigh` | 73 | $1.90 | harder bounded work |
| Luna `max` | 75 | $1.57 | high capability with extra tokens |
| Terra `max` | 77 | $2.76 | strong coding default for hard work |
| Sol `max` | 80 | $7.08 | quality ceiling before multi-agent |

These are benchmark averages, not quotes for a user's task. Read the complete matrix and caveats in
the empirical reference. In particular, current `$0.00` costs shown for Sol `low` through `xhigh`
are defective/missing data, not free inference.

## Pick effort by marginal return

All three GPT-5.6 tiers support `none`, `low`, `medium`, `high`, `xhigh`, and `max`.

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
- Allow at most **four total subagent launches per user request**.
- Require explicit user authorization for nested delegation.
- Before another worker wave, count all launches and confirm earlier workers produced useful work.
- Stop the subtree and report any unexpected recursive spawning.
- Never infer delegation permission from "parallelize," "do not stop," or a high-end model choice.

### `ultra`

`ultra` is multi-agent orchestration, not an ordinary effort level.

- Never select `ultra` automatically.
- Require explicit user authorization for the specific task.
- Use only its default four-agent configuration.
- Treat those four agents as the entire request allowance: launch no additional root or nested
  workers.
- Prohibit 16-agent or otherwise expanded configurations.

Use `max` as the normal single-agent ceiling.

## Secondary and conditional lanes

- Keep GPT-5.5, GPT-5.4, and GPT-5.4 Mini only for compatibility, explicit comparison, or accounts
  where GPT-5.6 is unavailable.
- Codex code review currently uses GPT-5.3-Codex; do not generalize that product routing into a
  default for local work.
- GPT-5.3-Codex-Spark is a preview latency lane with non-final credit pricing. Use it only when the
  user sees it and rapid focused iteration is the task.
- GPT-5.5 Cyber requires Trusted Access. Use it only for authorized advanced cybersecurity work;
  normal GPT-5.5 or the GPT-5.6 family remains the starting point for most defensive work.

## Quick reference

```text
cheap + verified      → Luna medium/high
routine coding        → Terra medium/high or Luna high/xhigh
hard bounded coding   → Terra xhigh/max or Luna max
ambiguous/high stakes → Sol high/xhigh/max (cost data permitting)
quality ceiling       → Sol max
multi-agent ultra     → explicit opt-in only; exactly 4 agents; no other workers

escalate on failed verification, repeated correction, wandering, or context loss
never escalate on self-reported confidence
never treat missing $0.00 benchmark cells as free
```
