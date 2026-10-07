# Optional language edition installation using only Windows PowerShell/.NET.
function Get-NfsFileHash([string]$Path) {
    $stream = [IO.File]::OpenRead($Path); $sha = [Security.Cryptography.SHA256]::Create()
    try { return ([BitConverter]::ToString($sha.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
    finally { $stream.Dispose(); $sha.Dispose() }
}
function Assert-NfsSafeTree([string]$Path) {
    if (([IO.File]::GetAttributes($Path) -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Linked folder is unsupported: $Path" }
    foreach ($item in Get-ChildItem -LiteralPath $Path -Recurse -Force) {
        if (($item.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw "Linked game/media file is unsupported: $($item.FullName)" }
    }
}
function Get-NfsJapanesePack([string]$Media, [string]$English, [string]$Kit) {
    Assert-NfsSafeTree $Media
    $profile = Get-Content -LiteralPath (Join-Path $Kit 'config\japanese-resource-profile.json') -Raw | ConvertFrom-Json
    if ((Get-NfsFileHash (Join-Path $Media 'NFS.EXE')) -ne $profile.japanese_executable_sha256) { throw 'Unsupported Japanese installation media.' }
    if (-not ('NfsLanguageResources' -as [type])) { Add-Type -Path (Join-Path $Kit 'tools\LanguageResources.cs') }
    $pack = @{}
    foreach ($file in $profile.files) {
        $path = Join-Path $Media $file.path
        if (-not [IO.File]::Exists($path) -or (Get-NfsFileHash $path) -ne $file.sha256) { throw "Japanese media integrity check failed: $($file.path)" }
        $pack[$file.target] = [IO.File]::ReadAllBytes($path)
    }
    $jp = [IO.File]::ReadAllBytes((Join-Path $Media 'FRONTEND\ART\OPTION\GRAPHICS.QFS'))
    $en = [IO.File]::ReadAllBytes((Join-Path $English 'FRONTEND\ART\OPTION\GRAPHICS.QFS'))
    foreach ($context in @('OPTION', 'CHECK')) {
        $target = [IO.File]::ReadAllBytes((Join-Path $English "FRONTEND\ART\$context\GRAPHICS.QFS"))
        $raw = [NfsLanguageResources]::Graphics($jp, $en, $target)
        $pack["LANG/JA/ART/$context/GRAPHICS.FSH"] = $raw
        $pack["LANG/JA/ART/$context/GRAPHICS.QFS"] = [NfsLanguageResources]::Encode($raw)
    }
    foreach ($name in @('MASKHI.FSH', 'MASKLO.FSH')) {
        $pack["LANG/JA/MISC/$name"] = [NfsLanguageResources]::Hud(
            [IO.File]::ReadAllBytes((Join-Path $Media "SIMDATA\MISC\$name")),
            [IO.File]::ReadAllBytes((Join-Path $English "SIMDATA\MISC\$name")))
    }
    return ,$pack
}
function Get-NfsLanguagePaths($Recipe, [string]$Language) {
    $overrides = @{}
    if ($Language -eq 'German') { $overrides = @{2='frontend/gspeech/';5='frontend/gart/';10='simdata/gtrackfm/';12='simdata/gslides/';16='simdata/gdash/';18='frontend/gshow/'} }
    if ($Language -eq 'Japanese') { $overrides = @{2='lang/ja/speech/';5='lang/ja/art/';9='lang/ja/misc/';17='lang/ja/misc/';18='lang/ja/show/'} }
    $bytes = New-Object byte[] 1520
    foreach ($row in $Recipe.paths) {
        $value = if ($overrides.ContainsKey([int]$row.index)) { $overrides[[int]$row.index] } else { $row.path.ToLowerInvariant() }
        $data = [Text.Encoding]::ASCII.GetBytes($value)
        [Array]::Copy($data, 0, $bytes, $row.index * 80, $data.Length)
    }
    return ,$bytes
}
function Get-NfsEnglishConfig([byte[]]$Bytes) {
    $text = [Text.Encoding]::ASCII.GetString($Bytes)
    $tokens = [regex]::Matches($text, '\S+')
    if ($Bytes.Length -gt 80 -or $tokens.Count -ne 4 -or $tokens[2].Value -notin @('ENGLISH','GERMAN')) { throw 'Custom nfs.cfg language configuration was preserved.' }
    foreach ($token in $tokens) {
        if ($token.Index + $token.Length -ge $text.Length -or $text[$token.Index + $token.Length] -ne ' ') { throw 'nfs.cfg options must each end in a space.' }
    }
    $text = $text.Remove($tokens[2].Index, $tokens[2].Length).Insert($tokens[2].Index, 'ENGLISH')
    return ,[Text.Encoding]::ASCII.GetBytes($text)
}
function Read-NfsExistingPack([string]$Root) {
    $manifest = Get-Content -LiteralPath (Join-Path $Root 'language-edition.json') -Raw | ConvertFrom-Json
    $index = Join-Path $Root 'LANG\language-edition.index'
    if ($manifest.edition -ne 'three-language-1' -or (Get-NfsFileHash $index) -ne $manifest.index_sha256) { throw 'Existing language inventory has custom changes; they were preserved.' }
    $pack = @{}
    foreach ($line in [IO.File]::ReadAllLines($index)) {
        $columns = $line -split "`t"
        if ($columns.Count -ne 3 -or $columns[0] -ne 'J' -or -not $columns[2].StartsWith('LANG/JA/')) { continue }
        $relative = $columns[2]
        if ($relative -match '(^|/)\.\.?(/|$)' -or $relative.Contains(':') -or $relative.Contains('\')) { throw 'Invalid installed Japanese path.' }
        $path = Join-Path $Root $relative
        if ((Get-NfsFileHash $path) -ne $columns[1]) { throw "Installed Japanese resource has custom changes: $relative" }
        $pack[$relative] = [IO.File]::ReadAllBytes($path)
    }
    return ,$pack
}
function Assert-NfsLanguageInputs([string]$Media, [string]$Destination, [string]$Kit, $Recipe, [bool]$ExistingEdition) {
    Assert-NfsSafeTree $Media
    $profile = Get-Content -LiteralPath (Join-Path $Kit 'config\language-media-profile.json') -Raw | ConvertFrom-Json
    foreach ($file in $profile.files) {
        if ((Get-NfsFileHash (Join-Path $Media $file.path)) -ne $file.sha256) { throw "English/German media integrity check failed: $($file.path)" }
        $installed = Join-Path $Destination $file.path
        if ([IO.File]::Exists($installed) -and (Get-NfsFileHash $installed) -ne $file.sha256) { throw "Existing game resource has custom changes: $($file.path). It was preserved." }
    }
    foreach ($name in $Recipe.race_speech_files) {
        $installed = Join-Path $Destination $name
        if ([IO.File]::Exists($installed)) {
            $hash = Get-NfsFileHash $installed
            if ($hash -notin @((Get-NfsFileHash (Join-Path $Media "FRONTEND\SPEECH\$name")),(Get-NfsFileHash (Join-Path $Media "FRONTEND\GSPEECH\$name")))) { throw "Custom race announcer was preserved: $name" }
        }
    }
    $paths = Join-Path $Destination 'GAMEDATA\CONFIG\PATHS.DAT'
    if ([IO.File]::Exists($paths)) {
        $found = [IO.File]::ReadAllBytes($paths)
        $normalized = [Text.Encoding]::ASCII.GetBytes([Text.Encoding]::ASCII.GetString($found).ToLowerInvariant())
        $hash = Get-ByteHash $normalized
        $known = @('English','German','Japanese') | ForEach-Object { Get-ByteHash (Get-NfsLanguagePaths $Recipe $_) }
        if ($hash -notin $known) { throw 'Custom PATHS.DAT was preserved; optional language installation was refused.' }
    }
    $config = Join-Path $Destination 'nfs.cfg'
    if ([IO.File]::Exists($config)) { Get-NfsEnglishConfig ([IO.File]::ReadAllBytes($config)) | Out-Null }
    if ($ExistingEdition -and (Get-NfsFileHash (Join-Path $Destination 'NFSSE-Game.exe')) -ne $Recipe.final_executable_sha256) { throw 'Existing language game engine has changed.' }
}
function Save-NfsLanguageBackup([string]$Root, [string]$Version, $Recipe) {
    $folder = Join-Path $Root ('.patch-backups\' + $Version + '-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss') + '-' + [Guid]::NewGuid().ToString('N').Substring(0,8))
    foreach ($relative in (@('NFSSE.exe','NFSSE-Game.exe','NFSPortable.dll','nfs.cfg','GAMEDATA/CONFIG/CONFIG.DAT','GAMEDATA/CONFIG/PATHS.DAT','language-edition.json','LANG/language-edition.index','LANG/English.paths','LANG/German.paths','LANG/Japanese.paths') + @($Recipe.race_speech_files))) {
        $source = Join-Path $Root $relative
        if ([IO.File]::Exists($source)) {
            $target = Join-Path $folder $relative
            [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
            [IO.File]::Copy($source, $target, $false)
        }
    }
    return $folder
}
function Write-NfsLanguageEdition([string]$Root, [string]$Media, [string]$Kit, $Recipe, $Release, [byte[]]$Engine, [hashtable]$Pack) {
    [IO.Directory]::CreateDirectory((Join-Path $Root 'LANG')) | Out-Null
    [IO.File]::WriteAllBytes((Join-Path $Root 'NFSSE-Game.exe'), $Engine)
    foreach ($relative in $Pack.Keys) {
        $target = Join-Path $Root $relative
        [IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target)) | Out-Null
        if (-not [IO.File]::Exists($target) -or (Get-NfsFileHash $target) -ne (Get-ByteHash $Pack[$relative])) {
            [IO.File]::WriteAllBytes($target, $Pack[$relative])
        }
    }
    $languages = @(); $index = New-Object 'Collections.Generic.List[string]'
    $index.Add('NFSSE-LANGUAGES-1')
    $profile = Get-Content -LiteralPath (Join-Path $Kit 'config\language-media-profile.json') -Raw | ConvertFrom-Json
    foreach ($file in $profile.files) { $index.Add($file.group + "`t" + $file.sha256 + "`t" + $file.path) }
    $runtime = @('NFSSE-Game.exe','NFSPortable.dll','ddraw.dll','IFORCE.DLL','DPLAY.dll','DPSERIAL.DLL','DPWSOCK.DLL','DPLAYX.DLL','DPWSOCKX.DLL','DPMODEMX.DLL')
    foreach ($name in $runtime) {
        if (@($profile.files | Where-Object path -eq $name).Count -eq 0) { $index.Add('C' + "`t" + (Get-NfsFileHash (Join-Path $Root $name)) + "`t" + $name) }
    }
    $names = @('English','German'); if ($Pack.Count -gt 0) { $names += 'Japanese' }
    foreach ($language in $names) {
        $relative = "LANG/$language.paths"; $bytes = Get-NfsLanguagePaths $Recipe $language
        [IO.File]::WriteAllBytes((Join-Path $Root $relative), $bytes)
        $hash = Get-ByteHash $bytes; $group = @{English='E';German='D';Japanese='J'}[$language]
        $index.Add($group + "`t" + $hash + "`t" + $relative)
        $languages += [ordered]@{language=$language;path=$relative;sha256=$hash}
    }
    if ($Pack.Count -gt 0) {
        foreach ($relative in ($Pack.Keys | Sort-Object)) { $index.Add('J' + "`t" + (Get-ByteHash $Pack[$relative]) + "`t" + $relative) }
        foreach ($name in $Recipe.race_speech_files) { $index.Add('J' + "`t" + (Get-NfsFileHash (Join-Path $Media "FRONTEND\SPEECH\$name")) + "`t" + "FRONTEND/SPEECH/$name") }
    }
    $indexPath = Join-Path $Root 'LANG\language-edition.index'
    [IO.File]::WriteAllText($indexPath, (($index -join "`n") + "`n"), [Text.Encoding]::ASCII)
    $launcher = [NfsseIconResources]::Embed([IO.File]::ReadAllBytes((Join-Path $Kit 'runtime\NFSSE-Language.exe')), [IO.File]::ReadAllBytes((Join-Path $Media 'NFSICONN.ICO')))
    $record = [ordered]@{schema=1;edition='three-language-1';version=$Release.version;languages=$languages;
        launcher_sha256=(Get-ByteHash $launcher);engine_sha256=(Get-ByteHash $Engine);index_sha256=(Get-NfsFileHash $indexPath);
        japanese_resource_count=$Pack.Count;game_media_distributed=$false;created_utc=[DateTime]::UtcNow.ToString('o')}
    $record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $Root 'language-edition.json') -Encoding UTF8
    Copy-ManagedFile (Join-Path $Kit 'LANGUAGE_EDITION.md') (Join-Path $Root 'LANGUAGE_EDITION.md')
    # Public entry point is installed last, after all language resources/metadata.
    $target = Join-Path $Root 'NFSSE.exe'
    if ([IO.File]::Exists($target)) { [IO.File]::SetAttributes($target, ([IO.File]::GetAttributes($target) -band (-bnot [IO.FileAttributes]::ReadOnly))) }
    [IO.File]::WriteAllBytes($target, $launcher)
}
