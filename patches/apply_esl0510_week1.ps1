# Windows equivalent of patch_esl0510_week1.py (adds OR replaces the 0510SE course).
#   powershell -ExecutionPolicy Bypass -File apply_esl0510_week1.ps1 -Target ..\dist\assets\app.js
param([Parameter(Mandatory = $true)][string]$Target)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = [Text.Encoding]::GetEncoding(28591)
$d = $enc.GetString([IO.File]::ReadAllBytes($Target))
$course = [IO.File]::ReadAllText((Join-Path $here 'esl0510se_course.json'))
$key = '"0510SE":{'
if ($d.Contains($key)) {
  $start = $d.IndexOf($key) + $key.Length - 1
  $depth = 0; $inStr = $false; $esc = $false; $end = -1
  for ($k = $start; $k -lt $d.Length; $k++) {
    $c = $d[$k]
    if ($inStr) { if ($esc) { $esc = $false } elseif ($c -eq '\') { $esc = $true } elseif ($c -eq '"') { $inStr = $false } }
    else {
      if ($c -eq '"') { $inStr = $true }
      elseif ($c -eq '{' -or $c -eq '[') { $depth++ }
      elseif ($c -eq '}' -or $c -eq ']') { $depth--; if ($depth -eq 0) { $end = $k; break } }
    }
  }
  if ($end -lt 0) { throw 'end of 0510SE not found' }
  $d = $d.Substring(0, $start) + $course + $d.Substring($end + 1)
  "replaced existing 0510SE"
} else {
  $anchor = ',mm={"0510":{code:"0510",cat:"Cambridge"'
  $n = ([regex]::Matches($d, [regex]::Escape($anchor))).Count
  if ($n -ne 1) { throw "anchor found $n times" }
  $d = $d.Replace($anchor, ',mm={"0510SE":' + $course + ',"0510":{code:"0510",cat:"Cambridge"')
  "added 0510SE"
}
[IO.File]::WriteAllBytes($Target, $enc.GetBytes($d))
"patched: $Target"