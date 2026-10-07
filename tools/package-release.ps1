param(
    [string]$Version = '0.2.2',
    [string]$RuntimeDll,
    [string]$LanguageLauncher,
    [string]$CncArchive,
    [string]$OutputRoot
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
if (-not $RuntimeDll) { $RuntimeDll = Join-Path $repo 'build\NFSPortable.dll' }
if (-not $LanguageLauncher) { $LanguageLauncher = Join-Path $repo 'build\NFSSE-Language.exe' }
if (-not $OutputRoot) { $OutputRoot = Join-Path $repo 'build\releases' }
$OutputRoot = [IO.Path]::GetFullPath($OutputRoot)
[IO.Directory]::CreateDirectory($OutputRoot) | Out-Null
if (-not $CncArchive) {
    $CncArchive = Join-Path $OutputRoot 'cnc-ddraw-v7.1.0.0.zip'
    if (-not [IO.File]::Exists($CncArchive)) {
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/v7.1.0.0/cnc-ddraw.zip' -OutFile $CncArchive
    }
}
$expectedArchive = '0b13ab89a64c9918189b1dadd449ef6ed3cb3b7b19cabd96d8adbd95505bb908'
if ((Get-FileHash -LiteralPath $CncArchive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $expectedArchive) { throw 'Unexpected cnc-ddraw archive hash.' }
if (-not [IO.File]::Exists($RuntimeDll)) { throw 'Build NFSPortable.dll first with tools\build-runtime.cmd.' }
if (-not [IO.File]::Exists($LanguageLauncher)) { throw 'Build the optional selector first with tools\build-language-launcher.cmd.' }
if ((Get-FileHash -LiteralPath $RuntimeDll -Algorithm SHA256).Hash.ToLowerInvariant() -ne '4e970616fb5100f03c7bb2543dec6a0a28bcd1ad8227a455f7e840bc1b6662e4') { throw 'Package the verified player-persistence helper; use -RuntimeDll to select it.' }
$kit = Join-Path $OutputRoot "NFSSE-v$Version-patch-kit"
if ([IO.Directory]::Exists($kit)) { throw "Release staging folder already exists: $kit. Use a fresh OutputRoot." }
foreach ($name in @('', 'runtime', 'tools', 'config', 'licenses')) { [IO.Directory]::CreateDirectory((Join-Path $kit $name)) | Out-Null }
$wrapper = Join-Path $OutputRoot ('cnc-ddraw-extracted-' + [Guid]::NewGuid().ToString('N'))
Expand-Archive -LiteralPath $CncArchive -DestinationPath $wrapper
$ddraw = Join-Path $wrapper 'ddraw.dll'
if ((Get-FileHash -LiteralPath $ddraw -Algorithm SHA256).Hash.ToLowerInvariant() -ne '85e0f7d530dfda134793a57cb3e76b0287dcc96892ee57162dd68f47283b03a9') { throw 'Unexpected cnc-ddraw DLL hash.' }
[IO.File]::Copy($ddraw, (Join-Path $kit 'runtime\ddraw.dll'), $false)
[IO.File]::Copy($RuntimeDll, (Join-Path $kit 'runtime\NFSPortable.dll'), $false)
[IO.File]::Copy($LanguageLauncher, (Join-Path $kit 'runtime\NFSSE-Language.exe'), $false)
foreach ($name in @('Install-NFSSE.cmd', 'Install-NFSSE.ps1', 'LICENSE')) { [IO.File]::Copy((Join-Path $repo $name), (Join-Path $kit $name), $false) }
foreach ($name in @('patch-recipe.json', 'ddraw.ini', 'japanese-resource-profile.json', 'language-media-profile.json')) { [IO.File]::Copy((Join-Path $repo "config\$name"), (Join-Path $kit "config\$name"), $false) }
[IO.File]::Copy((Join-Path $repo 'tools\IconResources.cs'), (Join-Path $kit 'tools\IconResources.cs'), $false)
[IO.File]::Copy((Join-Path $repo 'tools\GraphicsConfig.ps1'), (Join-Path $kit 'tools\GraphicsConfig.ps1'), $false)
foreach ($name in @('LanguageEdition.ps1', 'LanguageResources.cs')) { [IO.File]::Copy((Join-Path $repo "tools\$name"), (Join-Path $kit "tools\$name"), $false) }
[IO.File]::Copy((Join-Path $repo 'licenses\cnc-ddraw-MIT.txt'), (Join-Path $kit 'licenses\cnc-ddraw-MIT.txt'), $false)
foreach ($name in @('USER_GUIDE.md', 'VALIDATION.md', 'LANGUAGE_EDITION.md', 'PLAYER_PERSISTENCE.md', "RELEASE_NOTES_v$Version.md")) { [IO.File]::Copy((Join-Path $repo "docs\$name"), (Join-Path $kit $name), $false) }
[IO.File]::WriteAllText((Join-Path $kit 'README.txt'), "NFSSE v$Version compatibility patch kit`r`n`r`nExtract this complete ZIP, then double-click Install-NFSSE.cmd.`r`nSupply your own supported original English media and choose a new, empty destination folder.`r`nTo update an existing v0.2.1 kit installation, close the game, back up GAMEDATA and select the same destination.`r`nThe installer preserves saves, settings and language selection; managed updates are backed up inside the game folder.`r`nThe language-selector window is optional. Supply Japanese media to add Japanese.`r`nNormal play and installation need no Python, Visual Studio or administrator rights.`r`nAfter installation, double-click NFSSE.exe in the destination folder.`r`nRead USER_GUIDE.md, PLAYER_PERSISTENCE.md, LANGUAGE_EDITION.md, VALIDATION.md and RELEASE_NOTES_v$Version.md for details.`r`nGame media, the game engine and its original icon are not included in this ZIP.`r`nhttps://github.com/Buyukcaglar/NFSSE`r`n", [Text.Encoding]::ASCII)
# Keep extracted upstream files outside the distributable kit.
$files = @(Get-ChildItem -LiteralPath $kit -Recurse -File | Sort-Object FullName | ForEach-Object {
    [ordered]@{ path = $_.FullName.Substring($kit.Length + 1).Replace('\', '/'); sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant() }
})
$record = [ordered]@{ version = $Version; source_repository = 'https://github.com/Buyukcaglar/NFSSE';
    game_media_included = $false; cnc_ddraw_version = '7.1.0.0'; files = $files }
$record | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $kit 'release-manifest.json') -Encoding UTF8
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = Join-Path $OutputRoot "NFSSE-v$Version-patch-kit.zip"
[IO.Compression.ZipFile]::CreateFromDirectory($kit, $zip, [IO.Compression.CompressionLevel]::Optimal, $false)
$sum = (Get-FileHash -LiteralPath $zip -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText((Join-Path $OutputRoot 'SHA256SUMS.txt'), "$sum  $([IO.Path]::GetFileName($zip))`n", [Text.Encoding]::ASCII)
Write-Output $zip
Write-Output "SHA256 $sum"
