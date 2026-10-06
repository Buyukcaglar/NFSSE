param(
    [string]$SourceMedia,
    [string]$Destination,
    [switch]$NonInteractive
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-ByteHash([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Get-HexBytes([string]$Hex) {
    if ($Hex.Length % 2) { throw 'Invalid patch recipe hex string.' }
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i = 0; $i -lt $bytes.Length; $i++) { $bytes[$i] = [Convert]::ToByte($Hex.Substring($i * 2, 2), 16) }
    return ,$bytes
}
function Copy-MissingTree([string]$From, [string]$To) {
    [IO.Directory]::CreateDirectory($To) | Out-Null
    foreach ($item in Get-ChildItem -LiteralPath $From -Force) {
        $target = Join-Path $To $item.Name
        if ($item.PSIsContainer) { Copy-MissingTree $item.FullName $target }
        elseif (-not [IO.File]::Exists($target)) {
            [IO.File]::Copy($item.FullName, $target, $false)
            [IO.File]::SetAttributes($target, ([IO.File]::GetAttributes($target) -band (-bnot [IO.FileAttributes]::ReadOnly)))
        }
    }
}
function Copy-ManagedFile([string]$From, [string]$To) {
    if ([IO.File]::Exists($To)) {
        [IO.File]::SetAttributes($To, ([IO.File]::GetAttributes($To) -band (-bnot [IO.FileAttributes]::ReadOnly)))
    }
    [IO.File]::Copy($From, $To, $true)
    [IO.File]::SetAttributes($To, ([IO.File]::GetAttributes($To) -band (-bnot [IO.FileAttributes]::ReadOnly)))
}

try {
    if (-not $SourceMedia) {
        if ($NonInteractive) { throw '-SourceMedia is required in noninteractive mode.' }
        $SourceMedia = (Read-Host 'Folder containing the original NFS_WIN.EXE and FRONTEND/SIMDATA/GAMEDATA').Trim().Trim('"')
    }
    if (-not $Destination) {
        if ($NonInteractive) { throw '-Destination is required in noninteractive mode.' }
        $default = Join-Path ([Environment]::GetFolderPath('MyDocuments')) 'Games\NFSSE'
        $answer = (Read-Host "Destination folder (Enter for $default)").Trim().Trim('"')
        $Destination = if ($answer) { $answer } else { $default }
    }
    $SourceMedia = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $SourceMedia).Path)
    $Destination = [IO.Path]::GetFullPath($Destination)
    if ($SourceMedia.Length -gt [IO.Path]::GetPathRoot($SourceMedia).Length) { $SourceMedia = $SourceMedia.TrimEnd('\') }
    if ($Destination.Length -gt [IO.Path]::GetPathRoot($Destination).Length) { $Destination = $Destination.TrimEnd('\') }
    $sourcePrefix = $SourceMedia.TrimEnd('\') + '\'
    if ($Destination.Equals($SourceMedia, [StringComparison]::OrdinalIgnoreCase) -or
        $Destination.StartsWith($sourcePrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw 'Choose a destination outside the original installation-media folder.'
    }
    $required = @('NFS_WIN.EXE', 'NFSICONN.ICO', 'IFORCE.DLL', 'REDIST\DIRECTX\DPLAY.DLL',
        'REDIST\DIRECTX\DPWSOCK.DLL', 'REDIST\DIRECTX\DPSERIAL.DLL',
        'DIRECTX3\DIRECTX\DPLAYX.DLL', 'DIRECTX3\DIRECTX\DPWSOCKX.DLL', 'DIRECTX3\DIRECTX\DPMODEMX.DLL')
    foreach ($name in $required) {
        if (-not [IO.File]::Exists((Join-Path $SourceMedia $name))) { throw "Missing media file: $name" }
    }
    foreach ($name in @('FRONTEND', 'SIMDATA', 'GAMEDATA')) {
        if (-not [IO.Directory]::Exists((Join-Path $SourceMedia $name))) { throw "Missing media directory: $name" }
    }
    foreach ($name in @('runtime\NFSPortable.dll', 'runtime\ddraw.dll', 'release-manifest.json')) {
        if (-not [IO.File]::Exists((Join-Path $PSScriptRoot $name))) { throw "Missing patch-kit file: $name. Extract the complete release ZIP first." }
    }
    $recipe = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'config\patch-recipe.json') -Raw | ConvertFrom-Json
    $release = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'release-manifest.json') -Raw | ConvertFrom-Json
    foreach ($file in $release.files) {
        $path = Join-Path $PSScriptRoot $file.path
        if (-not [IO.File]::Exists($path) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -ne $file.sha256) {
            throw "Patch-kit integrity check failed: $($file.path). Extract the release again."
        }
    }
    $source = [IO.File]::ReadAllBytes((Join-Path $SourceMedia 'NFS_WIN.EXE'))
    $sourceHash = Get-ByteHash $source
    if ($sourceHash -ne $recipe.source_sha256 -or $source.Length -ne $recipe.source_bytes) {
        throw "Unsupported NFS_WIN.EXE. Expected SHA256 $($recipe.source_sha256); found $sourceHash. Original media was not changed."
    }
    $icon = [IO.File]::ReadAllBytes((Join-Path $SourceMedia 'NFSICONN.ICO'))
    if ((Get-ByteHash $icon) -ne $recipe.icon_sha256) { throw 'The media icon does not match this supported release.' }
    foreach ($name in $recipe.race_speech_files) {
        if ([IO.Path]::GetFileName($name) -ne $name -or [IO.Path]::GetExtension($name) -ne '.EAS') {
            throw 'Invalid race speech filename in patch recipe.'
        }
        $speechSource = Join-Path $SourceMedia "FRONTEND\SPEECH\$name"
        if (-not [IO.File]::Exists($speechSource)) { throw "Missing media file: FRONTEND\SPEECH\$name" }
    }
    if ([IO.Directory]::Exists($Destination) -and @(Get-ChildItem -LiteralPath $Destination -Force).Count -gt 0 -and
        -not [IO.File]::Exists((Join-Path $Destination 'nfsse-installation.json'))) {
        throw 'Destination is not empty and was not created by this installer. Choose a new folder.'
    }
    $exePath = Join-Path $Destination 'NFSSE.exe'
    if ([IO.File]::Exists($exePath)) {
        $existing = Get-ByteHash ([IO.File]::ReadAllBytes($exePath))
        if ($existing -ne $recipe.final_executable_sha256) { throw 'Existing NFSSE.exe has unrecognized changes. Choose a new folder.' }
        $lock = [IO.File]::Open($exePath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $lock.Dispose()
    }
    $patched = New-Object byte[] ($recipe.bootstrap_raw_offset + $recipe.bootstrap_raw_size)
    [Array]::Copy($source, $patched, $source.Length)
    foreach ($write in $recipe.writes) {
        $before = Get-HexBytes $write.before; $after = Get-HexBytes $write.after
        if ($before.Length -ne $after.Length -or $write.offset + $before.Length -gt $source.Length) { throw 'Invalid patch recipe bounds.' }
        for ($i = 0; $i -lt $before.Length; $i++) {
            if ($patched[$write.offset + $i] -ne $before[$i]) { throw "Unexpected bytes for patch: $($write.purpose)" }
        }
        [Array]::Copy($after, 0, $patched, $write.offset, $after.Length)
    }
    $bootstrap = Get-HexBytes $recipe.bootstrap_hex
    [Array]::Copy($bootstrap, 0, $patched, $recipe.bootstrap_raw_offset, $bootstrap.Length)
    if ((Get-ByteHash $patched) -ne $recipe.base_patched_sha256) { throw 'Bootstrap assembly hash check failed.' }
    if (-not ('NfsseIconResources' -as [type])) { Add-Type -Path (Join-Path $PSScriptRoot 'tools\IconResources.cs') }
    $patched = [NfsseIconResources]::Embed($patched, $icon)
    if ((Get-ByteHash $patched) -ne $recipe.final_executable_sha256) { throw 'Final executable/icon hash check failed.' }

    Write-Host 'Source verified. Copying local game assets (about 520 MB)...'
    foreach ($name in @('FRONTEND', 'SIMDATA', 'GAMEDATA')) {
        Copy-MissingTree (Join-Path $SourceMedia $name) (Join-Path $Destination $name)
    }
    # The original installer puts these announcer clips beside the executable.
    # Race speech opens bare filenames; menu narration uses FRONTEND\SPEECH.
    foreach ($name in $recipe.race_speech_files) {
        $speechTarget = Join-Path $Destination $name
        if (-not [IO.File]::Exists($speechTarget)) {
            [IO.File]::Copy((Join-Path $SourceMedia "FRONTEND\SPEECH\$name"), $speechTarget, $false)
            [IO.File]::SetAttributes($speechTarget, ([IO.File]::GetAttributes($speechTarget) -band (-bnot [IO.FileAttributes]::ReadOnly)))
        }
    }
    $copies = @{
        'IFORCE.DLL' = 'IFORCE.DLL'; 'NFSICONN.ICO' = 'NFSICONN.ICO';
        'REDIST\DIRECTX\DPLAY.DLL' = 'DPLAY.dll'; 'REDIST\DIRECTX\DPWSOCK.DLL' = 'DPWSOCK.DLL';
        'REDIST\DIRECTX\DPSERIAL.DLL' = 'DPSERIAL.DLL'; 'DIRECTX3\DIRECTX\DPLAYX.DLL' = 'DPLAYX.DLL';
        'DIRECTX3\DIRECTX\DPWSOCKX.DLL' = 'DPWSOCKX.DLL'; 'DIRECTX3\DIRECTX\DPMODEMX.DLL' = 'DPMODEMX.DLL'
    }
    foreach ($pair in $copies.GetEnumerator()) { Copy-ManagedFile (Join-Path $SourceMedia $pair.Key) (Join-Path $Destination $pair.Value) }
    foreach ($name in @('NFSPortable.dll', 'ddraw.dll')) { Copy-ManagedFile (Join-Path $PSScriptRoot "runtime\$name") (Join-Path $Destination $name) }
    $paths = New-Object byte[] 1520
    foreach ($row in $recipe.paths) {
        if ([IO.Path]::IsPathRooted($row.path) -or $row.path.Contains('..')) { throw 'Invalid resource path.' }
        $bytes = [Text.Encoding]::ASCII.GetBytes($row.path)
        if ($row.index -lt 0 -or $row.index -gt 18 -or $bytes.Length -ge 80) { throw 'Invalid path record.' }
        [Array]::Copy($bytes, 0, $paths, $row.index * 80, $bytes.Length)
        [IO.Directory]::CreateDirectory((Join-Path $Destination $row.path)) | Out-Null
    }
    [IO.File]::WriteAllBytes((Join-Path $Destination 'GAMEDATA\CONFIG\PATHS.DAT'), $paths)
    [IO.File]::WriteAllBytes($exePath, $patched)
    $configPath = Join-Path $Destination 'nfs.cfg'
    if (-not [IO.File]::Exists($configPath)) { [IO.File]::WriteAllText($configPath, "YESSOUND HIGHVIDEO ENGLISH NOREMOTE `r`n", [Text.Encoding]::ASCII) }
    $graphicsPath = Join-Path $Destination 'ddraw.ini'
    if (-not [IO.File]::Exists($graphicsPath)) { [IO.File]::Copy((Join-Path $PSScriptRoot 'config\ddraw.ini'), $graphicsPath, $false) }
    . (Join-Path $PSScriptRoot 'tools\GraphicsConfig.ps1')
    if (Update-NfsseGraphicsConfig $graphicsPath) {
        Write-Host 'Enabled a movable window border and added missing display settings. Original ddraw.ini retained in a backup beside it.'
    }
    [IO.File]::WriteAllText((Join-Path $Destination 'Run-NFS.cmd'), "@echo off`r`n`"%~dp0NFSSE.exe`"`r`n", [Text.Encoding]::ASCII)
    foreach ($name in @('USER_GUIDE.md', 'VALIDATION.md', 'LICENSE')) {
        Copy-ManagedFile (Join-Path $PSScriptRoot $name) (Join-Path $Destination $name)
    }
    Copy-ManagedFile (Join-Path $PSScriptRoot 'licenses\cnc-ddraw-MIT.txt') (Join-Path $Destination 'cnc-ddraw-LICENSE.txt')
    $record = [ordered]@{ version = $release.version; original_sha256 = $sourceHash; patched_sha256 = $recipe.final_executable_sha256;
        media_files_distributed = $false; relative_paths = 19; root_race_speech_files = $recipe.race_speech_files.Count;
        icon_embedded = $true; created_utc = [DateTime]::UtcNow.ToString('o') }
    $record | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $Destination 'nfsse-installation.json') -Encoding UTF8
    Write-Host "Installed: $exePath"
    Write-Host 'Double-click NFSSE.exe to play. Move the complete destination folder to relocate it.'
    Write-Host 'Existing saves and other settings are preserved; window-border compatibility settings are updated with a backup.'
    if (-not $NonInteractive) { Read-Host 'Press Enter to close' | Out-Null }
}
catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
