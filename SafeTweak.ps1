#Requires -Version 5.1
<#
.SYNOPSIS
    SafeTweak - a small, honest Windows 10/11 tweaker. Every change is backed up and can be rolled back.
.EXAMPLE
    powershell -ExecutionPolicy Bypass -File .\SafeTweak.ps1                          # Material 3 GUI
    powershell -ExecutionPolicy Bypass -File .\SafeTweak.ps1 -DryRun -Apply Telemetry,Visual
    powershell -ExecutionPolicy Bypass -File .\SafeTweak.ps1 -Undo
#>
[CmdletBinding()]
param(
    [string[]]$Apply,
    [switch]$Undo,
    [switch]$DryRun,
    [switch]$NoRestorePoint,
    [string]$BackupFile = (Join-Path $env:ProgramData 'SafeTweak\backup.json')
)

$ErrorActionPreference = 'Stop'
$script:Version = '1.0.0'
$script:DryRun = [bool]$DryRun
$script:NoRestorePoint = [bool]$NoRestorePoint
$script:BackupFile = $BackupFile
$script:RestorePointDone = $false
$script:LogSink = $null   # GUI sets this to a scriptblock that receives each log line

$Tweaks = [ordered]@{
    Temp      = 'Clean temp files older than 24 hours'
    Telemetry = 'Reduce telemetry and ad personalization'
    Startup   = 'Disable selected startup apps'
    Power     = 'High performance power plan'
    Visual    = 'Turn off visual effects (best performance)'
}

function Write-Log([string]$Message) {
    if ($script:LogSink) { & $script:LogSink $Message } else { Write-Host $Message }
}

