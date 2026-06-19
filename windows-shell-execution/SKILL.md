---
name: windows-shell-execution
description: >-
  Use when running or scripting commands on or through a Windows host — over SSH
  (Win32-OpenSSH), in cmd.exe or PowerShell (Windows PowerShell 5.1 or PowerShell 7+),
  or into WSL — and quoting, escaping, or argument passing misbehaves. Covers why
  single quotes don't group in cmd, why %VAR% expands, why embedded quotes/JSON get
  stripped when passing args to native exes, why PowerShell 5.1 and 7+ differ, host-key
  verification failures, CRLF "bad interpreter" errors, and CLIXML stdout noise. Triggers:
  a command that works on Linux fails on Windows, mangled or dropped arguments, stray
  quotes, "Host key verification failed", "/bin/bash^M: bad interpreter", PowerShell
  stripping quotes from JSON, or reaching WSL from an SSH session.
license: MIT
metadata:
  author: willsarg
  version: "1.0"
  status: Empirically verified live on Windows 11 + OpenSSH_for_Windows_9.5p2 (cmd default shell, Windows PowerShell 5.1, PowerShell 7.6.3, WSL2 Ubuntu 24.04).
---

# Windows Shell Execution (cmd / PowerShell / Win32-OpenSSH / WSL)

## Overview

**There is no single "command." Each one crosses several independent parsers — local shell, ssh, cmd or PowerShell, the target program's CRT — and each has its own quoting rules and strips a layer.** POSIX feels simple because there's usually one parser. Windows chains 3–4 that disagree. Get the layer count and each layer's rules right and behavior is deterministic; guess and arguments are silently corrupted (not errored).

LLM agents default to POSIX assumptions because that's their training corpus. On Windows those assumptions fail in invisible ways. This skill is the corrected, verified model.

## When to use

- Running commands on a Windows host over SSH, or driving cmd.exe / PowerShell / WSL.
- A command that works on Linux mangles quotes, drops arguments, or splits paths on Windows.
- Errors: `Host key verification failed`, `/bin/bash^M: bad interpreter`, JSON/quoted args arriving stripped, stray `"` appearing in arguments.
- Reaching a WSL Linux distro from a Windows SSH session.

## Quick reference (the high-frequency traps)

| Layer / situation | Reality (verified) |
|---|---|
| **cmd single quotes** | NOT string delimiters. `'a b'` → two tokens `'a` and `b'`. Only `"..."` groups. |
| **cmd metacharacters** | `& \| < > ^ %` are live. `echo a & echo b` runs two commands. `$` is safe; `%` is dangerous (inverse of bash). |
| **cmd `%VAR%`** | `%TEMP%` expands; undefined `%NOPE%` stays literal. Quote a metachar (`"a&b"`) to pass it literally. |
| **PowerShell single quotes** | ARE literal strings (no `$var` expansion). Opposite of cmd. "Windows ignores single quotes" is true only for cmd. |
| **PowerShell 5.1 → native exe** | `Legacy` arg passing **mangles 4 shapes**: embedded quotes stripped, empty-string args dropped (index shift), backslash-before-quote loses the backslash, and a space-containing arg ending in `\` becomes a stray `"`. |
| **PowerShell 7.3+ → native exe** | `Windows` mode fixes all four — BUT reverts to `Legacy` when the target is `cmd.exe`/`*.bat`/`*.cmd`/`cscript`/`wscript`/`*.js`/`*.vbs`/`*.wsf`. So `cmd /c …` from pwsh is still broken. |
| **SSH to a Windows box** | Lands in Windows OpenSSH (cmd or PowerShell), NOT WSL. sshd runs `cmd.exe /c "<cmd>"`. |
| **Host key verification failed** | Usually the key is trusted under the IP but not the hostname (or vice-versa). Add the real verified key; do NOT blanket-disable checking. |
| **CRLF line endings** | A Windows-authored (CRLF) script fails to exec on Linux/WSL — the `\r` becomes part of the shebang. Normalize to LF before transmit. |

