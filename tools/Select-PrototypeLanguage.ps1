param(
    [ValidateSet('English', 'Japanese')][string]$Language,
    [string]$GameRoot = $PSScriptRoot,
    [switch]$Launch
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Get-PrototypeFile([string]$Root, [string]$Relative) {
    if (-not $Relative -or [IO.Path]::IsPathRooted($Relative) -or
        $Relative.Contains(':') -or $Relative -match '(^|[\\/])\.\.?([\\/]|$)') {
        throw "Invalid prototype path: $Relative"
    }
    $path = [IO.Path]::GetFullPath((Join-Path $Root $Relative))
    if (-not $path.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or
        -not [IO.File]::Exists($path)) { throw "Missing prototype file: $Relative" }
    $item = $path
    while ($item.Length -gt $Root.Length) {
        if (([IO.File]::GetAttributes($item) -band [IO.FileAttributes]::ReparsePoint) -ne 0) {
            throw "Linked prototype path is not supported: $Relative"
        }
        $item = [IO.Path]::GetDirectoryName($item)
    }
    return $path
}
function Get-PrototypeByteHash([byte[]]$Bytes) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($Bytes))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
function Assert-PrototypeFileHash([string]$Root, $Record) {
    $path = Get-PrototypeFile $Root $Record.path
    $stream = [IO.File]::OpenRead($path)
    $sha = [Security.Cryptography.SHA256]::Create()
    try { $found = ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
    if ($found -ne $Record.sha256) {
        throw "Prototype integrity check failed: $($Record.path)"
    }
}
function Read-PrototypePaths([string]$Root, $Record) {
    $data = [IO.File]::ReadAllBytes((Get-PrototypeFile $Root $Record.path_table))
    if ($data.Length -ne 1520 -or (Get-PrototypeByteHash $data) -ne $Record.sha256) {
        throw "Invalid language path table: $($Record.name)"
    }
    $values = @()
    for ($index = 0; $index -lt 19; $index++) {
        $start = $index * 80
        $end = $start
        while ($end -lt $start + 80 -and $data[$end] -ne 0) {
            if ($data[$end] -gt 127) { throw 'Language paths must be ASCII.' }
            $end++
        }
        if ($end -eq $start -or $end -eq $start + 80) { throw 'Invalid legacy path record.' }
        for ($pad = $end; $pad -lt $start + 80; $pad++) {
            if ($data[$pad] -ne 0) { throw 'Legacy path record has nonzero padding.' }
        }
        $value = [Text.Encoding]::ASCII.GetString($data, $start, $end - $start)
        if ([IO.Path]::IsPathRooted($value) -or $value.Contains(':') -or
            $value -match '(^|[\\/])\.\.?([\\/]|$)' -or -not $value.EndsWith('/')) {
            throw 'Language table has an unsafe resource directory.'
        }
        $directory = [IO.Path]::GetFullPath((Join-Path $Root $value))
        if (-not $directory.StartsWith($Root.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or
            -not [IO.Directory]::Exists($directory)) { throw "Missing resource directory: $value" }
        $values += $value
    }
    return @{ bytes = $data; values = $values }
}

try {
    $GameRoot = [IO.Path]::GetFullPath((Resolve-Path -LiteralPath $GameRoot).Path).TrimEnd('\')
    $manifest = Get-Content -LiteralPath (Get-PrototypeFile $GameRoot 'japanese-prototype.json') -Raw | ConvertFrom-Json
    if ($manifest.schema -ne 1 -or $manifest.profile -ne 'japanese-resource-prototype-1' -or
        -not $manifest.experimental -or @($manifest.languages).Count -ne 2 -or
        @($manifest.runtime_files).Count -ne 3) { throw 'Unsupported prototype manifest.' }
    $english = @($manifest.languages | Where-Object name -eq 'English')
    $japanese = @($manifest.languages | Where-Object name -eq 'Japanese')
    if ($english.Count -ne 1 -or $japanese.Count -ne 1) { throw 'Prototype language records are incomplete.' }
    $en = Read-PrototypePaths $GameRoot $english[0]
    $ja = Read-PrototypePaths $GameRoot $japanese[0]
    $overrides = @{ 2 = 'lang/ja/speech/'; 5 = 'lang/ja/art/';
                    9 = 'lang/ja/misc/'; 17 = 'lang/ja/misc/'; 18 = 'lang/ja/show/' }
    $englishOverrides = @{ 2 = 'frontend/speech/'; 5 = 'frontend/art/';
                           9 = 'simdata/misc/'; 17 = 'simdata/misc/'; 18 = 'frontend/show/' }
    for ($index = 0; $index -lt 19; $index++) {
        if ($overrides.ContainsKey($index)) {
            if ($ja.values[$index] -ne $overrides[$index] -or $en.values[$index] -ne $englishOverrides[$index]) {
                throw 'Unexpected language resource routing.'
            }
        } elseif ($ja.values[$index] -ne $en.values[$index]) {
            throw 'Language tables must share gameplay, music and writable data paths.'
        }
    }
    if (-not $Language) {
        Write-Host 'Japanese resource prototype'
        Write-Host '1. Japanese'
        Write-Host '2. English'
        $answer = Read-Host 'Select 1 or 2'
        if ($answer -eq '1') { $Language = 'Japanese' }
        elseif ($answer -eq '2') { $Language = 'English' }
        else { throw 'Choose 1 or 2. No language was changed.' }
    }
    $selectorLock = $null
    $exeLock = $null
    $temporary = $null
    try {
        $selectorLock = [IO.File]::Open((Join-Path $GameRoot '.prototype-language.lock'),
            [IO.FileMode]::OpenOrCreate, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        $exePath = Get-PrototypeFile $GameRoot 'NFSSE.exe'
        try {
            $exeLock = [IO.File]::Open($exePath, [IO.FileMode]::Open, [IO.FileAccess]::ReadWrite, [IO.FileShare]::None)
        } catch { throw 'Close this prototype game before selecting a language.' }
        $runtimeNames = @($manifest.runtime_files | ForEach-Object { $_.path } | Sort-Object)
        if (($runtimeNames -join ',') -ne 'ddraw.dll,NFSPortable.dll,NFSSE.exe') { throw 'Unexpected runtime files.' }
        foreach ($record in $manifest.runtime_files) {
            if ($record.path -eq 'NFSSE.exe') {
                $sha = [Security.Cryptography.SHA256]::Create()
                try { $found = ([BitConverter]::ToString($sha.ComputeHash($exeLock))).Replace('-', '').ToLowerInvariant() }
                finally { $sha.Dispose() }
                if ($found -ne $record.sha256) { throw 'Prototype executable has changed.' }
            } else { Assert-PrototypeFileHash $GameRoot $record }
        }
        if ($Language -eq 'Japanese') {
            if (@($manifest.resource_files).Count -lt 1) { throw 'Prototype resource inventory is missing.' }
            foreach ($record in $manifest.resource_files) {
                if (-not $record.path.StartsWith('LANG/JA/', [StringComparison]::OrdinalIgnoreCase)) {
                    throw 'Unexpected Japanese resource path.'
                }
                Assert-PrototypeFileHash $GameRoot $record
            }
        }
        $configPath = Get-PrototypeFile $GameRoot 'nfs.cfg'
        $tokens = ([Text.Encoding]::ASCII.GetString([IO.File]::ReadAllBytes($configPath))).Trim() -split '\s+'
        if ($tokens.Count -ne 4 -or $tokens[2] -cne 'ENGLISH') {
            throw 'Keep nfs.cfg on the ENGLISH engine branch; use this selector for Japanese resources.'
        }
        $pathTable = Get-PrototypeFile $GameRoot 'GAMEDATA/CONFIG/PATHS.DAT'
        $current = [IO.File]::ReadAllBytes($pathTable)
        $hash = Get-PrototypeByteHash $current
        if ($hash -ne $english[0].sha256 -and $hash -ne $japanese[0].sha256) {
            throw 'PATHS.DAT has custom changes. They were preserved; language selection was refused.'
        }
        $selected = if ($Language -eq 'Japanese') { $ja.bytes } else { $en.bytes }
        if ($hash -ne (Get-PrototypeByteHash $selected)) {
            $backup = $pathTable + '.before-language-selector.bak'
            if (-not [IO.File]::Exists($backup)) { [IO.File]::Copy($pathTable, $backup, $false) }
            $temporary = $pathTable + '.language-' + [Guid]::NewGuid().ToString('N') + '.tmp'
            [IO.File]::WriteAllBytes($temporary, $selected)
            [IO.File]::Replace($temporary, $pathTable, [NullString]::Value)
            $temporary = $null
        }
        Write-Host "$Language selected. Saves and settings are shared between languages."
        if ($Launch) {
            $exeLock.Dispose(); $exeLock = $null
            Start-Process -FilePath $exePath -WorkingDirectory $GameRoot | Out-Null
        }
    } finally {
        if ($exeLock) { $exeLock.Dispose() }
        if ($selectorLock) { $selectorLock.Dispose() }
        if ($temporary -and [IO.File]::Exists($temporary)) { [IO.File]::Delete($temporary) }
    }
} catch {
    Write-Error $_ -ErrorAction Continue
    exit 1
}
