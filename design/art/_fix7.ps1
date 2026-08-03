$file = "C:\Users\Biostar\WorkBuddy\2026-08-02-12-34-39\design\art\art-bible.md"
$newFile = "C:\Users\Biostar\WorkBuddy\2026-08-02-12-34-39\design\art\_new7.md"
$status = "C:\Users\Biostar\WorkBuddy\2026-08-02-12-34-39\design\art\_fix7_status.txt"
$lines = Get-Content -Path $file -Encoding UTF8
$newLines = Get-Content -Path $newFile -Encoding UTF8
$startIdx = -1; $endIdx = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -like '### 7.2*') { $startIdx = $i }
    if ($lines[$i] -like '## 8.*') { $endIdx = $i; break }
}
$msg = @()
$msg += "total lines: $($lines.Count)"
$msg += "startIdx (### 7.2): $startIdx"
$msg += "endIdx (## 8.): $endIdx"
$msg += "newLines count: $($newLines.Count)"
if ($startIdx -lt 0 -or $endIdx -lt 0) {
    $msg += "ERROR: markers not found, no change"
    Set-Content -Path $status -Value $msg -Encoding UTF8
    exit 1
}
$tailStart = $endIdx - 1
if ($tailStart -lt 0) { $tailStart = $endIdx }
$tail = $lines[$tailStart..($lines.Count-1)]
$result = $lines[0..($startIdx-1)] + $newLines + $tail
Set-Content -Path $file -Value $result -Encoding UTF8
$msg += "OK: replaced lines $($startIdx+1)..$($endIdx) with $($newLines.Count) new; tail from $($tailStart+1)"
Set-Content -Path $status -Value $msg -Encoding UTF8
