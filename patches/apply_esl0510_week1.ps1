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
# teacher unit view: render an optional figure (section.img) before the example box
$old = 'd.art&&Md({kind:d.art,dark:h}),d.p.map((x,N)=>e("p",{style:{fontSize:13.5,color:a.txt,lineHeight:1.75,margin:"0 0 10px"},children:x},N)),d.ex&&'
$new = 'd.art&&Md({kind:d.art,dark:h}),d.p.map((x,N)=>e("p",{style:{fontSize:13.5,color:a.txt,lineHeight:1.75,margin:"0 0 10px"},children:x},N)),d.img&&t("figure",{style:{margin:"4px 0 12px"},children:[e("img",{src:d.img.src,alt:d.img.alt||"",style:{width:"100%",height:"auto",borderRadius:12,border:`1px solid ${a.border}`,background:"#fff",display:"block"}}),d.img.cap&&e("figcaption",{style:{fontSize:11,color:a.muted,marginTop:6,lineHeight:1.5},children:d.img.cap})]}),d.ex&&'
if (-not $d.Contains('d.img&&t("figure"')) { $n2 = ([regex]::Matches($d, [regex]::Escape($old))).Count; if ($n2 -ne 1) { throw "figure anchor found $n2 times" }; $d = $d.Replace($old, $new); "added figure rendering" }
[IO.File]::WriteAllBytes($Target, $enc.GetBytes($d))
"patched: $Target"