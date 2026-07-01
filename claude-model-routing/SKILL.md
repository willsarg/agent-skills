---
name: claude-model-routing
description: >-
  Use when choosing which Claude model (Fable, Opus, Sonnet, or Haiku) and effort level to run a task at,
  or which model + effort to assign a subagent you are dispatching, to get the best quality per
  token. Covers the model × effort decision (raise effort before jumping a tier), routing by task
  difficulty adjusted by stakes/reversibility plus context-length and latency, the cascade /
  escalate-on-failure pattern, the orchestrator + worker subagent pattern, the in-harness levers
  (/model, opusplan, /advisor, per-subagent model), and the cost truth that total cost = price ×
  turns-to-correct-completion (so a stronger model that one-shots can be the cheaper run). Triggers:
  picking a model for a task, dispatching a subagent / Task / Workflow, deciding whether to escalate
  to Opus or drop to Haiku, or "which model should I use for this?"
---

# Model Routing (Claude Fable / Opus / Sonnet / Haiku × effort)

Match each task to the cheapest configuration that clears its quality bar — **without** wasting
tokens *or* sacrificing first-pass success. Numbers are current-generation (verified 2026-06-27;
Fable 5 GA + Sonnet 5 launch pricing verified 2026-07-01, see
[references/empirical-basis.md](references/empirical-basis.md)); the *framework* outlives any one
price change. The platform has **no built-in difficulty-based auto-routing** — that gap is what these
heuristics fill.

> The single most important correction to the popular "hoard Opus" advice: **Opus is now only
> ~1.67× Sonnet** (not the 5–19× the older blogs assume), while still meaningfully stronger on hard
> work. So the real thrift lever is **Haiku-vs-Sonnet**, and you should **escalate to Opus readily**
> when the work is non-trivial. Rationing Opus is optimizing a cost that no longer exists.
> (Sonnet 5's intro pricing — $2/$10 through 2026-08-31 — temporarily stretches Opus to 2.5×
> Sonnet; still nowhere near the old 5×, but down-routing to Sonnet is extra-cheap until then.)

## Two knobs, in this order

Route on **tier** (Haiku → Sonnet → Opus → Fable) *and* **effort** (`low` → `medium` → `high` (default) →
`xhigh` → `max`). Apply in order:

1. **Difficulty** sets the tier band (mechanical / routine / hard).
2. **Stakes & reversibility** bump the band *up* — an easy-but-irreversible action outranks a
   hard-but-throwaway one (difficulty and stakes are uncorrelated). **Context length and latency**
   can also override the pick (see below).
