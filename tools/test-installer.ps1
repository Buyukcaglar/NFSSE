param(
    [Parameter(Mandatory = $true)][string]$Kit,
    [Parameter(Mandatory = $true)][string]$SourceMedia,
    [string]$OutputRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$Kit = (Resolve-Path -LiteralPath $Kit).Path
$SourceMedia = (Resolve-Path -LiteralPath $SourceMedia).Path
if (-not $OutputRoot) { $OutputRoot = Join-Path $repo ('build\installer-test-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss')) }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
if (Test-Path -LiteralPath $OutputRoot) { throw 'Use a fresh test output folder.' }
[IO.Directory]::CreateDirectory($OutputRoot) | Out-Null
$shell = Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe'

function Hash([string]$Path) { return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant() }
function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
function Run-Installer([string]$Package, [string]$Media, [string]$Target, [string]$TestName, [bool]$Success) {
    $savedPreference = $ErrorActionPreference
    try {
        $ErrorActionPreference = 'Continue'
        $output = & $shell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $Package 'Install-NFSSE.ps1') -SourceMedia $Media -Destination $Target -NonInteractive 2>&1
        $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $savedPreference }
    $output | Out-String | Set-Content -LiteralPath (Join-Path $OutputRoot "$TestName.log") -Encoding UTF8
    Assert (($code -eq 0) -eq $Success) "Unexpected exit code for $TestName : $code"
}

