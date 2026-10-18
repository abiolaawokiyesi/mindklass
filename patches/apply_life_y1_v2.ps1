# Windows equivalent of patch_life_y1_v2.py (use when Python is not installed).
#   powershell -ExecutionPolicy Bypass -File apply_life_y1_v2.ps1 -Target ..\dist\assets\app.js
param([Parameter(Mandatory = $true)][string]$Target)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = [Text.Encoding]::GetEncoding(28591)            # latin-1: byte-exact round trip
$d = $enc.GetString([IO.File]::ReadAllBytes($Target))
if ($d.Contains('"assessmentType":"project"')) { throw 'already patched' }

# --- 1. replace the LIFE-Y1 course object -----------------------------------
$key = '"LIFE-Y1":{'
if (([regex]::Matches($d, [regex]::Escape($key))).Count -ne 1) { throw 'LIFE-Y1 key not found exactly once' }
$start = $d.IndexOf($key) + $key.Length - 1            # index of the opening {
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
if ($end -lt 0) { throw 'could not find end of LIFE-Y1 object' }
$new = [IO.File]::ReadAllText((Join-Path $here 'lifey1_v2.json'))
$d = $d.Substring(0, $start) + $new + $d.Substring($end + 1)
"replaced LIFE-Y1: $($end - $start + 1) -> $($new.Length) chars"

# --- 2. UI swaps ------------------------------------------------------------
$swaps = Get-Content (Join-Path $here 'life_y1_ui_patches.json') -Raw | ConvertFrom-Json
foreach ($s in $swaps) {
  $n = ([regex]::Matches($d, [regex]::Escape($s.old))).Count
  if ($n -ne 1) { throw "swap '$($s.name)': anchor found $n times" }
  $d = $d.Replace($s.old, $s.new)
  "swap ok: $($s.name)"
}
[IO.File]::WriteAllBytes($Target, $enc.GetBytes($d))
"done: $Target"
