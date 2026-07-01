# Empirical basis & sources

The routing rules in [`../SKILL.md`](../SKILL.md) are grounded in the data below, verified
**2026-06-27** (Fable 5 GA + Sonnet 5 launch, re-verified **2026-07-01**) against official Anthropic docs,
peer-reviewed papers, and independent evals. Numbers
date; re-verify pricing and benchmarks before relying on exact figures. Each section ends with the
working assumption we started from and the **verdict** the evidence returned.

## 1. Pricing & cost ratios

Current-generation list price (USD per million tokens), from Anthropic's official pricing page:

| Model | Input | Output | Cache read (hit) |
|---|---|---|---|
| Claude Fable 5 | $10.00 | $50.00 | $1.00 |
| Claude Opus 4.8 | $5.00 | $25.00 | $0.50 |
| Claude Sonnet 5 | $3.00 (intro **$2.00** ≤2026-08-31) | $15.00 (intro **$10.00**) | $0.30 (intro **$0.20**) |
| Claude Haiku 4.5 | $1.00 | $5.00 | $0.10 |

Ratios at standing prices: **Sonnet = 3× Haiku · Opus = 1.67× Sonnet = 5× Haiku · Fable = 2× Opus
= 10× Haiku · output = 5× input** (uniform across tiers). During Sonnet 5's intro window
(≤2026-08-31) Opus is temporarily **2.5×** Sonnet and Sonnet only **2×** Haiku — down-routing to
Sonnet is extra-favorable until September. Batch API = flat 50% off. Prompt caching read ≈ 0.1×
input. Fable extras: US-only inference at 1.1×; subscription-plan inclusion ended 2026-06-22
(usage credits from 2026-06-23, except a partial free re-access window 2026-07-01→07 at 50% of
weekly limits — <https://www.anthropic.com/news/redeploying-fable-5>). Note the asymmetry: Opus→Fable (2×) is the *old* Opus-rationing
ratio reborn — the "escalate readily" correction applies at Sonnet→Opus, not Opus→Fable.

- Assumption "Sonnet ≈ 3× Haiku" → **CONFIRMED** (exactly 3×).
- Assumption "Opus ≈ 5× Sonnet ≈ 19× Haiku" → **CONTRADICTED** → corrected to **1.67× Sonnet, 5×
  Haiku**. The 19× figure was the retired Opus-$15/$75 era; current Opus 4.5–4.8 is $5/$25.
- Assumption "output ≈ 5× input" → **CONFIRMED** (exactly 5× on every tier).

**Implication:** the popular "Opus is a luxury, ration it" advice was calibrated to 5× pricing and is
stale. At 1.67× Sonnet, escalate to Opus readily for non-trivial work.

Source: <https://platform.claude.com/docs/en/about-claude/pricing> (corroborated by MetaCTO,
SiliconData, Finout — all consistent with official).

**Caching & batch math.** Cache write = 1.25× input (5-min TTL) or 2× (1-hr); cache read = 0.1×
input. Break-even for *cached Opus input vs uncached Haiku* on a stable prefix:
(6.25 − 0.50)/(1.00 − 0.50) = **~12 calls** (5-min), **~20** (1-hr) — confirming the skill's figure
for the 5-min TTL. Minimum prefix to cache: **1024 tok (Opus) / 4096 (Haiku)**; below that, writes
are charged but never hit. **Batch API** = flat 50% off input+output, async ≤24h; batch Opus
(2.50/12.50) undercuts real-time Sonnet (3/15). Batch + cache stack → ~95% input-cost reduction (a
RAG case study reports ~85% daily savings on Sonnet 4.6 from caching alone). Caveat: the updated
tokenizer (Opus 4.7+, Sonnet 4.6, Sonnet 5, Fable 5) can emit **up to ~35% more tokens** (1.0–1.35×,
content-dependent) for the same text — adjust cross-tier and break-even estimates accordingly. Sources: pricing page (caching/batch sections) + Finout RAG
writeup <https://www.finout.io/blog/anthropic-api-pricing>.

