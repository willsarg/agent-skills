# SSH, WSL, and Output Streams on Windows

Claims marked ✓ verified live on Windows 11 + OpenSSH_for_Windows_9.5p2 + WSL2 Ubuntu 24.04.

## How Win32-OpenSSH executes a remote command

- The remote login shell is set by the registry value `HKLM\SOFTWARE\OpenSSH\DefaultShell`. If unset, the built-in default is **cmd.exe** ✓. `DefaultShellCommandOption` sets the switch (e.g. `/c`); `DefaultShellEscapeArguments` controls argument escaping for non-standard shells.
- With the default shell, sshd invokes **`cmd.exe /c "<your command>"` — WITH outer quotes** ✓. Confirmed by reading cmd's own launch line: `ssh host "echo %CMDCMDLINE%"` returns `"...cmd.exe" /c "echo %CMDCMDLINE%"`.
- Unquoted metacharacters like `&`/`|` still act at the remote cmd layer — not because sshd omits quotes, but because **cmd's `/c` rule strips those outer quotes when the command contains special chars** (`&<>()@^|`). See `cmd /?`.
- Practical consequence: a command string you send is parsed by cmd on the remote side. All the cmd rules in `quoting-and-parsing.md` apply remotely.

### PowerShell as the default shell (untested caveat)

If a host's `DefaultShell` is set to PowerShell instead of cmd, the remote escaping regime changes (no `%VAR%`, different quoting; sshd uses a different command option). This was **not** verified live (it requires writing the registry on the target). Before trusting it, re-probe with `[Environment]::CommandLine` to see exactly how your command arrived.

## Host key verification

- A "Host key verification failed" error is frequently NOT a security problem — it's that `known_hosts` trusts the host's keys under one identity (e.g. the bare IP) but not the one you're connecting as (e.g. the hostname), or vice-versa. Compare the offered key (`ssh-keyscan host`) against your stored entry (`ssh-keygen -F host` / `ssh-keygen -F <ip>`); if the fingerprints match an already-trusted entry, add the missing alias.
- **Do not blanket-disable checking.** `-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null` defeats man-in-the-middle protection and should never be a default. Add the verified key once. On a Windows *local* client the null device is `NUL`, not `/dev/null`.

## Reaching WSL

- SSH to a Windows box lands in Windows OpenSSH (cmd or PowerShell), **not** WSL. WSL is a separate Linux environment with its own filesystem, users, and only-if-you-start-one sshd.
- Get an interactive WSL shell: `ssh -t <host> wsl.exe -d <Distro>` (the `-t` forces a TTY; drop it for one-off commands). List distros with `wsl.exe -l -v`.
- A distro that is "Stopped" starts on demand when you run a command in it.
- Tip: when sending a WSL command that contains shell metacharacters (`|`, `>`), wrap the whole `wsl.exe …` invocation inside a `powershell -EncodedCommand` payload so the intermediate cmd layer never sees the metacharacters — cmd does not respect the single quotes you'd use to protect a bash command.

## Output streams

- **PowerShell emits .NET objects, not text.** Running `grep`/`awk` against PowerShell output yields type names or width-wrapped tables. Force plain text with `| Out-String -Stream`, or get machine-parseable output with `| ConvertTo-Json -Compress`.
- **CLIXML / progress noise** (`#< CLIXML …<progress>… "Preparing modules for first use" …`) can leak into captured stdout, especially when one PowerShell consumes another's piped output. It is **intermittent — primarily a cold-start / first-use artifact** ✓ (it appeared on a session's first PowerShell calls and could not be reproduced once warm). `$ProgressPreference = 'SilentlyContinue'` is the documented suppressor for progress-driven noise (e.g. `Invoke-WebRequest` download bars); it won't retro-suppress startup module-prep that fires before your first line.
- **Exit codes:** for external commands check `$LASTEXITCODE`; for native PowerShell cmdlets check `$?` (or wrap in `try { } catch { exit 1 }`). Bash `$?`/`$IFS` semantics do not carry over.

## Null redirection

- cmd: `> nul 2>&1`
- PowerShell: `| Out-Null` or `… > $null`
- Not `/dev/null` (that's a POSIX path).
