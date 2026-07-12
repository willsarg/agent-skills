# Empirical Basis

Verified 2026-07-12. This file separates product facts from benchmark evidence so routing rules can
outlive individual model releases.

## Source hierarchy

- Use official OpenAI sources for model availability, Codex controls, supported effort levels,
  context, and pricing.
- Use Artificial Analysis for independent intelligence, coding-agent, latency, token-use, and
  cost-per-task measurements.
- Label evidence as independently measured, estimated, OpenAI-reported, unavailable, or defective.
- Keep Codex coding-agent evidence separate from the broader Intelligence Index.

## Primary OpenAI sources

- [GPT-5.6 launch and Codex availability](https://openai.com/index/gpt-5-6/)
- [Current model catalog and supported efforts](https://developers.openai.com/api/docs/models)
- [GPT-5.6 plan and Codex version availability](https://help.openai.com/en/articles/20001354-gpt-56-in-chatgpt)
- [Codex token-based credit rate card](https://help.openai.com/en/articles/20001106-codex-rate-card-2)
- [GPT-5.6 Luna model pricing and long-context rules](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [GPT-5.6 Terra model pricing](https://developers.openai.com/api/docs/models/gpt-5.6-terra)
- [Codex models and effort guidance](https://learn.chatgpt.com/docs/models)
- [Codex subagents and custom-agent configuration](https://learn.chatgpt.com/docs/agent-configuration/subagents)
- [Codex configuration reference](https://learn.chatgpt.com/docs/config-file/config-reference)

## Independent benchmark sources

- [Artificial Analysis GPT-5.6 report](https://artificialanalysis.ai/articles/gpt-5-6-has-landed)
- [Artificial Analysis Codex model-variant matrix](https://artificialanalysis.ai/agents/coding-agents/comparisons/codex-vs-cursor-cli)
- [Artificial Analysis Intelligence Index model catalog](https://artificialanalysis.ai/providers/openai)
- [Artificial Analysis cache-price table](https://artificialanalysis.ai/models/caching)
- [JetBrains Codex repository-task evaluation](https://blog.jetbrains.com/ai/2026/06/codex-is-now-the-recommended-agent-in-jetbrains-ai/)
- [ProgramBench extended results](https://programbench.com/extended/)

## Evidence priority

1. Use task-relevant independent benchmarks with disclosed harness, effort, cost, and completion
   treatment.
2. Use Artificial Analysis configuration-level cost, runtime, token, and quality measurements.
3. Use official OpenAI evaluations for product capabilities and cross-generation evidence, while
   accounting for vendor selection.
4. Use multiple corroborating real-world evaluations when controlled benchmarks do not represent
   the workload.
5. Treat local or personal benchmark suites as exploratory or "fun" evidence only. They may suggest
   hypotheses but cannot establish a default route.

## Product facts

OpenAI introduced Sol, Terra, and Luna as durable capability tiers that may advance on independent
cadences. The version number identifies the generation. This resembles other vendors' tier naming,
but OpenAI does not claim a one-to-one mapping to Haiku, Sonnet, Opus, or Fable.

GPT-5.6 tiers support effort through `max` on model/API surfaces. Current Codex config documentation
lists `minimal`, `low`, `medium`, `high`, and `xhigh` for `model_reasoning_effort`; treat Max and Ultra
as app-level modes unless the config schema changes. Eligible paid Codex plans can select Sol, Terra,
and Luna; Free and Go receive Terra. GPT-5.6 requires at least Codex CLI 0.144.0 or desktop app
26.707.30751 according to the Help Center at verification time.

Ultra uses subagents for parallelizable complex work; OpenAI says most tasks do not need Max or
Ultra. The current official subagent/model pages do not establish a fixed default agent count or a
task-level Ultra cost/quality frontier, so this skill does not route to it.

## Pricing

### API dollars per million tokens

| Model | Input | Cache write | Cache read | Output |
|---|---:|---:|---:|---:|
| GPT-5.6 Sol | $5.00 | $6.25 | $0.50 | $30.00 |
| GPT-5.6 Terra | $2.50 | $3.125 | $0.25 | $15.00 |
| GPT-5.6 Luna | $1.00 | $1.25 | $0.10 | $6.00 |

### Codex credits per million tokens

| Model | Input | Cached input | Output |
|---|---:|---:|---:|
| GPT-5.6 Sol | 125 | 12.50 | 750 |
| GPT-5.6 Terra | 62.50 | 6.250 | 375 |
| GPT-5.6 Luna | 25 | 2.50 | 150 |

The current Codex rate card meters credits from token usage, so dollar and credit ratios are
aligned. Most accounts use this token-based card; a small legacy Enterprise cohort may still use
per-message accounting.

### Cost modifiers

- Cache writes cost 1.25× ordinary input; cache reads receive a 90% discount.
- Prompts above 272K input tokens cost 2× input and 1.5× output for the entire request.
- The public Codex rate card says Fast mode uses more credits but does not give a verified GPT-5.6
  multiplier. Do not substitute API Priority pricing as though it were Codex Fast pricing.

## Codex coding-agent matrix

Independently measured by Artificial Analysis in the Codex harness across DeepSWE, Terminal-Bench
v2, and SWE-Atlas-QnA. Cost is average pay-per-token API cost per task, not subscription-plan cost.
Time is active agent wall time and excludes environment, verifier, and judge overhead.

| Model + effort | Index | DeepSWE | Terminal | Atlas | Cost/task | Time | Tokens/task |
|---|---:|---:|---:|---:|---:|---:|---:|
| Sol `max` | 80 | 69% | 88% | 84% | $7.08 | 10.2m | 13.2M |
| Sol `xhigh` | 79 | 67% | 86% | 83% | unavailable* | 7.4m | 9.9M |
| Sol `high` | 77 | 65% | 83% | 84% | unavailable* | 6.3m | 8.1M |
| Sol `medium` | 75 | 64% | 78% | 82% | unavailable* | 5.2m | 5.8M |
| Sol `low` | 69 | 53% | 73% | 81% | unavailable* | 3.7m | 3.2M |
| Sol `none` | 58 | 35% | 61% | 79% | $1.40 | 3.4m | 3.4M |
| Terra `max` | 77 | 67% | 84% | 81% | $2.76 | 8.4m | 9.5M |
| Terra `xhigh` | 73 | 58% | 81% | 81% | $1.90 | 6.9m | 6.5M |
| Terra `high` | 72 | 60% | 76% | 79% | $1.59 | 6.2m | 5.5M |
| Terra `medium` | 64 | 46% | 69% | 77% | $0.90 | 4.3m | 3.1M |
| Terra `low` | 54 | 30% | 58% | 74% | $0.48 | 2.8m | 1.5M |
| Terra `none` | 40 | 13% | 39% | 68% | $0.37 | 1.8m | 1.1M |
| Luna `max` | 75 | 63% | 80% | 81% | $1.57 | 8.0m | 15.5M |
| Luna `xhigh` | 71 | 57% | 76% | 80% | $1.26 | 6.6m | 12.3M |
| Luna `high` | 68 | 53% | 72% | 79% | $0.96 | 5.7m | 9.5M |
| Luna `medium` | 59 | 37% | 63% | 76% | $0.47 | 3.4m | 4.4M |
| Luna `low` | 42 | 10% | 50% | 67% | $0.21 | 1.9m | 1.5M |
| Luna `none` | 37 | 6% | 37% | 68% | $0.35 | 2.5m | 3.6M |

\* Artificial Analysis currently displays `$0.00` for these rows despite nonzero token use and
published token prices. Treat the cost cells as defective/unavailable, not measured zero.

### Coding interpretation

- Terra `max` retains about 96% of Sol `max`'s index score at about 39% of its measured task cost.
- Luna `max` is two index points behind Terra `max` and about 43% cheaper, but uses substantially
  more tokens; context and long-session behavior can change the real result.
- Luna `medium` through `xhigh` form strong cheap-worker routes.
- `none` is not always cheapest: Luna `none` costs more than Luna `low` in this harness because it
  used more turns/tokens while scoring worse.
- Sol's missing cost cells prevent a complete coding-cost Pareto calculation below `max`.

### Configuration-level routing implications

| Comparison | Measured result | Default implication |
|---|---|---|
| Luna `low` vs Luna `none` | 42 at $0.21 vs 37 at $0.35 | Skip Luna `none` for ordinary coding. |
| Luna `medium` vs Terra `low` | 59 at $0.47 vs 54 at $0.48 | Prefer Luna `medium`. |
| Luna `high` vs Terra `medium` | 68 at $0.96 vs 64 at $0.90 | Prefer Luna for quality; Terra for lower tokens/runtime. |
| Luna `xhigh` vs Terra `high` | 71 at $1.26 vs 72 at $1.59 | Luna is the value route; Terra is slightly faster. |
| Luna `max` vs Terra `xhigh` | 75 at $1.57 vs 73 at $1.90 | Prefer Luna unless Terra's lower tokens/runtime matter. |
| Terra `max` vs Luna `max` | 77 at $2.76 vs 75 at $1.57 | Terra is a capability bridge, not the cost default. |
| Sol `none` vs Luna `medium` | 58 at $1.40 vs 59 at $0.47 | Prefer Luna `medium`. |

This matrix makes Luna the center of coding cost-to-correct routing. Intermediate Terra routes are
primarily runtime/token-volume alternatives; Terra `max` establishes the only measured new Terra
quality point between Luna `max` and Sol.

## Broader Intelligence Index

This benchmark mixes agentic work, coding, science, knowledge, and long-context reasoning. Use it
for non-coding routing support, not as a substitute for the Codex matrix.

| Model | none | low | medium | high | xhigh | max |
|---|---:|---:|---:|---:|---:|---:|
| Sol | 41 | — | 54 | 56 | 58 | 59 |
| Terra | 34 | — | 46 | 49 | — | 55 |
| Luna | 27 | 33 | 38 | 46 | 49 | 51 |

`—` means the exact score was not used from a verified source in this revision; do not interpolate.
Artificial Analysis reports max cost per task of $1.04 for Sol, $0.55 for Terra, and $0.21 for
Luna. It reports Luna and Sol effort configurations on the broad intelligence/cost Pareto frontier,
with Terra dominated there. That statement is benchmark-specific. In the Codex coding matrix,
Terra's intermediate routes can reduce runtime and token volume, while Terra `max` reaches index 77.

Selected full-index evaluation bills illustrate effort cost growth, but are not per-task figures:

| Configuration | Score | Full-index bill |
|---|---:|---:|
| Sol `high` | 56 | $955.55 |
| Sol `xhigh` | 58 | $1,542.52 |
| Sol `max` | 59 | $2,824.18 |
| Terra `medium` | 46 | $240.23 |
| Terra `max` | 55 | $1,753.94 |
| Luna `low` | 33 | $68.80 |
| Luna `high` | 46 | $275.02 |
| Luna `xhigh` | 49 | $479.37 |
| Luna `max` | 51 | $870.30 |

## GPT-5.4 Mini bounded-worker evidence

OpenAI positions GPT-5.4 Mini for targeted edits, codebase navigation, debugging loops, computer
use, and subagents. It costs $0.75/M input, $0.075/M cached input, and $4.50/M output, with a 400K
context window. Those token prices are 25% below Luna's, but Mini is materially weaker on hard
terminal and long-context evaluations.

JetBrains evaluated Codex with GPT-5.4 Mini on repository tasks:

| Ecosystem | Mini `low` solve / median cost / latency | Mini `medium` solve / median cost / latency |
|---|---|---|
| Weighted total | 35.1% / $0.0650 / 137.82s | 39.9% / $0.1387 / 170.40s |
| Java | 40.4% / $0.0615 / 78.02s | 43.9% / $0.1292 / 124.11s |
| C# | 51.6% / $0.0580 / 87.86s | 62.6% / $0.1152 / 142.95s |
| Python | 14.8% / $0.0766 / 308.43s | 20.2% / $0.1724 / 297.72s |

JetBrains selected `medium` because its solve-rate improvement mattered more operationally than
`low`'s lower attempt cost. Therefore route `low` to mechanical work with cheap verification and
`medium` to normal bounded implementation. Do not estimate independent retries by simply dividing
median attempt cost by aggregate solve rate; failures can correlate by task difficulty.

At `xhigh`, OpenAI reports Mini at 54.4% on SWE-Bench Pro versus 57.7% for full GPT-5.4, but 60.0%
versus 75.1% on Terminal-Bench 2.0. Artificial Analysis measured Mini `xhigh` producing 220M output
tokens across its Intelligence Index evaluation. These results argue for changing model rather than
routinely raising Mini to `xhigh`.

## Comparison and conditional models

| Model | Current role |
|---|---|
| GPT-5.5 | Compatibility/comparison when GPT-5.6 is unavailable. Same token price as Sol but weaker in current published family comparisons. |
| GPT-5.4 | Compatibility lane at Terra's token price. |
| GPT-5.4 Mini | Active narrow worker: `low` for mechanical/scouting work and `medium` for bounded implementation. |
| GPT-5.3-Codex | Codex code review currently uses it; that product choice is not a universal local-work default. |
| GPT-5.3-Codex-Spark | Research preview for rapid focused iteration; credit rates are not final. |
| GPT-5.5 Cyber | Trusted Access/Daybreak only; four times GPT-5.5's Codex credit rates and intended for advanced authorized cyber work. |

## Local native-routing probe (exploratory)

On Codex CLI 0.144.1 on 2026-07-12:

- With global `gpt-5.6-sol` / `high` pins, a trivial read-only inventory child inherited Sol/high and
  had no assigned role.
- After removing those pins, fresh `codex exec` roots selected `gpt-5.5`; three read-only delegated
  tasks were assigned the built-in `explorer` role at `gpt-5.5` / `medium`.
- Permission/task wording affected role selection: an implementation proposal and a risk review were
  both routed as explorers because both were explicitly read-only inspections.
- A forward test of this skill left a bounded packaging inventory unpinned and launched exactly one
  depth-one explorer. Session metadata showed `gpt-5.5` for the root and `gpt-5.5` / `medium` for the
  explorer, despite the response describing Luna low as the suitable economic tier. Recommendations
  must therefore not be reported as observed routes without metadata confirmation.
- That forward test reported 797,619 input tokens, 704,000 cached. The session carried a very large
  global skill/plugin and project-instruction context, so reducing always-on context is a separate
  cost lever from model selection or subagent count.

This is local exploratory evidence, not a model-quality benchmark. It supports leaving subagents
unpinned first, inspecting session metadata, and adding custom pinned agents only for repeatable
misrouting.

## Maintenance rules

1. Recheck official availability and prices before changing a default.
2. Recheck Artificial Analysis when its Codex matrix updates, especially the defective Sol costs.
3. Preserve source date and evidence type beside new numbers.
4. Never compare different harnesses as though their scores were directly interchangeable.
5. Never convert a benchmark average into a promised user-task cost.