## 2. Capability deltas

Selected current-generation benchmarks (see source links for full tables/harness notes):

| Benchmark | Opus 4.8 | Sonnet 4.6 | Haiku 4.5 |
|---|---|---|---|
| SWE-bench Verified | 88.6% | 79.6% | 73.3% |
| GPQA Diamond (ext. thinking) | 93.6% | 83.4% (4.5) | "middling" |
| HumanEval Pass@1 | 92.8% (4.6) | **97.6% (4.5)** | 85.2% |
| Terminal-bench (agentic shell) | 69.4% (4.7) | 50.0% (4.5) | n/p |
| GSM8K (simple math) | — | 97.2% (base 4) | 95.3% |

- "Sonnet ≈ Opus on straightforward coding" → **CONFIRMED, and directionally reversed:** on
  HumanEval-class/algorithmic coding Sonnet **matches or beats** Opus (Sonnet 4.5 97.6% > Opus 4.5
  90.2%). Sonnet is the better *default* there, not a close second.
- "Opus advantage widens on complex/multi-file/architectural/agentic" → **CONFIRMED, with a new
  carve-out:** Opus 4.8 leads Sonnet 4.6 by ~9pp on SWE-bench and leads on GPQA/tau-bench/
  Vending-Bench. (Note: at the 4.6 generation the SWE-bench gap briefly narrowed to ~1.2pp; Opus
  4.8 reopened it.) **Sonnet 5** (released 2026-06-30, `claude-sonnet-5` — "the most agentic Sonnet
  model yet") narrows it again: 63.2% vs Opus 4.8's 69.2% on SWE-bench *Pro* (~6pp), 81.2% vs 83.4%
  on OSWorld, and **parity-class on Terminal-Bench 2.1**: Sonnet 5 scores 80.4% vs Opus 4.8's 74.6%
  (per the Opus 4.8 system card) — but Anthropic's Fable page lists Opus 4.8 at 82.7% under a
  different config, so treat it as parity, not a clean win. Routing consequence stands either way:
  at 2.5–5× cheaper, parity means bounded terminal/computer-use *execution* is Sonnet territory;
  Opus's remaining edge is architecture, hard reasoning, and long-horizon judgment. (Benchmarks
  cross-referenced from the Sonnet 5 and Opus 4.8 system cards — the Sonnet 5 card itself compares
  only against Sonnet 4.6/GPT-5.5/Gemini.)
- "Haiku materially weaker on multi-step, competitive on simple" → **CONFIRMED:** HumanEval 85 vs
  Sonnet 98 (12pp), but GSM8K within ~2pp. Haiku 4.5 ≈ *base* Sonnet 4 (May 2025), since surpassed.

Sources: MDPI Applied Sciences (Sep 2025) <https://www.mdpi.com/2076-3417/15/18/9907> ·
Vellum Opus 4.5/4.7 benchmarks <https://www.vellum.ai/blog/claude-opus-4-5-benchmarks> ·
Artificial Analysis <https://artificialanalysis.ai/models/claude-4-5-haiku> ·
Morphllm <https://www.morphllm.com/claude-benchmarks>.

> **Fable 5** (`claude-fable-5`) is **GA as of 2026-07-01** — the Jun-12 export-control suspension
> is lifted (<https://www.anthropic.com/news/fable-mythos-access>). Now in scope as the ceiling
> tier. Anthropic's own benchmark table does **not** publish SWE-bench for Fable (the widely-blogged
> "95.0% SWE-bench" appears only on aggregator sites — treat as unverified); the primary-source
> gaps over Opus 4.8 are **FrontierCode (Diamond) 29.3% vs 13.4%** (at `xhigh`; more than double)
> and **Terminal-Bench 2.1 88.0% vs 82.7%**, i.e. widest on frontier-ambiguous/long-horizon agentic
> work. 1M context; effort through `xhigh`/`max`; `thinking: {"type": "disabled"}` not supported.
> **Mythos 5** (`claude-mythos-5`) shares Fable 5's capabilities without the safety classifiers,
> approved-organizations only — not routable from a normal harness.
> Sources: <https://www.anthropic.com/claude/fable> ·
> <https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5-and-claude-mythos-5>.

