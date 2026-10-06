param([Parameter(Mandatory=$true)][string]$InputExecutable,
    [Parameter(Mandatory=$true)][string]$OutputExecutable,
    [Parameter(Mandatory=$true)][string]$SourceIcon)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -Path (Join-Path $PSScriptRoot 'IconResources.cs')
$bytes = [NfsseIconResources]::Embed([IO.File]::ReadAllBytes($InputExecutable), [IO.File]::ReadAllBytes($SourceIcon))
[IO.File]::WriteAllBytes($OutputExecutable, $bytes)
