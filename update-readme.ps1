# Refreshes the "Recently" line in the profile README from repos pushed in the last 30 days.
# Runs daily via Task Scheduler. Commits only when the line actually changes.
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

git pull --quiet --rebase

$cutoff = (Get-Date).ToUniversalTime().AddDays(-30)
$repos = gh repo list Axio112 --limit 100 --json name,pushedAt,isFork |
    ConvertFrom-Json |
    Where-Object { $_.name -ne 'Axio112' -and [datetime]$_.pushedAt -gt $cutoff } |
    Sort-Object { [datetime]$_.pushedAt } -Descending |
    Select-Object -First 4

$line = if ($repos) {
    ($repos | ForEach-Object { "**$($_.name)** ($(([datetime]$_.pushedAt).ToString('MMM d', [cultureinfo]'en-US')))" }) -join ' · '
} else { '_heads-down on something new_' }

$readme = Get-Content README.md -Raw
$updated = [regex]::Replace($readme, '(?s)<!--RECENT:START-->.*?<!--RECENT:END-->', "<!--RECENT:START-->$line<!--RECENT:END-->")

if ($updated -ne $readme) {
    [IO.File]::WriteAllText("$PSScriptRoot\README.md", $updated)
    git add README.md
    git commit --quiet -m "chore: refresh recent activity"
    git push --quiet
    Write-Output "Updated: $line"
} else {
    Write-Output 'No change.'
}
