Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '..\tools\GraphicsConfig.ps1')
$root = Join-Path $PSScriptRoot ('..\build\config-test-' + [Guid]::NewGuid().ToString('N'))
[IO.Directory]::CreateDirectory($root) | Out-Null
function Assert([bool]$Condition, [string]$Message) { if (-not $Condition) { throw $Message } }
$path = Join-Path $root 'ddraw.ini'
$legacy = "; Custom renderer settings`r`n[ddraw]`r`nrenderer=gdi`r`nminfps=5`r`n border = false ; keep this comment`r`n; caf" + [char]233 + "`r`n[OtherGame]`r`ntoggle_borderless=false`r`nborder=false`r`n"
$latin = [Text.Encoding]::GetEncoding(28591)
[IO.File]::WriteAllBytes($path, $latin.GetBytes($legacy))
Assert (Update-NfsseGraphicsConfig $path) 'Legacy configuration was not migrated.'
$text = $latin.GetString([IO.File]::ReadAllBytes($path))
Assert ($text.Contains("toggle_borderless=true`r`nadjmouse=true`r`n[OtherGame]")) 'Settings escaped the global section.'
Assert ($text.Contains("renderer=gdi`r`nminfps=5") -and $text.Contains('; caf' + [char]233)) 'Custom settings or ANSI comments changed.'
Assert ($text.Contains(' border = true ; keep this comment')) 'Movable border was not enabled with its comment preserved.'
Assert ($text.EndsWith("[OtherGame]`r`ntoggle_borderless=false`r`nborder=false`r`n")) 'Another game section changed.'
Assert ($latin.GetString([IO.File]::ReadAllBytes($path + '.before-input-update.bak')) -eq $legacy) 'Original configuration was not backed up exactly.'
$beforeBytes = [Convert]::ToBase64String([IO.File]::ReadAllBytes($path))
Assert (-not (Update-NfsseGraphicsConfig $path)) 'Migration was not idempotent.'
Assert ([Convert]::ToBase64String([IO.File]::ReadAllBytes($path)) -eq $beforeBytes) 'Second migration modified the file.'
[IO.File]::WriteAllText($path, "[DDRAW]`nToggle_Borderless=false`nadjmouse=false`nBorder=true`n")
Assert (-not (Update-NfsseGraphicsConfig $path)) 'Explicit user preferences were overwritten.'
[IO.File]::WriteAllText($path, "[DDRAW]`nToggle_Borderless=false`nadjmouse=false`nBorder=false`nwidth=800`nheight=600`nresizable=true`n")
Assert (Update-NfsseGraphicsConfig $path) 'Existing border=false was not upgraded.'
Assert ([IO.File]::ReadAllText($path) -eq "[DDRAW]`nToggle_Borderless=false`nadjmouse=false`nBorder=true`nwidth=800`nheight=600`nresizable=true`n") 'Border upgrade changed unrelated preferences.'
[IO.File]::WriteAllText($path, '[OtherGame]')
Assert (Update-NfsseGraphicsConfig $path) 'Missing global section was not added.'
Assert ([IO.File]::ReadAllText($path).Contains("[OtherGame]`n[ddraw]`ntoggle_borderless=true`nadjmouse=true`nborder=true`n")) 'New section was appended incorrectly.'
foreach ($encoding in @([Text.Encoding]::UTF8, [Text.Encoding]::Unicode, [Text.Encoding]::BigEndianUnicode)) {
    $original = '[ddraw]' + "`r`n; Unicode " + [char]305 + "`r`n"
    [IO.File]::WriteAllText($path, $original, $encoding)
    $before = [IO.File]::ReadAllBytes($path)
    Assert (Update-NfsseGraphicsConfig $path) 'Unicode configuration migration failed.'
    $after = [IO.File]::ReadAllBytes($path)
    $preamble = $encoding.GetPreamble()
    for ($i = 0; $i -lt $preamble.Length; $i++) { Assert ($before[$i] -eq $after[$i]) 'Encoding marker changed.' }
    Assert ([IO.File]::ReadAllText($path).StartsWith($original)) 'Unicode configuration contents changed.'
}
Write-Output 'Graphics configuration migration checks passed.'
