# Add missing compatibility settings and enable the requested movable border.
function Update-NfsseGraphicsConfig([string]$Path) {
    $bytes = [IO.File]::ReadAllBytes($Path)
    $offset = 0
    $encoding = [Text.Encoding]::GetEncoding(28591) # Round-trip existing ANSI bytes.
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191) {
        $offset = 3
        $encoding = New-Object Text.UTF8Encoding($false, $true)
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 255 -and $bytes[1] -eq 254) {
        $offset = 2; $encoding = [Text.Encoding]::Unicode
    }
    elseif ($bytes.Length -ge 2 -and $bytes[0] -eq 254 -and $bytes[1] -eq 255) {
        $offset = 2; $encoding = [Text.Encoding]::BigEndianUnicode
    }
    $text = $encoding.GetString($bytes, $offset, $bytes.Length - $offset)
    $newline = if ($text.Contains("`r`n")) { "`r`n" } else { "`n" }
    $section = [regex]::Match($text, '(?im)^[ \t]*\[ddraw\][ \t]*(?:[;#][^\r\n]*)?\r?$')
    if ($section.Success) {
        $start = $section.Index + $section.Length
        $next = [regex]::Match($text.Substring($start), '(?m)^[ \t]*\[[^\]\r\n]+\]')
        $end = if ($next.Success) { $start + $next.Index } else { $text.Length }
        $settings = $text.Substring($start, $end - $start)
    }
    else { $start = $end = $text.Length; $settings = '' }
    $updatedSettings = [regex]::Replace($settings,
        '(?im)^([ \t]*border[ \t]*=[ \t]*)[^\s;#\r\n]*', '${1}true')
    $missing = @()
    foreach ($name in @('toggle_borderless', 'adjmouse', 'border')) {
        if (-not [regex]::IsMatch($settings, ('(?im)^[ \t]*' + $name + '[ \t]*='))) {
            $missing += "$name=true"
        }
    }
    if (-not $missing.Count -and $updatedSettings -ceq $settings) { return $false }
    $updated = $text.Substring(0, $start) + $updatedSettings + $text.Substring($end)
    $end += $updatedSettings.Length - $settings.Length
    if ($missing.Count) {
        $insert = if ($end -gt 0 -and $updated[$end - 1] -ne "`n") { $newline } else { '' }
        if (-not $section.Success) { $insert += '[ddraw]' + $newline }
        $insert += ($missing -join $newline) + $newline
        $updated = $updated.Insert($end, $insert)
    }
    $backup = $Path + '.before-input-update.bak'
    $suffix = 0
    while ([IO.File]::Exists($backup)) { $suffix++; $backup = $Path + ".before-input-update.$suffix.bak" }
    [IO.File]::Copy($Path, $backup, $false)
    $body = $encoding.GetBytes($updated)
    $result = New-Object byte[] ($offset + $body.Length)
    [Array]::Copy($bytes, 0, $result, 0, $offset)
    [Array]::Copy($body, 0, $result, $offset, $body.Length)
    [IO.File]::WriteAllBytes($Path, $result)
    return $true
}