See **[references/quoting-and-parsing.md](references/quoting-and-parsing.md)** for the full layer-by-layer model, the PowerShell version matrix, and the CRT backslash/quote rules. See **[references/ssh-wsl-and-streams.md](references/ssh-wsl-and-streams.md)** for sshd execution mechanics, host keys, WSL access, exit codes, and stdout/CLIXML handling.

## Robust patterns (do these)

1. **Detect the shell first — never infer it from the repo.** Probe before sending real payloads: cmd `echo %OS%` → `Windows_NT`; PowerShell `$PSVersionTable.PSVersion` (5.1 vs 7+ behave differently). The Win32-OpenSSH default shell is usually cmd but may be PowerShell.

2. **Don't hand-escape through 3 layers** (the `\"` → `\\\"` death spiral). Bypass parsing entirely:
   - **Best for PowerShell:** `powershell -NoProfile -EncodedCommand <base64-UTF16LE>` — immune to every intermediate parser. Build the base64 of your PowerShell source (note: **UTF-16LE**, not UTF-8):
     - From a Linux/macOS client: `printf '%s' '<powershell source>' | iconv -f UTF-8 -t UTF-16LE | base64 | tr -d '\n'`
     - In PowerShell: `[Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('<powershell source>'))`
     - The base64 is `[A-Za-z0-9+/=]` only, so it survives every shell/ssh/cmd layer as one bareword token.
   - `powershell -File script.ps1 args` → args land in `$args` with no expression re-parsing.
   - Pipe a script to `powershell -NoProfile -Command -` over stdin (works). This does NOT work for cmd — piping to `cmd` is an interactive REPL, not a script mode; for cmd write a `.cmd`/`.bat`.
   - Diagnose how arguments actually arrive with **[scripts/dump-args.ps1](scripts/dump-args.ps1)** (`powershell -File dump-args.ps1 <your args>`).

3. **Local (POSIX client) quoting still applies first.** From zsh/bash, wrap the whole remote command in **single quotes** so your local shell passes it verbatim — `ssh host '<remote command>'` — then quote *inside* per the remote shell's rules (double quotes for cmd). The local single quotes protect the inner double quotes and any `$`/`%` from the local shell.

4. **Passing a literal payload (e.g. JSON `{"a":"b c"}`) to a native exe:** the safe, version-independent path is to avoid inline quoting — write the payload to a file, or use `--%` for a *static* literal (`mytool.exe --% {"a":"b c"}`). **Caveat:** `--%` still expands `%VAR%`, so if the payload can contain `%`, do NOT use `--%` — build it in a variable and call the exe directly (PowerShell 7.3+ `Windows` mode preserves it) or use `-EncodedCommand`. Never route a quoted payload through `cmd /c` (reverts to Legacy → quotes stripped).

5. **`--%`** (PowerShell stop-parsing) passes the rest of the line verbatim, but still does cmd-style `%VAR%` expansion — not fully literal.

6. **Reach WSL via** `ssh -t <host> wsl.exe -d <Distro>` — WSL is a separate Linux environment with its own filesystem, users, and (only if you start one) its own sshd. When the WSL command contains `|`/`>`/etc., wrap the whole `wsl.exe …` call in a `-EncodedCommand` payload so the intermediate cmd layer never sees the metacharacters.

## Common mistakes

- Wrapping a remote command in single quotes and expecting cmd to group it — it won't; use double quotes.
- Assuming PowerShell 7+ fixed all quoting — it didn't for `cmd.exe`/`.bat` targets.
- Disabling host-key checking (`StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null`) to "just make it work" — that defeats MITM protection. Add the verified key instead.
- Running Linux text tools (`grep`/`awk`) against PowerShell output — it emits .NET objects; force text with `| Out-String -Stream` or structured data with `| ConvertTo-Json -Compress`.
- Editing a script on Windows and running it on Linux without converting CRLF→LF. Fix an affected file with `sed -i 's/\r$//' script.sh` (or `dos2unix script.sh`); prevent recurrence with `git config --global core.autocrlf input` or a `.gitattributes` entry `*.sh text eol=lf`.
