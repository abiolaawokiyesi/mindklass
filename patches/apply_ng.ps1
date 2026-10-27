# Nigerian curriculum student subjects (Student Subjects > Nigerian Curriculum).
#   powershell -ExecutionPolicy Bypass -File apply_ng.ps1 -Target ..\dist\assets\app.js
# 1. puts the courses in ng_courses.json into the student journey list (between /*NG-BEGIN*/ and /*NG-END*/, replaced on every run)
# 2. teaches the student unit page to show pictures (section.img) and tables (section.tbl), and the course page to handle assessmentType "notes"
# 3. copies patches\ng_content\img\* to materials\ng\ in dist and static
# Safe to run again. Build the JSON first with ng_content\build_ng.ps1.
param([Parameter(Mandatory = $true)][string]$Target)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$enc = [Text.Encoding]::GetEncoding(28591)
$d = $enc.GetString([IO.File]::ReadAllBytes($Target))
$json = [IO.File]::ReadAllText((Join-Path $here 'ng_courses.json'), [Text.Encoding]::UTF8)
if ($json -match '[^\x00-\x7F]') { throw 'ng_courses.json must be plain ASCII' }
if ($json.Contains('/*') -or $json.Contains('*/')) { throw 'ng_courses.json contains a comment marker' }
$inner = $json.Substring(1, $json.Length - 2)

