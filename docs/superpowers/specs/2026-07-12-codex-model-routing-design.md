# Codex Model Routing Skill Design

## Objective

Create `codex-model-routing`, a Codex-native counterpart to `claude-model-routing`. Route Codex-selectable OpenAI models and reasoning levels by expected cost to correct, verified completion rather than price per call. Keep OpenRouter and other providers out of version one.

## Scope

The main routing family is GPT-5.6 Sol, Terra, and Luna. Cover every supported reasoning level: `none`, `low`, `medium`, `high`, `xhigh`, and `max`. Cover `ultra` as a separately guarded multi-agent mode rather than another ordinary effort level.

Keep older and conditional Codex choices in a dated secondary section, including GPT-5.5, GPT-5.4, GPT-5.4 Mini, GPT-5.3-Codex, GPT-5.3-Codex-Spark, and GPT-5.5 Cyber. Do not let these legacy or entitlement-dependent choices drive the primary decision tree.

## Skill Structure

Create only files that directly support the skill:

- `codex-model-routing/SKILL.md`: compact routing workflow, decision rules, safeguards, and quick reference.
- `codex-model-routing/references/empirical-basis.md`: dated model availability, pricing, context, effort support, benchmark evidence, cost calculations, caveats, and source links.
- `codex-model-routing/agents/openai.yaml`: generated UI metadata.

Update the repository skill index and create `~/.agents/skills/codex-model-routing` as a symlink to the repository skill.

## Routing Model

Use this objective:

`expected total cost = measured cost per attempt x expected attempts to verified completion`

Choose a complete model and effort configuration, not a model tier in isolation. Evaluate:

1. Task difficulty and shape.
2. Stakes and reversibility.
3. Strength and cost of the available verifier.
4. Measured Codex coding-agent quality and cost per task when the task is software work.
5. Broader intelligence evidence for research, knowledge work, and general reasoning.
6. Latency, context length, token use, and cache behavior.
7. Plan and selector availability.

Escalate on observable outcomes such as failed verification, repeated correction loops, wandering, or a context mismatch. Do not use model self-confidence as an escalation signal.

Do not encode a universal rule to raise effort before changing model. Compare the measured marginal quality, cost, and latency of adjacent configurations. The empirical reference will preserve the current frontier while the workflow remains valid when model data changes.

## Primary Family Interpretation

Treat Sol, Terra, and Luna as OpenAI's durable capability tiers, not as exact equivalents to Anthropic models.

- Luna is the low-cost, high-speed tier, but high effort can make it suitable for substantive bounded work.
- Terra is the balanced Codex workhorse and a strong coding lane. It remains important despite not occupying every broad intelligence/cost Pareto frontier.
- Sol is the flagship tier for ambiguous, failure-costly, long-horizon, or unusually difficult work.

Use Codex coding-agent evidence as the primary benchmark for coding routes. Current measured examples include Sol `max` at index 80 and $7.08 per task, Terra `max` at 77 and $2.76, and Luna `max` at 75 and $1.57. Preserve lower-effort rows as well. Treat missing or defective values, including currently displayed `$0.00` Sol costs, as unavailable rather than free.

Keep Artificial Analysis Intelligence Index evidence separate from Codex coding-agent evidence. Label each value as independently measured, estimated, OpenAI-reported, or unavailable.

## Cost Details

Record API token prices and Codex credit equivalents because Codex credits track token usage. Include input, cached-input, cache-write, and output costs.

Account for current GPT-5.6 pricing behavior:

- Cache reads receive a 90% discount.
- Cache writes cost 1.25 times uncached input.
- Requests above 272K input tokens charge 2 times input and 1.5 times output for the entire request.
- Fast mode exists, but its Codex-specific multiplier must be verified live until an official numeric rate is published.

Avoid presenting benchmark cost per task as a universal production estimate. It is a comparative measurement from a defined task mixture and harness.

## Delegation Safety Invariant

Prevent recursive or runaway delegation:

- Only the root orchestrator may spawn subagents by default.
- Every worker prompt must explicitly say not to spawn subagents.
- Cap each user request at four total subagent launches.
- Nested delegation requires explicit user authorization for that task.
- Model selection never grants delegation authority.
- Before another worker wave, verify that the total launch count remains within four and that earlier workers produced useful results.
- If unexpected nested spawning occurs, stop the subtree and report it.

`ultra` coordinates four agents by default. It may be used only with explicit user authorization, must use the default four-agent configuration, consumes the entire four-agent allowance, and forbids any additional root or nested workers. Configurations with more than four agents are prohibited.

## Evidence Maintenance

Date all empirical claims. Prefer official OpenAI sources for availability, selector behavior, supported efforts, pricing, context, and product controls. Use Artificial Analysis as the independent source for intelligence, coding-agent, latency, token-use, and cost-per-task comparisons.

Do not silently extrapolate missing model-effort combinations. When evidence changes, update the reference matrix and preserve the durable routing framework.

## Validation

Validate the skill by:

1. Running the skill creator's `quick_validate.py`.
2. Checking that `agents/openai.yaml` matches the finished skill.
3. Scanning for placeholders, unsupported claims, stale model names, and broken relative links.
4. Checking every numeric claim against a cited source and date.
5. Exercising representative routing scenarios without spawning subagents: cheap deterministic edit, normal implementation, hard architectural change, long-context request, failed-verification escalation, explicit `ultra` request, and unauthorized recursive delegation.
6. Confirming the repository index and `~/.agents/skills` symlink expose the skill.

## Out of Scope

- OpenRouter or other non-OpenAI models.
- Automated live benchmark collection.
- Production API router implementation.
- Automatic `ultra` selection.
- More than four subagents per user request.
