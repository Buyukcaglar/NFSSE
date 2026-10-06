param([string]$CncArchive)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$repo = Split-Path -Parent $PSScriptRoot
$root = Join-Path $repo 'build\window-test-renderer'
[IO.Directory]::CreateDirectory($root) | Out-Null
if (-not $CncArchive) {
    $CncArchive = Join-Path $root 'cnc-ddraw-v7.1.0.0.zip'
    if (-not [IO.File]::Exists($CncArchive)) {
        Invoke-WebRequest -UseBasicParsing -Uri 'https://github.com/FunkyFr3sh/cnc-ddraw/releases/download/v7.1.0.0/cnc-ddraw.zip' -OutFile $CncArchive
    }
}
function Hash([string]$Path) {
    $sha = [Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes($Path))).Replace('-', '').ToLowerInvariant() }
    finally { $sha.Dispose() }
}
if ((Hash $CncArchive) -ne '0b13ab89a64c9918189b1dadd449ef6ed3cb3b7b19cabd96d8adbd95505bb908') { throw 'Unexpected cnc-ddraw archive hash.' }
# Extract just the renderer; no executable or original game media is needed.
Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [IO.Compression.ZipFile]::OpenRead($CncArchive)
$renderer = Join-Path $root 'ddraw.dll'
try {
    $entry = $archive.GetEntry('ddraw.dll')
    if (-not $entry) { throw 'Renderer missing from the pinned archive.' }
    [IO.Compression.ZipFileExtensions]::ExtractToFile($entry, $renderer, $true)
}
finally { $archive.Dispose() }
if ((Hash $renderer) -ne '85e0f7d530dfda134793a57cb3e76b0287dcc96892ee57162dd68f47283b03a9') { throw 'Unexpected renderer DLL hash.' }
& (Join-Path $repo 'build\WindowPresentationTests.exe') $renderer
if ($LASTEXITCODE -ne 0) { throw 'Window presentation regression failed.' }