# ---- 1. the courses ----
$b = $d.IndexOf('/*NG-BEGIN*/')
if ($b -ge 0) {
  $en = $d.IndexOf('/*NG-END*/', $b) + '/*NG-END*/'.Length
  $d = $d.Substring(0, $b) + '/*NG-BEGIN*/' + $inner + '/*NG-END*/' + $d.Substring($en)
  "  replaced the Nigerian curriculum courses"
} else {
  $gs = $d.IndexOf('var gg={'); if ($gs -lt 0) { throw 'journey list (var gg) not found' }
  $start = $gs + 7; $depth = 0; $inStr = $false; $esc = $false; $end = -1
  for ($k = $start; $k -lt $d.Length; $k++) {
    $c = $d[$k]
    if ($inStr) { if ($esc) { $esc = $false } elseif ($c -eq '\') { $esc = $true } elseif ($c -eq '"') { $inStr = $false } }
    else {
      if ($c -eq '"') { $inStr = $true }
      elseif ($c -eq '{' -or $c -eq '[') { $depth++ }
      elseif ($c -eq '}' -or $c -eq ']') { $depth--; if ($depth -eq 0) { $end = $k; break } }
    }
  }
  if ($end -lt 0) { throw 'end of the journey list not found' }
  $d = $d.Substring(0, $end) + ',/*NG-BEGIN*/' + $inner + '/*NG-END*/' + $d.Substring($end)
  "  added the Nigerian curriculum courses"
}

# ---- 2. the student unit and course pages ----
function Patch([string]$name, [string]$old, [string]$new, [string]$marker) {
  if ($script:d.Contains($marker)) { "  skip (already applied): $name"; return }
  $n = ([regex]::Matches($script:d, [regex]::Escape($old))).Count
  if ($n -ne 1) { throw "$name : expected 1 match, found $n" }
  $script:d = $script:d.Replace($old, $new)
  "  applied: $name"
}
$pOld1 = 'u.art&&Md({kind:u.art,dark:h}),u.p.map((W,T)=>e("p",{style:{fontSize:13.5,color:a.txt,lineHeight:1.75,margin:"0 0 10px"},children:W},T)),'
$pNew1 = $pOld1 + @'
u.tbl&&e("div",{style:{overflowX:"auto",margin:"2px 0 12px",border:`1px solid ${a.border}`,borderRadius:10},children:t("table",{style:{borderCollapse:"collapse",width:"100%",fontSize:12.5},children:[e("thead",{children:e("tr",{children:u.tbl.head.map((nH,nI)=>e("th",{style:{textAlign:"left",padding:"8px 10px",background:a.pale,color:a.head,borderBottom:`1px solid ${a.border}`,fontWeight:800,verticalAlign:"top"},children:nH},nI))})}),e("tbody",{children:u.tbl.rows.map((nR,nJ)=>e("tr",{children:nR.map((nC,nK)=>e("td",{style:{padding:"7px 10px",borderTop:nJ?`1px solid ${a.border}`:"none",color:a.txt,lineHeight:1.5,verticalAlign:"top",fontWeight:nK?400:700},children:nC},nK))},nJ))})]})}),u.img&&t("figure",{style:{margin:"4px 0 12px",textAlign:"center"},children:[e("img",{src:u.img.src,alt:u.img.alt||"",loading:"lazy",style:{maxWidth:"100%",maxHeight:560,width:"auto",height:"auto",objectFit:"contain",borderRadius:12,border:`1px solid ${a.border}`,background:"#fff",display:"inline-block"}}),u.img.cap&&e("figcaption",{style:{fontSize:11.5,color:a.muted,marginTop:6,lineHeight:1.5},children:u.img.cap})]}),
'@
Patch 'unit pictures and tables' $pOld1 $pNew1 'u.tbl&&e("div"'

$chipOld = 'assessmentType==="project"?[{I:_e,l:"Projects & activities"},{I:je,l:"Portfolio-graded"}]:'
Patch 'course card chips' ('x.' + $chipOld) ('x.assessmentType==="notes"?[{I:_e,l:"Notes with pictures"},{I:je,l:"Practice questions"}]:x.' + $chipOld) 'x.assessmentType==="notes"?[{I:_e'
Patch 'course header chips' ('l.' + $chipOld) ('l.assessmentType==="notes"?[{I:_e,l:"Notes with pictures"},{I:je,l:"Practice questions"}]:l.' + $chipOld) 'l.assessmentType==="notes"?[{I:_e'
Patch 'course header badge' 'l.cat==="General Courses"||l.assessmentType==="project"?l.termLabel:' 'l.cat==="General Courses"||l.assessmentType==="project"||l.assessmentType==="notes"?l.termLabel:' 'l.assessmentType==="project"||l.assessmentType==="notes"?l.termLabel:'
Patch 'practice question wording' 'children:l.assessmentType==="project"?"Answer all of these to finish the unit.' 'children:l.assessmentType==="project"||l.assessmentType==="notes"?"Answer all of these to finish the unit.' 'l.assessmentType==="project"||l.assessmentType==="notes"?"Answer all'
$pOld5 = 'l.assessmentType==="project"?t("div",{style:{...k,borderTop:"4px solid #7c3aed"}'
$pNew5 = @'
l.assessmentType==="notes"?t("div",{style:{...k,borderTop:"4px solid #059669"},children:[t("h3",{style:{fontSize:16,fontWeight:900,fontFamily:"Outfit,sans-serif",color:a.head,margin:"0 0 6px",display:"flex",alignItems:"center",gap:7},children:[e(gt,{size:17,color:"#059669"}),"Lesson notes and practice"]}),e("p",{style:{fontSize:12.5,color:a.txt,lineHeight:1.7,margin:"0 0 12px"},children:"Work through the units in order. Each unit has simple notes, pictures, worked examples and a few practice questions. The practice questions do not count towards any mark. They help you check that you understood. The term assessment for this subject will be added later."}),e("div",{style:{padding:"11px 14px",borderRadius:10,background:n.length>=l.units.length?"#dcfce7":a.alt,color:n.length>=l.units.length?"#047857":a.muted,fontSize:12.5,fontWeight:700},children:n.length>=l.units.length?"You have completed every unit in this term. Well done!":`Progress: ${n.length}/${l.units.length} units complete.`})]}):
'@.TrimEnd("`r", "`n") + $pOld5
Patch 'course page notes panel' $pOld5 $pNew5 '"Lesson notes and practice"'
Patch 'last unit button' '"Ready to take assessment",e(ge,{size:13,style:{marginLeft:3,verticalAlign:"middle"}})]})]}):t("div"' 'l.assessmentType==="notes"?"Back to the course":"Ready to take assessment",e(ge,{size:13,style:{marginLeft:3,verticalAlign:"middle"}})]})]}):t("div"' '"Back to the course"'
[IO.File]::WriteAllBytes($Target, $enc.GetBytes($d))
"patched: $Target"

# ---- 3. the pictures ----
$dist = Split-Path -Parent (Split-Path -Parent $Target)
$proj = Split-Path -Parent $dist
$src = Join-Path $here 'ng_content\img'
$dests = @((Join-Path $dist 'materials\ng'))
if (Test-Path (Join-Path $proj 'static')) { $dests += (Join-Path $proj 'static\materials\ng') }
foreach ($dd in $dests) { New-Item -ItemType Directory -Force $dd | Out-Null; Copy-Item (Join-Path $src '*') $dd -Force; "  pictures copied to $dd ($((Get-ChildItem $dd -File).Count) files)" }
