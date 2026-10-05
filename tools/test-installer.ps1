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
$preserved = @{}
foreach ($path in @($savePath, (Join-Path $destination 'nfs.cfg'), (Join-Path $destination 'ddraw.ini'))) { $preserved[$path] = Hash $path }
foreach ($name in @('IFORCE.DLL', 'NFSICONN.ICO', 'DPLAY.dll', 'ddraw.dll')) {
    $path = Join-Path $destination $name
    [IO.File]::SetAttributes($path, ([IO.File]::GetAttributes($path) -bor [IO.FileAttributes]::ReadOnly))
}
Run-Installer $Kit $SourceMedia $destination 'reinstall' $true
foreach ($path in $preserved.Keys) { Assert ((Hash $path) -eq $preserved[$path]) 'Reinstall changed user data.' }
foreach ($name in @('IFORCE.DLL', 'NFSICONN.ICO', 'DPLAY.dll', 'ddraw.dll')) {
    Assert (([IO.File]::GetAttributes((Join-Path $destination $name)) -band [IO.FileAttributes]::ReadOnly) -eq 0) 'Managed media component remains read-only.'
}

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
    original_iforce_unchanged = $true
    runtime_dlls_match_kit = $true
    valid_relative_path_records = 19
    initial_config_spacing_preserved = $true
    reinstall_preserves_save_and_configs = $true
    reinstall_refreshes_readonly_managed_components = $true
    unrelated_destination_preserved = $true
    unsupported_media_rejected_before_destination_write = $true
    damaged_kit_rejected_before_destination_write = $true
    original_executable_unchanged = $true
}
$result | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $OutputRoot 'installer-validation.json') -Encoding UTF8
$result | ConvertTo-Json
