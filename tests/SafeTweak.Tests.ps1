# Self-check for backup/undo logic on a throwaway registry branch, plus a dry run of every tweak.
# Run: powershell -NoProfile -ExecutionPolicy Bypass -File .\tests\SafeTweak.Tests.ps1   (no admin needed)
$ErrorActionPreference = 'Stop'
$scriptPath = Join-Path $PSScriptRoot '..\SafeTweak.ps1'
. $scriptPath

$root = 'HKCU:\Software\SafeTweakTest'
$script:BackupFile = Join-Path $env:TEMP "SafeTweakTest-$PID\backup.json"
$script:Failures = 0

function Assert([bool]$Condition, [string]$Message) {
    if ($Condition) { Write-Host "ok   - $Message" -ForegroundColor Green }
    else { Write-Host "FAIL - $Message" -ForegroundColor Red; $script:Failures++ }
}
function Get-Val($Name) { (Get-ItemProperty -LiteralPath $root -Name $Name -ErrorAction SilentlyContinue).$Name }

try {
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
    New-Item $root -Force | Out-Null
    New-ItemProperty $root -Name Existing -Value 5 -PropertyType DWord | Out-Null
    New-ItemProperty $root -Name Bin -Value ([byte[]](1, 2, 3)) -PropertyType Binary | Out-Null
    New-ItemProperty $root -Name Str -Value 'hello' -PropertyType String | Out-Null
    New-ItemProperty $root -Name Multi -Value ([string[]]('a', 'b')) -PropertyType MultiString | Out-Null

    # dry run changes nothing
    $script:DryRun = $true
    Set-RegValue $root 'Existing' 1
    Set-RegValue $root 'Missing' 7
    Assert ((Get-Val Existing) -eq 5) 'dry run keeps the value'
    Assert ($null -eq (Get-Val Missing)) 'dry run creates nothing'
    Assert (-not (Test-Path $script:BackupFile)) 'dry run writes no backup'

    # real changes are backed up
    $script:DryRun = $false
    Set-RegValue $root 'Existing' 1
    Set-RegValue $root 'Missing' 7
    Set-RegValue $root 'Bin' ([byte[]](9, 9)) 'Binary'
    Set-RegValue $root 'Str' 'changed' 'String'
    Set-RegValue $root 'Multi' ([string[]]('x')) 'MultiString'
    Set-RegValue "$root\NewKey" 'Deep' 1
    Assert ((Get-Val Existing) -eq 1) 'value changed'
    Assert ((Get-Val Missing) -eq 7) 'value created'
    Assert (@(Read-Backup).Count -eq 6) 'six entries backed up'

    # changing again keeps the first original
    Set-RegValue $root 'Existing' 2
    $entry = @(Read-Backup) | Where-Object Name -eq 'Existing'
    Assert (@(Read-Backup).Count -eq 6 -and $entry.Value -eq 5) 'second change keeps original 5'

    # startup flag on a fake item
    Disable-StartupItem ([pscustomobject]@{ Name = 'FakeApp'; Approved = "$root\Approved" })
    $flag = (Get-ItemProperty "$root\Approved").FakeApp
    Assert ($flag[0] -eq 3 -and $flag.Count -eq 12) 'startup item flagged disabled (03 + 11 bytes)'

    # undo restores everything, with original types
    Undo-All
    $key = Get-Item $root
    Assert ((Get-Val Existing) -eq 5 -and $key.GetValueKind('Existing') -eq 'DWord') 'DWord restored'
    Assert ($key.GetValueNames() -notcontains 'Missing') 'created value removed'
    Assert ((@(Get-Val Bin) -join ',') -eq '1,2,3' -and $key.GetValueKind('Bin') -eq 'Binary') 'Binary restored'
    Assert ((Get-Val Str) -eq 'hello') 'String restored'
    Assert ((@(Get-Val Multi) -join ',') -eq 'a,b' -and $key.GetValueKind('Multi') -eq 'MultiString') 'MultiString restored'
    Assert ($null -eq (Get-ItemProperty "$root\Approved").FakeApp) 'startup flag removed'
    Assert ($null -eq (Get-ItemProperty "$root\NewKey").Deep) 'value in new key removed'
    Assert (-not (Test-Path $script:BackupFile)) 'backup archived after undo'
    Undo-All  # second undo is a no-op
    Assert ((Get-Val Existing) -eq 5) 'second undo is harmless'

    # dry run of every real tweak, in-process and through the command line
    $script:DryRun = $true
    foreach ($name in 'Temp', 'Telemetry', 'Power', 'Visual') { Invoke-Tweak $name }
    Invoke-Tweak 'Startup' @()
    $null = @(Get-StartupItems)
    Assert (-not (Test-Path $script:BackupFile)) 'dry run of all tweaks writes no backup'

    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -DryRun -Apply 'Temp,Telemetry,Power,Visual' -BackupFile $script:BackupFile | Out-Host
    Assert ($LASTEXITCODE -eq 0) 'command-line dry run exits 0'
    & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $scriptPath -DryRun -Undo -BackupFile $script:BackupFile | Out-Host
    Assert ($LASTEXITCODE -eq 0) 'command-line dry-run undo exits 0'
    Assert (-not (Test-Path $script:BackupFile)) 'command-line dry run writes no backup'

    # the GUI markup parses
    . (Join-Path $PSScriptRoot '..\gui.ps1')
    $window = [Windows.Markup.XamlReader]::Parse($script:Xaml)
    Assert ($null -ne $window.FindName('btnApply')) 'GUI XAML loads'
    $script:Ui = @{ Window = $window }
    Set-Theme $true
    Assert ("$($window.Resources['Surface'].Color)" -eq '#FF141218') 'dark theme swaps the palette'
} finally {
    if (Test-Path $root) { Remove-Item $root -Recurse -Force }
    Remove-Item (Split-Path $script:BackupFile) -Recurse -Force -ErrorAction SilentlyContinue
}

if ($script:Failures) { Write-Host "$($script:Failures) check(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All checks passed' -ForegroundColor Green