function Test-Admin {
    ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
        [Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Confirm-Continue([string]$Question) {
    if ($script:LogSink) {
        Add-Type -AssemblyName PresentationFramework
        return [Windows.MessageBox]::Show($Question, 'SafeTweak', 'YesNo', 'Warning') -eq 'Yes'
    }
    return (Read-Host "$Question [y/N]") -match '^[yY]'
}

#region Backup file: a JSON list of original values, newest last
function Read-Backup {
    if (-not (Test-Path -LiteralPath $script:BackupFile)) { return @() }
    $raw = Get-Content -LiteralPath $script:BackupFile -Raw
    if (-not $raw -or -not $raw.Trim()) { return @() }
    $data = $raw | ConvertFrom-Json
    return @($data)
}

function Save-Backup([object[]]$Entries) {
    $dir = Split-Path -Parent $script:BackupFile
    if (-not (Test-Path -LiteralPath $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    ConvertTo-Json -InputObject @($Entries) -Depth 5 | Set-Content -LiteralPath $script:BackupFile -Encoding UTF8
}

function Add-BackupEntry($Entry) {
    $all = @(Read-Backup)
    if ($all | Where-Object { $_.Id -eq $Entry.Id }) { return }  # keep the very first original, not an already-tweaked value
    Save-Backup ($all + $Entry)
}
#endregion

#region Registry
function Format-Value($Value) {
    if ($Value -is [array]) { return ($Value | ForEach-Object { '{0:X2}' -f $_ }) -join ' ' }
    return "$Value"
}

function Get-RegState([string]$Path, [string]$Name) {
    $key = Get-Item -LiteralPath $Path -ErrorAction SilentlyContinue
    if ($key -and ($key.GetValueNames() -contains $Name)) {
        return [pscustomobject]@{
            Existed = $true
            Value   = $key.GetValue($Name, $null, 'DoNotExpandEnvironmentNames')
            Type    = $key.GetValueKind($Name).ToString()
        }
    }
    [pscustomobject]@{ Existed = $false; Value = $null; Type = $null }
}

function Set-RegValue([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    $old = Get-RegState $Path $Name
    if ($old.Existed -and $old.Type -eq $Type -and (Format-Value $old.Value) -ceq (Format-Value $Value)) {
        Write-Log "  $Path\$Name : already $(Format-Value $Value)"; return
    }
    $change = "$Path\$Name : $(if ($old.Existed) { Format-Value $old.Value } else { '<absent>' }) -> $(Format-Value $Value)"
    if ($script:DryRun) { Write-Log "  [dry-run] $change"; return }
    Add-BackupEntry ([pscustomobject]@{
        Id = "reg|$Path|$Name"; Kind = 'Reg'; Path = $Path; Name = $Name
        Existed = $old.Existed; Value = $old.Value; Type = $old.Type
    })
    if (-not (Test-Path -LiteralPath $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -LiteralPath $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
    Write-Log "  $change"
}

function Restore-RegEntry($Entry) {
    if ($Entry.Existed) {
        $value = switch ($Entry.Type) {
            'Binary'      { [byte[]]@($Entry.Value) }
            'MultiString' { [string[]]@($Entry.Value) }
            default       { $Entry.Value }
        }
        if (-not (Test-Path -LiteralPath $Entry.Path)) { New-Item -Path $Entry.Path -Force | Out-Null }
        New-ItemProperty -LiteralPath $Entry.Path -Name $Entry.Name -Value $value -PropertyType $Entry.Type -Force | Out-Null
    } elseif (Test-Path -LiteralPath $Entry.Path) {
        Remove-ItemProperty -LiteralPath $Entry.Path -Name $Entry.Name -ErrorAction SilentlyContinue
    }
}

# Services are switched through their registry Start value, so the exact original (incl. delayed start) is restored.
function Disable-ServiceSafe([string]$Name) {
    $key = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
    if (-not (Test-Path -LiteralPath $key)) { Write-Log "  service $Name not found, skipped"; return }
    Set-RegValue $key 'Start' 4
    if (-not $script:DryRun) { Stop-Service -Name $Name -Force -ErrorAction SilentlyContinue }
}
#endregion

#region Restore point
function New-SafeRestorePoint {
    if ($script:DryRun -or $script:NoRestorePoint -or $script:RestorePointDone) { return }
    Write-Log 'Creating a system restore point (can take a minute)...'
    try {
        # Windows silently skips it if another point was made in the last 24 hours.
        Checkpoint-Computer -Description "SafeTweak $script:Version" -RestorePointType MODIFY_SETTINGS -ErrorAction Stop
        Write-Log '  restore point requested'
    } catch {
        Write-Log "  could not create a restore point: $($_.Exception.Message)"
        if (-not (Confirm-Continue 'Could not create a restore point (is System Protection on?). The SafeTweak backup still works. Continue?')) {
            throw 'Cancelled: no restore point.'
        }
    }
    $script:RestorePointDone = $true
}
#endregion

#region Tweaks
function Get-TempFiles([string]$Dir) {
    foreach ($item in Get-ChildItem -LiteralPath $Dir -Force -ErrorAction SilentlyContinue) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }  # never follow links out of the temp folder
        if ($item.PSIsContainer) { Get-TempFiles $item.FullName } else { $item }
    }
}

function Clear-TempFiles {
    $cutoff = (Get-Date).AddDays(-1)  # fresh files may belong to a running installer
    $bytes = 0; $count = 0
    foreach ($dir in @($env:TEMP, (Join-Path $env:SystemRoot 'Temp')) | Select-Object -Unique) {
        foreach ($file in Get-TempFiles $dir | Where-Object { $_.LastWriteTime -lt $cutoff }) {
            if (-not $script:DryRun) {
                try { Remove-Item -LiteralPath $file.FullName -Force -ErrorAction Stop } catch { continue }  # in use
            }
            $bytes += $file.Length; $count++
        }
    }
    $verb = if ($script:DryRun) { '[dry-run] would delete' } else { 'deleted' }
    Write-Log ('  {0} {1} files, {2:N1} MB' -f $verb, $count, ($bytes / 1MB))
}

function Disable-Telemetry {
    # On Home/Pro 0 means "Required diagnostic data", the lowest level these editions allow.
    Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' 'Enabled' 0
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Privacy' 'TailoredExperiencesWithDiagnosticDataEnabled' 0
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'Start_TrackProgs' 0
    Disable-ServiceSafe 'DiagTrack'
}

$StartupSources = @(
    @{ Run = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Run'
       Approved = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
    @{ Run = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
       Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run' }
    @{ Run = 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Run'
       Approved = 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\StartupApproved\Run32' }
)

# shortcut: covers Run registry keys only, not the Startup folder or scheduled tasks; add those if users ask.
function Get-StartupItems {
    foreach ($src in $StartupSources) {
        $key = Get-Item -LiteralPath $src.Run -ErrorAction SilentlyContinue
        if (-not $key) { continue }
        foreach ($name in $key.GetValueNames() | Where-Object { $_ }) {
            $state = Get-RegState $src.Approved $name
            [pscustomobject]@{
                Name     = $name
                Command  = "$($key.GetValue($name))"
                Approved = $src.Approved
                Enabled  = -not ($state.Existed -and (@($state.Value)[0] -band 1))  # odd first byte = disabled
            }
        }
    }
}

# Same flag Task Manager uses, so the app can also be re-enabled from Task Manager.
function Disable-StartupItem($Item) {
    Set-RegValue $Item.Approved $Item.Name ([byte[]](3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0)) 'Binary'
}

function Invoke-StartupTweak([object[]]$Selected) {
    if ($null -eq $Selected) {
        $items = @(Get-StartupItems | Where-Object Enabled)
        if (-not $items) { Write-Log '  no enabled startup apps found'; return }
        for ($i = 0; $i -lt $items.Count; $i++) { Write-Log ('  [{0}] {1}  ({2})' -f ($i + 1), $items[$i].Name, $items[$i].Command) }
        $answer = Read-Host 'Numbers to disable, e.g. 1,3 (Enter = none)'
        $Selected = foreach ($n in $answer -split '[,\s]+' | Where-Object { $_ -match '^\d+$' }) {
            if ([int]$n -ge 1 -and [int]$n -le $items.Count) { $items[[int]$n - 1] }
        }
    }
    if (-not $Selected) { Write-Log '  nothing selected'; return }
    foreach ($item in $Selected) { Disable-StartupItem $item }
}

$HighPerformance = '8c5e7fda-e8bf-4a96-9a85-cf48e3d7a4c8'

function Get-ActivePowerScheme {
    if ("$(powercfg /getactivescheme)" -match '[0-9a-fA-F]{8}(-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}') { return $Matches[0] }
}

function Set-HighPerformance {
    if (-not ((powercfg /list) -match $HighPerformance)) {
        Write-Log '  High performance plan is not available here (normal on Modern Standby laptops), skipped'
        return
    }
    $current = Get-ActivePowerScheme
    if ($current -eq $HighPerformance) { Write-Log '  already active'; return }
    if ($script:DryRun) { Write-Log "  [dry-run] power plan : $current -> $HighPerformance"; return }
    Add-BackupEntry ([pscustomobject]@{ Id = 'power'; Kind = 'Power'; Value = $current })
    powercfg /setactive $HighPerformance
    Write-Log "  power plan : $current -> $HighPerformance"
}

function Disable-VisualEffects {
    $explorer = 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer'
    Set-RegValue "$explorer\VisualEffects" 'VisualFXSetting' 3  # 3 = "Custom", the values below
    Set-RegValue 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90, 0x12, 0x03, 0x80, 0x10, 0, 0, 0)) 'Binary'
    Set-RegValue 'HKCU:\Control Panel\Desktop\WindowMetrics' 'MinAnimate' '0' 'String'
    Set-RegValue "$explorer\Advanced" 'TaskbarAnimations' 0
    Set-RegValue "$explorer\Advanced" 'ListviewAlphaSelect' 0
    Set-RegValue "$explorer\Advanced" 'ListviewShadow' 0
    Set-RegValue 'HKCU:\Software\Microsoft\Windows\DWM' 'EnableAeroPeek' 0
    Write-Log '  sign out and back in to see all of it'
}

function Invoke-Tweak([string]$Name, [object[]]$StartupSelection) {
    Write-Log "== $($Tweaks[$Name]) =="
    if ($Name -ne 'Temp') { New-SafeRestorePoint }
    switch ($Name) {
        'Temp'      { Clear-TempFiles }
        'Telemetry' { Disable-Telemetry }
        'Startup'   { Invoke-StartupTweak $StartupSelection }
        'Power'     { Set-HighPerformance }
        'Visual'    { Disable-VisualEffects }
    }
}
#endregion

#region Undo
function Undo-All {
    $all = @(Read-Backup)
    if (-not $all) { Write-Log 'Nothing to roll back.'; return }
    Write-Log "== Roll back $($all.Count) change(s) =="
    [array]::Reverse($all)
    $failed = @()
    foreach ($e in $all) {
        $what = if ($e.Kind -eq 'Power') { "power plan -> $($e.Value)" }
                elseif ($e.Existed) { "$($e.Path)\$($e.Name) -> $(Format-Value $e.Value)" }
                else { "$($e.Path)\$($e.Name) -> <removed>" }
        if ($script:DryRun) { Write-Log "  [dry-run] $what"; continue }
        try {
            if ($e.Kind -eq 'Power') { powercfg /setactive $e.Value } else { Restore-RegEntry $e }
            Write-Log "  $what"
        } catch {
            Write-Log "  FAILED $what : $($_.Exception.Message)"
            $failed += $e
        }
    }
    if ($script:DryRun) { return }
    Move-Item -LiteralPath $script:BackupFile -Destination "$($script:BackupFile).restored-$(Get-Date -Format yyyyMMdd-HHmmss)"
    if ($failed) {
        [array]::Reverse($failed)
        Save-Backup $failed
        Write-Log "$($failed.Count) change(s) could not be restored and stay in the backup file."
    } else {
        Write-Log 'Done. Reboot to make sure services and effects are back to normal.'
    }
}
#endregion

if ($MyInvocation.InvocationName -eq '.') { return }  # dot-sourced by tests: load functions only

$Apply = @($Apply -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })  # -File passes "a,b" as one string
foreach ($name in $Apply) {
    if (-not $Tweaks.Contains($name)) { throw "Unknown tweak '$name'. Valid: $($Tweaks.Keys -join ', ')" }
}

$gui = -not $Apply -and -not $Undo
if (-not (Test-Admin) -and -not $script:DryRun) {
    Write-Host 'Administrator rights are required. Relaunching elevated...'
    $argList = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', "`"$PSCommandPath`"")
    if ($Apply) { $argList += '-Apply', ($Apply -join ',') }
    if ($Undo) { $argList += '-Undo' }
    if ($NoRestorePoint) { $argList += '-NoRestorePoint' }
    if ($PSBoundParameters.ContainsKey('BackupFile')) { $argList += '-BackupFile', "`"$BackupFile`"" }
    if (-not $gui) { $argList = @('-NoExit') + $argList }  # keep the console open to read the result
    Start-Process powershell.exe -Verb RunAs -ArgumentList $argList
    return
}

if ($gui) { . (Join-Path $PSScriptRoot 'gui.ps1'); Show-SafeTweakWindow; return }
if ($Undo) { Undo-All }
foreach ($name in $Apply) { Invoke-Tweak $name }
