# Quoting & Argument Parsing on Windows

Every claim marked ✓ was verified live on Windows 11 (OpenSSH_for_Windows_9.5p2, Windows PowerShell 5.1.26100, PowerShell 7.6.3) using the argv-dumper in `scripts/dump-args.ps1`.

## The mental model: count the parsers

A command from a non-Windows client to a Windows host typically crosses:

```
local shell  →  ssh client flattens argv into one string  →  Windows sshd runs cmd.exe /c "<cmd>"  →  cmd applies its /c quote-stripping rule  →  target program's CRT parses argv
```

Each step is a parser (or a join) with its own rules. There is no single quoting scheme that is "correct" — correctness is per-layer.

## CMD layer

`cmd.exe` is the usual remote default shell for Win32-OpenSSH. Rules (all ✓):

- **Single quotes are not delimiters.** `'x y'` → two tokens `'x` and `y'`. Only `"..."` groups arguments.
- **`& | < > ^ %` are live metacharacters.** `echo a & echo b` runs two separate commands. In a remote `cmd /c` context this means unquoted `&`/`|`/`&&` act on the remote shell, not your program.
- **`%VAR%` expands; undefined `%NOPE%` stays literal.** `$` has no special meaning in cmd — the inverse of bash, where `$` is dangerous and `%` is safe.
- **To pass a metacharacter literally, quote it:** `"a&b"` arrives as one literal argument `a&b`.

## PowerShell layer

PowerShell is not a text shell; it parses in *expression* vs *argument* mode and re-expands `$var`, `$(...)`, etc. inside double-quoted strings.

- **Single-quoted strings are literal** (no expansion) ✓ — the exact opposite of cmd. The popular claim "Windows doesn't recognize single quotes" is true only for cmd.
- **Backtick `` ` `` is the escape character** (not backslash). Backslash is *not* a PowerShell escape character — it's the escape character used by the underlying `ProcessStartInfo.ArgumentList` API, which is why backslash-near-quote interacts badly (below).

### The PowerShell native-argument-passing version matrix ✓

`$PSNativeCommandArgumentPassing` controls how PowerShell builds the command line for a native executable. Default is `Windows` on Windows, `Standard` on non-Windows, and Windows PowerShell 5.1 is always `Legacy`.

Live results passing each argument to a native exe (the dumper), 5.1 `Legacy` vs 7.6.3 `Windows`:

| argument | 5.1 (Legacy) | 7.6.3 (Windows) |
|---|---|---|
| `a\b`, `a\\b`, `C:\dir\` (backslashes, no adjacent quote) | ✓ intact | ✓ intact |
| `say "hi"` or JSON `{"a":"b c"}` (embedded quotes) | `say hi` / `{a:b c}` ✗ stripped | ✓ preserved |
| `''` (empty-string arg) | **dropped — argument count shifts** ✗ | ✓ preserved |
| `a\"b` (backslash-before-quote) | `a"b` ✗ backslash lost | ✓ preserved |
| `x \` (space → needs quoting, ends in `\`) | **`x "` ✗ corrupted into a stray quote** | ✓ preserved |

So Windows PowerShell 5.1 silently mangles **four** argument shapes. Plain Windows paths *without* an adjacent quote (`C:\dir\`) are safe in both. The danger is specifically: an embedded `"`, an empty string, or a backslash adjacent to a quote / at the end of a quoted (space-containing) argument.

### The trap even on PowerShell 7.3+ ✓

In `Windows` mode, calls whose target is one of these revert to broken `Legacy` passing:

`cmd.exe`, `cscript.exe`, `wscript.exe`, and files ending in `.bat`, `.cmd`, `.js`, `.vbs`, `.wsf`.

Verified: pwsh passing `a" "b` to a **direct exe** → `a" "b` (kept); via **`cmd.exe`** → `a b` (quotes stripped). So `cmd /c …` and batch files from modern PowerShell are still subject to the old corruption — only direct exes (`ssh.exe`, `git.exe`, …) get the fix.

### Stop-parsing token `--%` ✓

`--%` after an executable passes the rest of the line verbatim — except it still performs cmd-style `%VAR%` expansion. Verified: `... --% $x %TEMP%` passed `$x` literally (no PowerShell expansion) but expanded `%TEMP%`. `%%` is not supported; undefined `%name%` passes through; redirection after `--%` is passed as a literal argument.

## The underlying CRT rule (why backslashes matter)

When any program receives its command line, the Microsoft C/C++ runtime parses argv using these rules (daviddeley reference):

- **Rule 6:** an *even* number of backslashes followed by `"` → one backslash in argv per pair, and the `"` is a string delimiter.
- **Rule 7:** an *odd* number of backslashes followed by `"` → one backslash per pair, and the final backslash escapes the `"`, putting a literal `"` in argv.

This `2n`-backslash rule is why `Legacy` mode corrupts trailing-backslash-before-quote: the backslash that should be literal gets consumed as an escape. It's also why correct quoting of a Windows path that ends in `\` requires doubling the trailing backslashes before a closing quote.

## Line endings (CRLF) ✓

A Windows-authored script saved with CRLF (`\r\n`) fails to execute on Linux/WSL: the `\r` becomes part of the shebang interpreter path (`/bin/bash\r`), which doesn't exist. Verified via byte dump (`#!/bin/bash\r\n`) — the script never ran while an LF control ran fine. Error wording is version-dependent: modern WSL says `cannot execute: required file not found`; the classic phrasing is `/bin/bash^M: bad interpreter: No such file or directory`. Always normalize generated scripts to LF before sending them to a Linux/WSL host.

**Fix / prevent:**
- Repair an affected file: `sed -i 's/\r$//' script.sh`, or `dos2unix script.sh`, or `tr -d '\r' < in.sh > out.sh`.
- Prevent at the source: `git config --global core.autocrlf input`, a `.gitattributes` entry `*.sh text eol=lf`, and set your editor to write LF for shell scripts.
