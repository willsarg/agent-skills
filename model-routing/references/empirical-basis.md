# Empirical basis & sources

The routing rules in [`../SKILL.md`](../SKILL.md) are grounded in the data below, verified
**2026-06-27** against official Anthropic docs, peer-reviewed papers, and independent evals. Numbers
date; re-verify pricing and benchmarks before relying on exact figures. Each section ends with the
working assumption we started from and the **verdict** the evidence returned.

## 1. Pricing & cost ratios

Current-generation list price (USD per million tokens), from Anthropic's official pricing page:

| Model | Input | Output | Cache read (hit) |
|---|---|---|---|
| Claude Opus 4.8 | $5.00 | $25.00 | $0.50 |
| Claude Sonnet 4.6 | $3.00 | $15.00 | $0.30 |
| Claude Haiku 4.5 | $1.00 | $5.00 | $0.10 |

Ratios: **Sonnet = 3× Haiku · Opus = 1.67× Sonnet = 5× Haiku · output = 5× input** (uniform across
tiers). Batch API = flat 50% off. Prompt caching read ≈ 0.1× input.

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
RAG case study reports ~85% daily savings on Sonnet 4.6 from caching alone). Caveat: the Opus
4.7+/Sonnet 4.6 tokenizer can emit **up to 35% more tokens** for the same text — adjust cross-tier
and break-even estimates accordingly. Sources: pricing page (caching/batch sections) + Finout RAG
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
- "Opus advantage widens on complex/multi-file/architectural/agentic" → **CONFIRMED:** Opus 4.8 leads
  Sonnet 4.6 by ~9pp on SWE-bench and leads on Terminal-bench/GPQA/tau-bench/Vending-Bench. (Note: at
  the 4.6 generation the SWE-bench gap briefly narrowed to ~1.2pp; Opus 4.8 reopened it.)
- "Haiku materially weaker on multi-step, competitive on simple" → **CONFIRMED:** HumanEval 85 vs
  Sonnet 98 (12pp), but GSM8K within ~2pp. Haiku 4.5 ≈ *base* Sonnet 4 (May 2025), since surpassed.

Sources: MDPI Applied Sciences (Sep 2025) <https://www.mdpi.com/2076-3417/15/18/9907> ·
Vellum Opus 4.5/4.7 benchmarks <https://www.vellum.ai/blog/claude-opus-4-5-benchmarks> ·
Artificial Analysis <https://artificialanalysis.ai/models/claude-4-5-haiku> ·
Morphllm <https://www.morphllm.com/claude-benchmarks>.

> Tiers above Opus — **Fable 5** (95.0% SWE-bench) and **Mythos 5** — exist (`claude-fable-5`,
> `claude-mythos-5`) but were export-control-suspended ~2026-06-12, restoration ~2026-07-01. Out of
> scope for this skill (Opus/Sonnet/Haiku trio); revisit if they return.

## 3. Effort as a lever

Levels (API `output_config.effort`): `low` / `medium` / `high` (default) / `xhigh` / `max`.

- **Haiku 4.5 has no effort parameter** (legacy `budget_tokens` only) — so the Haiku→Sonnet boundary
  is tier-only, no effort ramp.
- **`xhigh` is Opus-only** (+ Fable/Mythos); Sonnet tops out at `max`.
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

- **Context window:** Haiku 4.5 = **200k** cap; Sonnet 4.6 / Opus 4.8 / Fable 5 = **1M** (long-context
  surcharge dropped Mar 2026 — no price penalty). >200k input → Haiku out; route Sonnet (not Opus for
  length alone).
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

`/model <alias>` (opus/sonnet/haiku/best/default, `opus[1m]`, **opusplan** = Opus-in-plan +
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
