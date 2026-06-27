---
name: model-routing
description: >-
  Use when choosing which Claude model (Opus, Sonnet, or Haiku) and effort level to run a task at,
  or which model + effort to assign a subagent you are dispatching, to get the best quality per
  token. Covers the model × effort decision (raise effort before jumping a tier), routing by task
  difficulty adjusted by stakes/reversibility, the cascade / escalate-on-failure pattern, the
  orchestrator + worker subagent pattern, and the cost truth that total cost = price ×
  turns-to-correct-completion (so a stronger model that one-shots can be the cheaper run). Triggers:
  picking a model for a task, dispatching a subagent / Task / Workflow, deciding whether to escalate
  to Opus or drop to Haiku, or "which model should I use for this?"
---

# Model Routing (Claude Opus / Sonnet / Haiku × effort)

Match each task to the cheapest configuration that clears its quality bar — **without** wasting
tokens *or* sacrificing first-pass success. The numbers below are current-generation (verified
2026-06-27, see [references/empirical-basis.md](references/empirical-basis.md)); the *framework*
outlives any one price change.

> The single most important correction to the popular "hoard Opus" advice: **Opus is now only
> ~1.67× Sonnet** (not the 5–19× the older blogs assume), while still meaningfully stronger on hard
> work. So the real thrift lever is **Haiku-vs-Sonnet**, and you should **escalate to Opus readily**
> when the work is non-trivial. Rationing Opus is optimizing a cost that no longer exists.

## Two knobs, in this order

You route on **tier** (Haiku → Sonnet → Opus) *and* **effort** (`low` → `medium` → `high` (default)
→ `xhigh` → `max`). Apply them in order:

1. **Difficulty** sets the tier band (mechanical / routine / hard).
2. **Stakes & reversibility** bump the band *up* (an easy-but-irreversible action outranks a
   hard-but-throwaway one — difficulty and stakes are uncorrelated).
3. **Raise effort before jumping a tier** — officially the cheaper lever ("tuning effort is often a
   better lever than switching models"). **Caveats that bite:** Haiku has **no effort knob** (so
   Haiku→Sonnet is tier-only), `xhigh` is **Opus-only**, and `max` can *overthink* and hurt
   structured-output tasks — it is not monotonically better.

## The cost truth (read this before optimizing)

**Total cost = model price × turns-to-*correct*-completion**, not price per call. In agent loops the
conversation is re-sent every turn, so cost grows **super-linearly** with turns — which makes
**first-pass success the dominant cost lever**. Consequences:

- A stronger model that one-shots a task is frequently the **cheaper total run** than a weaker one
  that loops, wanders, and needs cleanup. At Opus = 1.67× Sonnet, this tips toward escalating.
- Output tokens cost **5× input**, and a model that "writes less, reads more" is cheaper — give
  workers references, not full dumps.
- **Caching inverts naïve thrift:** on a stable prefix, *cached* Opus input can be cheaper than
  *uncached* Haiku after ~12 calls. If you reuse a big prompt, cache it and stop down-routing.

## Pick the tier

| Tier | Route here for | Avoid when | Price (in/out per M) |
|------|----------------|------------|----------------------|
| **Haiku** | Mechanical, single-step, high-volume: extraction, classification, summarization, grep/glue, batch edits/renames, tight test-run/fix-imports loops (it doesn't overthink). The genuine thrift lever. | Anything needing multi-step reasoning or judgment — it's materially weaker there (HumanEval ~85 vs Sonnet ~98). | $1 / $5 |
| **Sonnet** | **Default (~80–90% of work).** Bounded implementation, executing a plan, trivial/algorithmic coding (it *matches or beats* Opus here), everyday edits, RAG, docs. | The task is open-ended, architectural, long-horizon agentic, or hard-reasoning — escalate. | $3 / $15 |
| **Opus** | **Escalate readily (only 1.67× Sonnet):** substantive/multi-file/architectural coding, long-horizon agentic, hard reasoning (GPQA/ARC-class), ambiguous or open-ended problems, irreversible / high-stakes decisions, and **orchestrator / judge** roles. | Genuinely mechanical work (use Haiku) — and note `max` effort can overthink. | $5 / $25 |

Rule of thumb: **difficulty picks the row; stakes/reversibility can only push it up.** When unsure
between two rows and the work isn't trivially mechanical, pick the higher one — first-pass success
usually pays for it.

## Escalate on outcomes, not vibes

Cascade (try cheaper first) only when failure is **cheap *and* detectable**. Trigger escalation on
**outcome signals**, never on the model's self-reported confidence (it's miscalibrated/overconfident):

- "**failed twice / still broken / can't figure it out**" → **raise effort**, then **bump tier**.
- "**repo tourism**" / wandering / ballooning turn count → the down-route was wrong; step up.
- For **irreversible or high-stakes** work, **start strong** — don't cascade into it.

## Dispatching subagents (the orchestrator + worker pattern)

This is Anthropic's own production pattern (an Opus lead + Sonnet workers beat solo-Opus by 90.2%)
and it maps onto how you should fan out:

- **You orchestrate / judge on the capable tier; delegate tightly-scoped work to cheaper workers.**
  Set each subagent's model+effort by *its own* cost-of-failure: recoverable/mechanical →
  **Haiku/low**; bounded-substantive → **Sonnet**; irreversible judgment or hard reasoning → **Opus**.
- **Minimal-context handoff is enforced, not optional.** A subagent gets a fresh conversation; the
  *only* channel from you to it is the prompt string (no parent history). Pack every file path,
  error, and decision it needs **into the prompt** — and prefer references over full dumps
  ("reading is cheaper than writing"; workers should return ~1–2k-token distilled summaries).
- **Fan-out is expensive:** multi-agent runs use ~15× the tokens of a single chat. Keep the fan
  narrow (≈5), and only fan out when the task's value justifies it.
- **Auto-route and state it in one line** — e.g. *"dispatching on Haiku/low — mechanical extract,
  recoverable; will escalate if it stalls."* No need to ask permission; the user can override.

## When *not* to optimize

- **Plan-aware:** hard token-thrift matters most when limits are binding. If they aren't, or the user
  wants quality-first, bias up — the downside of over-spending is small at current Opus pricing.
- **Explicit user directives win.** "use opus", a `+budget` target, "keep it cheap" — follow them
  over these defaults.
- **Main loop can't self-switch.** You cannot change your *own* model mid-session — only *recommend*
  it. Surface a one-line hint **only on a real mismatch** (e.g. "this is a mechanical sweep — you
  could `/model haiku` for it"); otherwise stay silent (no hint fatigue).

## Quick reference

```
difficulty → tier band   │ stakes/reversibility → bump up   │ effort → raise before tier
─────────────────────────┼──────────────────────────────────┼───────────────────────────
mechanical    → Haiku     │ irreversible / high-stakes → +1   │ low / medium / high(default)
routine       → Sonnet    │ (easy+irreversible outranks       │ xhigh  (Opus only)
hard/agentic  → Opus      │  hard+throwaway)                  │ max    (can overthink — careful)
                          │                                   │ Haiku: no effort knob
total cost = price × turns-to-correct-completion → favor first-pass success → escalate when in doubt
escalate on OUTCOME (failed/stuck/wandering), never on self-confidence
subagents: orchestrate-on-Opus, scoped workers on Haiku/Sonnet, minimal-context (prompt-only), fan ≤5
```

For the verified pricing/benchmark numbers and all sources behind these rules, see
[references/empirical-basis.md](references/empirical-basis.md).
