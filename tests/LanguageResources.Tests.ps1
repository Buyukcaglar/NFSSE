Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot '..\tools\LanguageResources.cs')
function Unhex([string]$Hex) {
    $bytes = New-Object byte[] ($Hex.Length / 2)
    for ($i=0; $i -lt $bytes.Length; $i++) { $bytes[$i]=[Convert]::ToByte($Hex.Substring($i*2,2),16) }
    return ,$bytes
}
function Hash([byte[]]$Bytes) {
    $sha=[Security.Cryptography.SHA256]::Create()
    try { return [BitConverter]::ToString($sha.ComputeHash($Bytes)) }
    finally { $sha.Dispose() }
}
$cases = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'resource-cases.json') -Raw | ConvertFrom-Json
foreach ($case in $cases) {
    $failed = $false; $actual = $null
    try {
        $first=Unhex $case.inputs[0]
        switch ($case.action) {
            'Decode' { $actual=[NfsLanguageResources]::Decode($first) }
            'Encode' { $actual=[NfsLanguageResources]::Encode($first) }
            'Archive' { [NfsLanguageResources+Archive]::new($first) | Out-Null }
            'Graphics' { $actual=[NfsLanguageResources]::Graphics($first,(Unhex $case.inputs[1]),(Unhex $case.inputs[2])) }
            'Hud' { $actual=[NfsLanguageResources]::Hud($first,(Unhex $case.inputs[1])) }
            default { throw 'Unknown fixture action' }
        }
    } catch { $failed=$true }
    if ($failed -ne $case.reject) { throw "Unexpected acceptance/rejection: $($case.action)" }
    if (-not $case.reject -and (Hash $actual) -ne (Hash (Unhex $case.expected))) { throw "Resource output differs from Python reference: $($case.action)" }
}
Write-Output "$($cases.Count) synthetic C# resource cases passed; no game media or UI used."