3. **Raise effort before jumping a tier** — officially the cheaper lever ("tuning effort is often a
   better lever than switching models"). Caveats that bite: **Haiku has no `effort` param** (it does
   light reasoning via `budget_tokens`, but you can't effort-ramp it — Haiku→Sonnet is a tier jump);
   **`xhigh` needs Opus 4.7+** (Sonnet has no `xhigh`); **`max` exists on Sonnet & Opus but can
   *overthink*** and hurt structured-output tasks — not monotonically better. Sonnet defaults to
   `high`; drop to `medium` for routine work to avoid latency surprises.

## The cost truth (read this before optimizing)

**Total cost = model price × turns-to-*correct*-completion**, not price per call. In agent loops the
conversation is re-sent every turn, so cost grows **super-linearly** with turns — making **first-pass
success the dominant lever**. Consequences:

- A stronger model that one-shots a task is frequently the **cheaper total run** than a weaker one
  that loops, wanders, and needs cleanup. At Opus = 1.67× Sonnet, this tips toward escalating.
- Output tokens cost **5× input** — a model that "reads more, writes less" is cheaper; give workers
  references, not full dumps.
- **Caching can invert thrift.** Cached input = 0.1× (write costs 1.25× at 5-min TTL, 2× at 1-hr).
  A stable prefix makes a higher tier cheap: cached Opus input beats uncached Haiku after **~12
  reads** (5-min) / **~20** (1-hr). Min prefix to cache: 1024 tok (Opus) / 4096 (Haiku) — below
  that, no caching. So **if you reuse a big prompt, cache it and stop down-routing.**
- **Batch API** (async, ≤24h) = **50% off input + output**; batch Opus (2.50 / 12.50) *undercuts*
  real-time Sonnet (3 / 15). If the task tolerates latency, that can flip the tier choice. Batch +
  cache stack to ~95% input savings.

## Pick the tier

| Tier | Route here for | Avoid when | USD/M in·out |
|------|----------------|------------|--------------|
| **Haiku** | Mechanical, single-step, high-volume: extraction, classification, summarization, grep/glue, batch edits/renames, tight test-run/fix-imports loops (it doesn't overthink). The genuine thrift lever. | Anything needing multi-step reasoning/judgment (materially weaker — SWE-bench ~73 vs Sonnet ~80, Opus ~89); **or input may exceed its 200k context cap** (Sonnet/Opus are 1M). | 1 · 5 |
| **Sonnet** | **Default (~80–90% of work).** Bounded implementation, executing a plan, trivial/algorithmic coding (it *matches or beats* Opus there), everyday edits, RAG, docs, long-context (1M). Sonnet 5 (2026-06-30) extends the "matches or beats" zone to terminal/computer-use agentic execution (beats Opus 4.8 on Terminal-Bench 2.1). | The task is open-ended, architectural, long-horizon agentic, or hard-reasoning — escalate. | 3 · 15 (intro **2 · 10** ≤2026-08-31) |
| **Opus** | **Escalate readily (only 1.67× Sonnet):** substantive/multi-file/architectural coding, long-horizon agentic, hard reasoning (GPQA/ARC-class), ambiguous/open-ended problems, irreversible / high-stakes decisions, and **orchestrator / judge** roles. | Genuinely mechanical work (use Haiku); `max` effort can overthink. | 5 · 25 |
| **Fable** | **The ceiling — route *from* it, rarely *to* it.** Frontier-ambiguous or failure-costly work where the judgment *is* the deliverable: architecture verdicts, security decisions, week-long agentic runs, judge-of-last-resort when Opus verdicts conflict. | Anything with a deterministic verifier (tests, schema, gate) — Opus/Sonnet suffice. The "escalate readily" logic does **not** extend up by default: Fable = 2× Opus, the old rationing math Opus escaped. Thinking can't be disabled — avoid for pure structured output. | 10 · 50 |

Rule of thumb: **difficulty picks the row; stakes/reversibility/context/latency can push it.** When
unsure between two rows and the work isn't trivially mechanical, pick the higher one — first-pass
success usually pays for it. (That tiebreak covers Haiku↔Sonnet↔Opus; escalating Opus→Fable needs a
positive reason — irrecoverable stakes or genuine ambiguity — not just doubt.)

> **Fable 5 is GA** (back from the mid-2026 export-control suspension) at `claude-fable-5`, $10/$50,
> 1M context, standard 90% cache-read discount. **Mythos 5** is the same underlying model without
> the dual-use safety measures, restricted to approved orgs — treat it as non-routable.

## Axes that can override the difficulty pick

- **Context length:** >200k tokens disqualifies Haiku (200k cap). Route **Sonnet** (1M, same window
  as Opus, cheaper) — don't jump to Opus *for length alone*.
- **Latency:** Haiku *fastest*, Sonnet *fast*, Opus *moderate*. For a binding real-time SLA, Haiku
  can win over Sonnet even with quality headroom; reserve Opus for async/interactive-tolerant work.
- **Structured output / tool use:** all tiers do it; with `strict: true` + forced `tool_choice` even
  Haiku is ~97% valid JSON. **Don't escalate for JSON validity** — only for complex multi-tool chains.
- **Embeddings:** Claude has no embedding model — route vector work to a dedicated embedder (see
  references). Vision is tier-independent (route on difficulty).

## Escalate on outcomes, not vibes

Cascade (try cheaper first) only when failure is **cheap *and* detectable**. Trigger escalation on
**outcome signals**, never on the model's self-reported confidence (miscalibrated/overconfident):

- "**failed twice / still broken / can't figure it out**" → **raise effort**, then **bump tier**.
- "**repo tourism**" / wandering / ballooning turn count → the down-route was wrong; step up.
- For **irreversible or high-stakes** work, **start strong** — don't cascade into it.

## Dispatching subagents (orchestrator + worker)

Anthropic's own production pattern (an Opus lead + Sonnet workers beat solo-Opus by 90.2%):

- **You orchestrate / judge on the capable tier; delegate tightly-scoped work to cheaper workers.**
  Set each subagent's model+effort by *its own* cost-of-failure: recoverable/mechanical →
  **Haiku/low**; bounded-substantive → **Sonnet**; irreversible judgment / hard reasoning → **Opus**.
- **Minimal-context handoff is architecturally enforced** — a subagent gets a fresh conversation; the
  *only* channel to it is the prompt string (no parent history). Pack every file path, error, and
  decision into the prompt; prefer references over dumps; workers should return ~1–2k-token summaries.
- **Fan-out is expensive:** multi-agent runs use ~15× the tokens of a single chat. Keep the fan
  narrow (≈5) and only fan out when the task's value justifies it.
- **Auto-route and state it in one line** — *"dispatching on Haiku/low — mechanical extract,
  recoverable; will escalate if it stalls."* No need to ask; the user can override.
- **When the main loop IS Fable, the delegation threshold drops.** Every main-loop token costs 2×
  Opus, so keep only what needs the ceiling — boundaries, verdicts, security/architecture decisions —
  and push everything with a mechanical core and a deterministic verifier down-tier. Opus becomes the
  routable judge tier; routing a subagent *to* `fable` is reserved for verdicts you'd otherwise have
  to make yourself but want out-of-context (e.g. a fork for a long adversarial review).

## Pulling the levers in Claude Code

The platform has no difficulty-based auto-routing (opusplan/advisor/fallback trigger on
boundaries/availability, *not* task difficulty) — apply these heuristics by hand:

| Intent | Lever |
|--------|-------|
| Switch model now | `/model fable\|opus\|sonnet\|haiku` |
| Plan on Opus, execute on Sonnet | `/model opusplan` (built-in plan/execute split) |
| Consult a stronger model at decision points | `/advisor opus` (built-in escalate-on-outcome) |
| Route a subagent's tier / effort | its `model:` / `effort:` frontmatter (or `CLAUDE_CODE_SUBAGENT_MODEL`); Agent tool accepts `fable` |
| Deeper reasoning, one turn only | put `ultrathink` in the prompt |
| Lower Opus latency (higher cost) | `/fast` |
| Survive overload automatically | `"fallbackModel": ["sonnet"]` |

You **can't switch your *own* main-loop model mid-session** — only recommend it; surface a one-line
`/model` hint **only on a real mismatch** (no hint fatigue).

## When *not* to optimize

- **Plan-aware:** hard thrift matters most when limits are binding. If they aren't, or the user wants
  quality-first, bias up — the downside of over-spending is small at current Opus pricing.
- **Explicit user directives win.** "use opus", a `+budget` target, "keep it cheap" — follow them.
- **Scale beyond hand-routing:** at production scale (100s–1000s req/day, unpredictable task mix)
  manual routing stops paying — an automated router fits better (see references). For interactive /
  low-volume work, this skill's audience, hand-routing wins (control + transparency).

## Quick reference

```
difficulty → tier band   │ bump up for...                    │ effort → raise before tier
─────────────────────────┼──────────────────────────────────┼───────────────────────────
mechanical    → Haiku     │ irreversible / high-stakes         │ low / medium / high(default)
routine       → Sonnet    │ >200k context (→ Sonnet, not Opus) │ xhigh  (Opus 4.7+ & Fable, not Sonnet)
hard/agentic  → Opus      │ (latency SLA → DOWN to Haiku)      │ max    (Sonnet+Opus; can overthink)
frontier-ambiguous/       │ Opus→Fable needs a POSITIVE reason │ Haiku: no effort param (budget_tokens)
 failure-costly → Fable   │ (2× Opus — not "when in doubt")    │ Fable: thinking can't be disabled
total cost = price × turns-to-correct-completion → favor first-pass success → escalate when in doubt
escalate on OUTCOME (failed/stuck/wandering), never on self-confidence
subagents: orchestrate/judge on the top tier you're on, scoped workers on Haiku/Sonnet, Opus judges,
 minimal-context (prompt-only), fan ≤5; on Fable route FROM it — keep only boundaries and verdicts
levers: /model · opusplan · /advisor · subagent model:/effort: · ultrathink · /fast
caching/batch: stable prefix or async? a higher tier can be the cheaper run
```

For verified pricing/benchmarks, the caching/batch math, the routing axes, the Claude Code mechanics,
and all sources, see [references/empirical-basis.md](references/empirical-basis.md).
