# Contributing

## Before opening a pull request

1. Create a short-lived branch from `main`.
2. Keep the change focused on one deployment tool or one documentation issue.
3. Do not commit credentials, private server details, generated backups, or
   downloaded packages.
4. Update the affected README when behavior or commands change.

Use Conventional Commits, for example:

```text
feat(bettafish): add offline package validation
fix(windows): quote paths containing spaces
docs(all): clarify Docker requirements
```

## Local verification

Check all Bash scripts:

```bash
find . -type f \( -name '*.sh' -o -name '*.sh.template' \) -print0 |
  while IFS= read -r -d '' file; do bash -n "$file"; done
```

Check PowerShell syntax on a machine with PowerShell 7:

```powershell
Get-ChildItem -Recurse -Filter *.ps1 | ForEach-Object {
  $tokens = $null
  $errors = $null
  [System.Management.Automation.Language.Parser]::ParseFile(
    $_.FullName,
    [ref]$tokens,
    [ref]$errors
  ) | Out-Null
  if ($errors.Count -gt 0) { throw "Parse failed: $($_.FullName)" }
}
```

Also run `git diff --check`. Describe the tested operating system, Docker
version, commands, observed result, and rollback method in the pull request.
