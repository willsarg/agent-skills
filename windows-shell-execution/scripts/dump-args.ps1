<#
.SYNOPSIS
    Diagnostic argv dumper for Windows shell/SSH quoting problems.

.DESCRIPTION
    Prints each argument it received, wrapped in <angle markers> so leading/
    trailing whitespace and empty strings are visible, plus the count and the
    current PowerShell argument-passing mode. Use it to see EXACTLY how an
    argument list survives your local shell -> ssh -> cmd/PowerShell -> exe
    parsing chain, instead of guessing.

    Invoke with -File so PowerShell does not re-parse expressions:

        powershell -NoProfile -File dump-args.ps1 alpha "beta gamma" 'a"b' ""

    Over SSH (sidesteps the local-shell parsing problem with base64). Build the
    UTF-16LE base64 of a small PowerShell snippet that calls this script, then
    run  powershell -NoProfile -EncodedCommand <base64> . To build the base64:

        # Linux/macOS client:
        printf '%s' '<powershell source>' | iconv -f UTF-8 -t UTF-16LE | base64 | tr -d '\n'
        # PowerShell:
        [Convert]::ToBase64String([Text.Encoding]::Unicode.GetBytes('<powershell source>'))

    Limitation: this dumps the PowerShell-side argv only. It does not show how
    cmd.exe tokenized a line or what a non-PowerShell exe's CRT received — for
    those, reason from the cmd rules and the CRT backslash rules (Rule 6/7) in
    references/quoting-and-parsing.md.

    Output is plain text to stdout, one line per argument:

        [0]=<alpha>
        [1]=<beta gamma>
        [2]=<a"b>
        [3]=<>
        COUNT=4
        PSVersion=5.1.26100.8655
        ArgPassingMode=Legacy(5.1)

.NOTES
    No external dependencies. Works on Windows PowerShell 5.1 and PowerShell 7+.
#>

$i = 0
foreach ($a in $args) {
    "[$i]=<$a>"
    $i++
}
"COUNT=$($args.Count)"
"PSVersion=$($PSVersionTable.PSVersion)"
if (Test-Path variable:PSNativeCommandArgumentPassing) {
    "ArgPassingMode=$PSNativeCommandArgumentPassing"
} else {
    "ArgPassingMode=Legacy(5.1)"
}
