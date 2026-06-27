# agent-skills

Will's custom [Agent Skills](https://agentskills.io) — portable, model-agnostic reference guides that coding agents (Claude Code, Codex, Copilot CLI, Gemini CLI, …) load on demand to apply proven techniques.

Each skill is a directory containing a `SKILL.md` (metadata + instructions) plus optional `references/`, `scripts/`, and `assets/`. Agents read the `description` to decide when to load a skill, then pull in references and scripts only as needed. See the [Agent Skills format](https://agentskills.io/specification) for details.

## Skills

| Skill | What it covers | Use when |
|-------|----------------|----------|
| [windows-shell-execution](windows-shell-execution/) | Running commands on/through Windows — cmd.exe, Windows PowerShell 5.1 vs PowerShell 7+, Win32-OpenSSH, and WSL. Multi-layer quoting/parsing model, the PowerShell native-arg-passing version matrix (incl. the 7.3+ revert-to-Legacy trap), sshd `cmd /c` mechanics, host keys, CRLF, and CLIXML noise. Every load-bearing claim verified live on Windows 11. | A command that works on Linux mangles quotes/drops args on Windows, `Host key verification failed`, `/bin/bash^M: bad interpreter`, PowerShell stripping quotes from JSON, or reaching WSL over SSH. |
| [claude-model-routing](claude-model-routing/) | Choosing which Claude model (Opus/Sonnet/Haiku) and effort level to run a task — or assign a subagent — for the best quality per token. The model × effort decision (raise effort before jumping a tier), routing by difficulty adjusted for stakes/reversibility, cascade/escalate-on-failure, the orchestrator + worker subagent pattern, and the cost truth that total cost = price × turns-to-correct-completion. Numbers verified 2026-06-27 against official pricing, benchmarks, and the routing literature. | Picking a model for a task, dispatching a subagent/Task/Workflow, deciding whether to escalate to Opus or drop to Haiku, or "which model should I use for this?" |

## Using these skills

- **Claude Code / Codex / Copilot CLI / Gemini CLI:** clone or symlink a skill directory into your runtime's skills location (e.g. `~/.claude/skills/` or `~/.agents/skills/`), then invoke it by name.
- **Directly:** point any agent at a skill's `SKILL.md` and ask it to follow it.

## Repo layout

```
<skill-name>/
├── SKILL.md          # required: YAML frontmatter (name, description, …) + instructions
├── references/       # optional: detailed docs loaded on demand
├── scripts/          # optional: runnable helpers/diagnostics
└── assets/           # optional: templates, data, images
```

## License

[MIT](LICENSE) © Will Sarg