## 3. Effort as a lever

Levels (API `output_config.effort`): `low` / `medium` / `high` (default) / `xhigh` / `max`.

- **Haiku 4.5 has no effort parameter** (legacy `budget_tokens` only) — so the Haiku→Sonnet boundary
  is tier-only, no effort ramp.
- **`xhigh` needs Opus 4.7+, Sonnet 5, or Fable/Mythos** (per the effort docs' availability list);
  Sonnet ≤4.6 tops out at `max`. Sonnet 5 gaining `xhigh` extends "raise effort before jumping a
  tier" to the Sonnet→Opus boundary.
- **`max` is not monotonically better** — docs warn it causes "overthinking" and can degrade
  structured-output tasks. Start Opus coding/agentic at `xhigh`, reserve `max` for frontier problems.

Assumption "escalate effort before tier" → **CONFIRMED, officially endorsed:** Anthropic's
model-selection guide states *"tuning effort is often a better lever than switching models."* Holds
within Sonnet (`medium→high→max`) and Opus (`high→xhigh→max`); does **not** apply at the Haiku
boundary, and effort can't substitute for the model ceiling on frontier reasoning (GPQA/ARC-class).

Sources: <https://platform.claude.com/docs/en/build-with-claude/effort> ·
<https://platform.claude.com/docs/en/about-claude/models/choosing-a-model> ·
Ready Solutions "two knobs, not one" <https://readysolutions.ai/blog/2026-05-08-claude-model-effort-matrix/>.

## 4. Subagent orchestration

- **Per-subagent model is a documented lever:** `AgentDefinition.model` accepts `opus`/`sonnet`/
  `haiku`/`inherit`/full ID; Anthropic's own SDK example routes `model="opus" if is_strict else
  "sonnet"`. → **CONFIRMED.**
- **Opus-orchestrator + Sonnet/Haiku-workers** is Anthropic's production Research pattern, which
  "outperformed single-agent Opus 4 by 90.2%." → **CONFIRMED.**
- **Minimal-context handoff is architecturally enforced:** subagents run a fresh conversation;
  the only parent→child channel is the Agent tool's prompt string (no parent history). → **CONFIRMED
  — a constraint, not a preference.**
- **Cost anchor:** agents use ~4× the tokens of a chat; multi-agent ~15× — the economic case for
  cheap workers *and* the reason to keep fan-out narrow.

Sources: <https://code.claude.com/docs/en/agent-sdk/subagents> ·
<https://code.claude.com/docs/en/sub-agents> ·
<https://www.anthropic.com/engineering/multi-agent-research-system> ·
<https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>.

## 5. Routing-framework thesis (outside literature)

- **Route by difficulty, adjusted by stakes/reversibility** → **NUANCED.** The field's baseline is
  *difficulty-based* routing (RouteLLM, Not Diamond, the 2026 dynamic-routing survey). Reversibility
  is a valid *refinement* — difficulty and stakes are uncorrelated — best framed as a **threshold
  multiplier on top of difficulty**, not a replacement.
- **Cascade (cheap-first, escalate on low confidence/failed validation)** → **STRONGLY SUPPORTED.**
  FrugalGPT (50–98% cost cut), RouteLLM (85%), and cascade routing is *proven theoretically optimal*
  (ETH). **Caveat:** small-model self-confidence is miscalibrated — use **outcome/validation-based**
  escalation (or an LLM judge), not raw confidence.
- **"Cost = price × turns-to-completion"** → **DIRECTIONALLY CORRECT, sharpened to:** *expected cost
  per **correct** completion*; in agent loops re-sent context makes cost **super-linear** in turns,
  so **first-pass success rate** is the controlling lever.

Sources: FrugalGPT <https://arxiv.org/abs/2305.05176> · RouteLLM <https://arxiv.org/abs/2406.18665> ·
Unified Routing+Cascading (ETH) <https://arxiv.org/abs/2410.10347> ·
"Trust or Escalate" (ICLR 2025) judge-driven cascades · 2026 dynamic-routing survey
<https://arxiv.org/abs/2603.04445>.

## 6. Routing axes beyond cost & difficulty

- **Context window:** Haiku 4.5 = **200k** cap; Sonnet 5 (and 4.6) / Opus 4.8 / Fable 5 = **1M**
  (long-context surcharge dropped Mar 2026 — no price penalty; Sonnet 5's 1M confirmed in the
  models overview at launch). >200k input → Haiku out; route Sonnet (not Opus for length alone) —
  at Sonnet 5 intro pricing, doubly so.
- **Latency:** official labels Opus *Moderate* / Sonnet *Fast* / Haiku *Fastest* (~97 vs ~50 tok/s;
  Haiku ~sub-1.5s p95 chat). Binding real-time SLA can force Haiku over Sonnet.
- **Structured output / tool use:** all tiers support it; `strict:true` + forced `tool_choice` →
  ~97%+ valid JSON even on Haiku (<0.2% failure). Residual tier gap is reasoning on complex chains,
  not JSON validity — don't escalate for format.
- **Embeddings:** Anthropic has no embedding model — use Voyage (recommended), Google, or OpenAI.
  **Vision:** all tiers accept images; quality tracks general difficulty (no separate vision axis).

Source: <https://platform.claude.com/docs/en/about-claude/models/overview> ·
<https://platform.claude.com/docs/en/build-with-claude/structured-outputs>.

## 7. Claude Code / harness levers

`/model <alias>` (fable/opus/sonnet/haiku/best/default, `opus[1m]`, **opusplan** = Opus-in-plan +
Sonnet-in-execution). **`/advisor <model>`** pairs a stronger model Claude consults autonomously at
decision points (experimental, Anthropic-API-only) — the built-in escalate-on-outcome. Per-subagent
`model:` / `effort:` frontmatter, `CLAUDE_CODE_SUBAGENT_MODEL` env override (resolution: env >
per-invocation > frontmatter > main model; Explore subagent defaults to `haiku`). Effort: `/effort`,
`--effort`, `CLAUDE_CODE_EFFORT_LEVEL`; `ultrathink` keyword = one-turn deep reasoning; `ultracode` =
`xhigh` + dynamic parallel-subagent workflows; `/fast` = Opus ~2.5× faster at higher cost. **No
built-in difficulty-based auto-routing exists** — opusplan/advisor/`fallbackModel` trigger on
boundaries/availability, not task difficulty. Source: <https://code.claude.com/docs/en/model-config>
· <https://code.claude.com/docs/en/sub-agents> · <https://code.claude.com/docs/en/advisor>.

## 8. Automated routing (when to scale past hand-rules)

Manual heuristics suit interactive / low-to-medium-volume / known-task-type work where control and
transparency matter. Consider an automated router for production APIs at 100s–1000s+ req/day with an
unpredictable task mix and cost-per-request as a primary KPI. Most credible: **OpenRouter Auto**
(Not-Diamond-backed, drop-in `cost_quality_tradeoff` dial) and **RouteLLM** (LMSYS, ICLR 2025; ~85%
cost cut at ~95% quality on MT-Bench, self-hosted/auditable). Sources:
<https://github.com/lm-sys/routellm> · <https://openrouter.ai/docs/guides/routing/routers/auto-router>.

## Practitioner corroboration

The convergent practitioner consensus (r/ClaudeAI threads + SitePoint/MindStudio/Dextralabs guides,
2026) independently reaches the same shape: Haiku = read/describe/execute, Sonnet = default
implementer (~80–90%), Opus = architect/orchestrator; escalate effort before model; "Opus plans,
Sonnet/Haiku execute." The main place practitioners are *out of date* is cost: many still treat Opus
as 5×+ Sonnet and ration it accordingly — corrected in §1.
