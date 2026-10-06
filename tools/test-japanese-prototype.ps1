param(
    [Parameter(Mandatory = $true)][string]$GameRoot,
    [string]$OutputPath
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if (-not $OutputPath) { $OutputPath = Join-Path $PSScriptRoot '..\research\validation\japanese-prototype-validation.json' }
function Assert([bool]$Value, [string]$Message) { if (-not $Value) { throw $Message } }
function Hash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
}
$GameRoot = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $GameRoot).Path).TrimEnd('\')
$manifest = Get-Content -LiteralPath (Join-Path $GameRoot 'japanese-prototype.json') -Raw | ConvertFrom-Json
Assert ($manifest.profile -eq 'japanese-resource-prototype-1' -and $manifest.experimental) 'Use an isolated managed prototype.'
$selector = Join-Path $GameRoot 'Select-Language.ps1'
$table = Join-Path $GameRoot 'GAMEDATA\CONFIG\PATHS.DAT'
$config = Join-Path $GameRoot 'nfs.cfg'
$english = @($manifest.languages | Where-Object name -eq English)[0]
$japanese = @($manifest.languages | Where-Object name -eq Japanese)[0]
$logRoot = Join-Path $PSScriptRoot ('..\build\japanese-tests-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($logRoot) | Out-Null
function Select-Language([string]$Name, [string]$Case, [bool]$ExpectedSuccess = $true) {
    $stdout = Join-Path $logRoot ($Case + '.out.log')
    $stderr = Join-Path $logRoot ($Case + '.err.log')
    $arguments = @('-NoProfile', '-ExecutionPolicy', 'Bypass', '-File', ('"' + $selector + '"'),
                   '-GameRoot', ('"' + $GameRoot + '"'), '-Language', $Name)
    $process = Start-Process -FilePath (Join-Path $env:SystemRoot 'System32\WindowsPowerShell\v1.0\powershell.exe') -ArgumentList $arguments -WindowStyle Hidden -Wait -PassThru `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    Assert (($process.ExitCode -eq 0) -eq $ExpectedSuccess) ("Unexpected result for $Case`: " + [IO.File]::ReadAllText($stderr))
}
function Snapshot {
    $result = @{}
    foreach ($file in Get-ChildItem -LiteralPath $GameRoot -File -Recurse -Force) {
        if ($file.FullName -eq $table -or $file.FullName -eq ($table + '.before-language-selector.bak') -or
            $file.Name -eq '.prototype-language.lock') { continue }
        $relative = $file.FullName.Substring($GameRoot.Length + 1)
        $result[$relative] = Hash $file.FullName
    }
    return $result
}
$save = Join-Path $GameRoot ('GAMEDATA\SAVEGAME\language-test-' + [Guid]::NewGuid().ToString('N') + '.sav')
[IO.File]::WriteAllBytes($save, [byte[]](0, 255, 17, 128, 34, 0, 99))
try {
    $before = Snapshot
    Select-Language English 'english'
    Assert ((Hash $table) -eq $english.sha256) 'English routing failed.'
    Select-Language Japanese 'japanese'
    Assert ((Hash $table) -eq $japanese.sha256) 'Japanese routing failed.'
    $backup = $table + '.before-language-selector.bak'
    Assert ((Hash $backup) -eq $english.sha256) 'First-switch backup differs from original English paths.'
    $backupHash = Hash $backup
    Select-Language Japanese 'idempotent'
    Assert ((Hash $backup) -eq $backupHash -and (Hash $table) -eq $japanese.sha256) 'Repeated selection changed backup or routing.'

    $configBytes = [IO.File]::ReadAllBytes($config)
    try {
        [IO.File]::WriteAllText($config, "NOSOUND LOWVIDEO GERMAN NOREMOTE `r`n", [Text.Encoding]::ASCII)
        $configured = Hash $config
        Select-Language English 'reject-german-branch' $false
        Assert ((Hash $config) -eq $configured -and (Hash $table) -eq $japanese.sha256) 'Rejected configuration was overwritten.'
    } finally { [IO.File]::WriteAllBytes($config, $configBytes) }

    $tableBytes = [IO.File]::ReadAllBytes($table)
    try {
        [byte[]]$custom = $tableBytes.Clone(); $custom[1] = 120
        [IO.File]::WriteAllBytes($table, $custom)
        $customHash = Hash $table
        Select-Language English 'reject-custom-paths' $false
        Assert ((Hash $table) -eq $customHash) 'Custom path bytes were changed.'
    } finally { [IO.File]::WriteAllBytes($table, $tableBytes) }

    $speech = Join-Path $GameRoot 'LANG\JA\SPEECH\NSXGEN16.EAS'
    $speechBytes = [IO.File]::ReadAllBytes($speech)
    try {
        [byte[]]$damaged = $speechBytes.Clone(); $damaged[100] = $damaged[100] -bxor 1
        [IO.File]::WriteAllBytes($speech, $damaged)
        Select-Language Japanese 'reject-damaged-resource' $false
        Assert ((Hash $table) -eq $japanese.sha256) 'Damaged-resource rejection changed the selected table.'
        Select-Language English 'english-recovery-with-damaged-pack'
        Assert ((Hash $table) -eq $english.sha256) 'English recovery failed.'
    } finally { [IO.File]::WriteAllBytes($speech, $speechBytes) }

    $handle = [IO.File]::Open((Join-Path $GameRoot 'NFSSE.exe'), [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
    try {
        Select-Language Japanese 'reject-locked-game' $false
        Assert ((Hash $table) -eq $english.sha256) 'Locked-game rejection changed routing.'
    } finally { $handle.Dispose() }
    Select-Language Japanese 'final-japanese'
    $after = Snapshot
    Assert ($before.Count -eq $after.Count) 'Selection changed the installation file inventory.'
    foreach ($relative in $before.Keys) {
        Assert ($after.ContainsKey($relative) -and $after[$relative] -eq $before[$relative]) "File changed across selection tests: $relative"
    }
    $result = [ordered]@{
        profile = $manifest.profile; checked_utc = [DateTime]::UtcNow.ToString('o'); game_launched = $false;
        japanese_source_files = $manifest.source_input_files; output_resource_files = @($manifest.resource_files).Count;
        unchanged_prototype_files = $before.Count; language_round_trip = $true;
        repeated_selection_idempotent = $true; original_path_backup_exact = $true;
        custom_paths_preserved_and_rejected = $true; german_config_preserved_and_rejected = $true;
        changed_resource_rejected = $true; english_recovery_with_changed_japanese_resource = $true;
        exclusive_game_lock_rejected = $true; save_and_settings_bytes_preserved = $true;
        final_language = 'Japanese'; runtime_files = $manifest.runtime_files;
        resource_edits = $manifest.resource_edits; police_movie_remapping = $manifest.police_movie_remapping;
        runtime_visual_audio_acceptance = 'pending user test'
    }
    $outputFull = [IO.Path]::GetFullPath($OutputPath)
    [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($outputFull)) | Out-Null
    $result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $outputFull -Encoding UTF8
    Write-Host "Japanese prototype static/integration checks passed. $($before.Count) files preserved. No game launched."
} finally {
    if ([IO.File]::Exists($save)) { [IO.File]::Delete($save) }
}
