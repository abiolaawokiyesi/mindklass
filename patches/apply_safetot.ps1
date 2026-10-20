# Adds or replaces the teacher course "SAFETOT" (Safeguarding Training of Trainers and Capacity Building).
#   powershell -ExecutionPolicy Bypass -File apply_safetot.ps1 -Target ..\dist\assets\app.js
# Needs the teacher-unit figure support that apply_esl0510_week1.ps1 adds (section.img); run that first.
param([Parameter(Mandatory = $true)][string]$Target)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = [Text.Encoding]::GetEncoding(28591)
$d = $enc.GetString([IO.File]::ReadAllBytes($Target))
$course = [IO.File]::ReadAllText((Join-Path $here 'safetot_course.json'))
$key = '"SAFETOT":{'
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
  if ($end -lt 0) { throw 'end of SAFETOT not found' }
  $d = $d.Substring(0, $start) + $course + $d.Substring($end + 1)
  "replaced existing SAFETOT"
} else {
  $anchor = ',mm={'
  $n = ([regex]::Matches($d, [regex]::Escape($anchor))).Count
  if ($n -ne 1) { throw "anchor found $n times" }
  $d = $d.Replace($anchor, ',mm={"SAFETOT":' + $course + ',')
  "added SAFETOT"
}
if (-not $d.Contains('d.img&&t("figure"')) { throw 'figure support missing: run apply_esl0510_week1.ps1 first' }
[IO.File]::WriteAllBytes($Target, $enc.GetBytes($d))
"patched: $Target"