$originalHash = Hash (Join-Path $SourceMedia 'NFS_WIN.EXE')
$destination = Join-Path $OutputRoot 'game'
Run-Installer $Kit $SourceMedia $destination 'fresh-install' $true
$exeHash = Hash (Join-Path $destination 'NFSSE.exe')
Assert ($exeHash -eq 'a962a27077a31748f860160dc84699cc46fe03b2c3d04287d07a0c88479c9ddd') 'Generated executable differs from accepted build.'
$assetCount = 0
foreach ($folder in @('FRONTEND', 'SIMDATA')) {
    foreach ($file in Get-ChildItem -LiteralPath (Join-Path $SourceMedia $folder) -Recurse -File) {
        $relative = $file.FullName.Substring($SourceMedia.TrimEnd('\').Length + 1)
        Assert ((Hash $file.FullName) -eq (Hash (Join-Path $destination $relative))) "Asset mismatch: $relative"
        $assetCount++
    }
}
Assert ($assetCount -eq 1228) 'Unexpected number of media assets.'
$raceSpeech = @('FINALLAP.EAS', 'BESTTIME.EAS', 'FIRST.EAS', 'SECOND.EAS', 'THIRD.EAS',
    'FOURTH.EAS', 'FIFTH.EAS', 'SIXTH.EAS', 'SEVENTH.EAS', 'EIGHTH.EAS', 'BESTLAST.EAS')
foreach ($name in $raceSpeech) {
    Assert ((Hash (Join-Path $SourceMedia "FRONTEND\SPEECH\$name")) -eq (Hash (Join-Path $destination $name))) "Missing or incorrect root race speech: $name"
}
Assert ((Hash (Join-Path $SourceMedia 'IFORCE.DLL')) -eq (Hash (Join-Path $destination 'IFORCE.DLL'))) 'I-Force DLL changed.'
Assert ((Hash (Join-Path $Kit 'runtime\NFSPortable.dll')) -eq (Hash (Join-Path $destination 'NFSPortable.dll'))) 'Helper mismatch.'
Assert ((Hash (Join-Path $Kit 'runtime\ddraw.dll')) -eq (Hash (Join-Path $destination 'ddraw.dll'))) 'Renderer mismatch.'
$pathBytes = [IO.File]::ReadAllBytes((Join-Path $destination 'GAMEDATA\CONFIG\PATHS.DAT'))
Assert ($pathBytes.Length -eq 1520) 'Invalid path table size.'
for ($i = 0; $i -lt 19; $i++) {
    $path = [Text.Encoding]::ASCII.GetString($pathBytes, $i * 80, 80).TrimEnd([char]0)
    Assert ($path.Length -gt 0 -and -not [IO.Path]::IsPathRooted($path) -and (Test-Path -LiteralPath (Join-Path $destination $path) -PathType Container)) "Invalid path record $i"
}
$initialConfig = [IO.File]::ReadAllText((Join-Path $destination 'nfs.cfg'))
Assert ($initialConfig -eq "YESSOUND HIGHVIDEO ENGLISH NOREMOTE `r`n") 'Legacy configuration token spacing changed.'

$savePath = Join-Path $destination 'GAMEDATA\SAVEGAME\NFSSE-SMOKE.SAV'
[IO.File]::WriteAllText($savePath, 'Installer preservation sentinel')
[IO.File]::AppendAllText((Join-Path $destination 'ddraw.ini'), "`r`n; Installer test sentinel`r`n")
[IO.File]::WriteAllText((Join-Path $destination 'nfs.cfg'), "NOSOUND HIGHVIDEO ENGLISH NOREMOTE `r`n")
$existingSpeech = Join-Path $destination 'FIRST.EAS'
[IO.File]::WriteAllText($existingSpeech, 'Existing race speech preservation sentinel')
# Model an older installation missing announcer clips, while retaining one
# existing clip to verify reinstall preserves existing game data.
foreach ($name in $raceSpeech) {
    if ($name -ne 'FIRST.EAS') { [IO.File]::Delete((Join-Path $destination $name)) }
}
$preserved = @{}
foreach ($path in @($savePath, (Join-Path $destination 'nfs.cfg'), (Join-Path $destination 'ddraw.ini'), $existingSpeech)) { $preserved[$path] = Hash $path }
foreach ($name in @('IFORCE.DLL', 'NFSICONN.ICO', 'DPLAY.dll', 'ddraw.dll')) {
    $path = Join-Path $destination $name
    [IO.File]::SetAttributes($path, ([IO.File]::GetAttributes($path) -bor [IO.FileAttributes]::ReadOnly))
}
Run-Installer $Kit $SourceMedia $destination 'reinstall' $true
foreach ($path in $preserved.Keys) { Assert ((Hash $path) -eq $preserved[$path]) 'Reinstall changed user data.' }
foreach ($name in $raceSpeech) {
    if ($name -ne 'FIRST.EAS') {
        Assert ((Hash (Join-Path $SourceMedia "FRONTEND\SPEECH\$name")) -eq (Hash (Join-Path $destination $name))) "Reinstall did not restore race speech: $name"
    }
}
foreach ($name in @('IFORCE.DLL', 'NFSICONN.ICO', 'DPLAY.dll', 'ddraw.dll')) {
    Assert (([IO.File]::GetAttributes((Join-Path $destination $name)) -band [IO.FileAttributes]::ReadOnly) -eq 0) 'Managed media component remains read-only.'
}

# Older kits preserved a global display configuration without these keys.
# Exercise the real packaged installer, including another game's overrides.
$graphicsPath = Join-Path $destination 'ddraw.ini'
$legacyGraphics = [regex]::Replace([IO.File]::ReadAllText($graphicsPath), '(?im)^(toggle_borderless|adjmouse)=.*\r?\n', '')
$legacyGraphics = $legacyGraphics.Replace('border=true', 'border=false')
$legacyGraphics += "`r`n[OtherGame]`r`ntoggle_borderless=false`r`nadjmouse=false`r`nborder=false`r`n"
[IO.File]::WriteAllText($graphicsPath, $legacyGraphics)
Run-Installer $Kit $SourceMedia $destination 'legacy-display-upgrade' $true
$updatedGraphics = [IO.File]::ReadAllText($graphicsPath)
Assert ($updatedGraphics.Contains("toggle_borderless=true`r`nadjmouse=true`r`n[OtherGame]")) 'Legacy display keys were not added to the global section.'
Assert ($updatedGraphics.Contains("; Installer test sentinel") -and $updatedGraphics.Contains('renderer=gdi')) 'Display upgrade lost custom configuration.'
Assert ($updatedGraphics.Contains("border=true")) 'Legacy border=false was not upgraded.'
Assert ($updatedGraphics.EndsWith("[OtherGame]`r`ntoggle_borderless=false`r`nadjmouse=false`r`nborder=false`r`n")) 'Display upgrade changed another game section.'
Assert ([IO.File]::ReadAllText($graphicsPath + '.before-input-update.bak') -eq $legacyGraphics) 'Display upgrade lost its original configuration backup.'
foreach ($path in @($savePath, (Join-Path $destination 'nfs.cfg'), $existingSpeech)) {
    Assert ((Hash $path) -eq $preserved[$path]) 'Display upgrade changed unrelated user data.'
}
$migratedHash = Hash $graphicsPath
Run-Installer $Kit $SourceMedia $destination 'display-upgrade-repeat' $true
Assert ((Hash $graphicsPath) -eq $migratedHash) 'Repeated display upgrade modified the configuration.'

$unrelated = Join-Path $OutputRoot 'unrelated-destination'
[IO.Directory]::CreateDirectory($unrelated) | Out-Null
[IO.File]::WriteAllText((Join-Path $unrelated 'keep.txt'), 'Unrelated data')
Run-Installer $Kit $SourceMedia $unrelated 'unrelated-destination' $false
Assert (@(Get-ChildItem -LiteralPath $unrelated -File).Count -eq 1) 'Unrelated destination was modified.'
Assert ([IO.File]::ReadAllText((Join-Path $unrelated 'keep.txt')) -eq 'Unrelated data') 'Unrelated file changed.'

$fixture = Join-Path $OutputRoot 'unsupported-media'
$required = @('NFS_WIN.EXE', 'NFSICONN.ICO', 'IFORCE.DLL', 'REDIST\DIRECTX\DPLAY.DLL', 'REDIST\DIRECTX\DPWSOCK.DLL', 'REDIST\DIRECTX\DPSERIAL.DLL', 'DIRECTX3\DIRECTX\DPLAYX.DLL', 'DIRECTX3\DIRECTX\DPWSOCKX.DLL', 'DIRECTX3\DIRECTX\DPMODEMX.DLL')
foreach ($name in $required) {
    $target = Join-Path $fixture $name
    [IO.Directory]::CreateDirectory((Split-Path -Parent $target)) | Out-Null
    [IO.File]::Copy((Join-Path $SourceMedia $name), $target)
}
foreach ($name in @('FRONTEND', 'SIMDATA', 'GAMEDATA')) { [IO.Directory]::CreateDirectory((Join-Path $fixture $name)) | Out-Null }
$wrongExe = [IO.File]::ReadAllBytes((Join-Path $fixture 'NFS_WIN.EXE'))
$wrongExe[100] = $wrongExe[100] -bxor 1
[IO.File]::WriteAllBytes((Join-Path $fixture 'NFS_WIN.EXE'), $wrongExe)
$rejected = Join-Path $OutputRoot 'rejected-media-output'
Run-Installer $Kit $fixture $rejected 'unsupported-media' $false
Assert (-not (Test-Path -LiteralPath $rejected)) 'Unsupported media created a destination.'
[IO.File]::Copy((Join-Path $SourceMedia 'NFS_WIN.EXE'), (Join-Path $fixture 'NFS_WIN.EXE'), $true)
$missingSpeechDestination = Join-Path $OutputRoot 'rejected-missing-speech-output'
Run-Installer $Kit $fixture $missingSpeechDestination 'missing-race-speech' $false
Assert (-not (Test-Path -LiteralPath $missingSpeechDestination)) 'Missing race speech created a destination.'
Assert ([IO.File]::ReadAllText((Join-Path $OutputRoot 'missing-race-speech.log')).Contains('FRONTEND\SPEECH\FINALLAP.EAS')) 'Missing race speech was not diagnosed.'

$damagedKit = Join-Path $OutputRoot 'damaged-kit'
Copy-Item -LiteralPath $Kit -Destination $damagedKit -Recurse
[IO.File]::AppendAllText((Join-Path $damagedKit 'README.txt'), 'Integrity test')
$damagedDestination = Join-Path $OutputRoot 'rejected-kit-output'
Run-Installer $damagedKit $SourceMedia $damagedDestination 'damaged-kit' $false
Assert (-not (Test-Path -LiteralPath $damagedDestination)) 'Damaged kit created a destination.'
Assert ((Hash (Join-Path $SourceMedia 'NFS_WIN.EXE')) -eq $originalHash) 'Original executable changed.'

$result = [ordered]@{
    checked_utc = [DateTime]::UtcNow.ToString('o')
    shell = 'Windows PowerShell 5.1'
    game_launched = $false
    generated_executable_sha256 = $exeHash
    identical_frontend_simdata_files = $assetCount
    identical_root_race_speech_files = $raceSpeech.Count
    reinstall_restores_missing_race_speech = $true
    reinstall_preserves_existing_race_speech = $true
    missing_race_speech_rejected_before_destination_write = $true
    original_iforce_unchanged = $true
    runtime_dlls_match_kit = $true
    valid_relative_path_records = 19
    initial_config_spacing_preserved = $true
    reinstall_preserves_save_and_configs = $true
    legacy_display_keys_added_with_backup = $true
    legacy_border_disabled_upgraded = $true
    legacy_display_upgrade_preserves_other_settings = $true
    display_upgrade_idempotent = $true
    reinstall_refreshes_readonly_managed_components = $true
    unrelated_destination_preserved = $true
    unsupported_media_rejected_before_destination_write = $true
    damaged_kit_rejected_before_destination_write = $true
    original_executable_unchanged = $true
}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputRoot 'installer-validation.json') -Encoding UTF8
$result | ConvertTo-Json
