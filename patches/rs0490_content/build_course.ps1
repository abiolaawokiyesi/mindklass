# Builds ..\rs0490_course.json : teacher course "Cambridge IGCSE Religious Studies (0490), 6-week online course".
# Add Weeks 2..6 later: new weekN_units.json / weekN_questions.json, list them below, re-run, then re-apply.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Load($f) { Get-Content (Join-Path $here $f) -Raw -Encoding UTF8 | ConvertFrom-Json }
$unitFiles = @('week1_units.json','week2a_units.json','week2b_units.json','week2c_units.json','week2d_units.json')
$extraFiles = @('extras_week1.json')
$questionFiles = @('week1_questions.json','week2_questions.json')

function Shuffle($o, $a, $seed) {
  $rng = New-Object System.Random($seed)
  $idx = 0..($o.Count - 1)
  for ($i = $idx.Count - 1; $i -gt 0; $i--) { $j = $rng.Next(0, $i + 1); $t = $idx[$i]; $idx[$i] = $idx[$j]; $idx[$j] = $t }
  $opts = @(); $newA = 0
  for ($k = 0; $k -lt $idx.Count; $k++) { $opts += [string]$o[$idx[$k]]; if ($idx[$k] -eq [int]$a) { $newA = $k } }
  return @{ o = $opts; a = $newA }
}
$units = @(); $seed = 101
$extras = @{}
foreach ($ef in $extraFiles) { $o = Load $ef; foreach ($pr in $o.PSObject.Properties) { $extras[$pr.Name] = @($pr.Value) } }
foreach ($f in $unitFiles) {
  foreach ($u in (Load $f)) {
    $checks = @()
    foreach ($q in $u.check) { $seed++; $s = Shuffle $q.o $q.a $seed; $checks += [ordered]@{ q = [string]$q.q; o = $s.o; a = $s.a } }
    $secs = @()
    foreach ($s2 in $u.sections) {
      $sec = [ordered]@{ h = $s2.h; art = $s2.art; p = @($s2.p) }
      if ($s2.ex) { $sec['ex'] = [ordered]@{ t = $s2.ex.t; b = @($s2.ex.b) } }
      if ($s2.img) { $sec['img'] = [ordered]@{ src = $s2.img.src; alt = $s2.img.alt; cap = $s2.img.cap } }
      $secs += $sec
    }
    if ($extras.ContainsKey($u.id)) { foreach ($x in $extras[$u.id]) { $sec = [ordered]@{ h = $x.h; art = $x.art; p = @($x.p) }; if ($x.ex) { $sec['ex'] = [ordered]@{ t = $x.ex.t; b = @($x.ex.b) } }; $secs += $sec } }
    $w = 0; foreach ($s3 in $secs) { foreach ($p3 in $s3.p) { $w += ($p3 -split '\s+').Count }; if ($s3.Contains('ex')) { foreach ($b3 in $s3.ex.b) { $w += ($b3 -split '\s+').Count } } }
    $mins = [int]([math]::Ceiling(($w / 60 + 30) / 5) * 5)
    $units += [ordered]@{ id = $u.id; n = [int]$u.n; week = [int]$u.week; title = $u.title; mins = $mins; icon = $u.icon; summary = $u.summary; keyWords = @($u.keyWords); sections = $secs; activity = $u.activity; check = $checks }
  }
}
$questions = @()
foreach ($f in $questionFiles) {
  foreach ($q in (Load $f)) { $seed++; $s = Shuffle $q.o $q.a $seed; $questions += [ordered]@{ ao = $q.ao; q = [string]$q.q; o = $s.o; a = $s.a; why = $q.why } }
}
$course = [ordered]@{
  code = '0490'; cat = 'Cambridge'; subject = 'Religious Studies'
  title = 'Cambridge IGCSE Religious Studies (0490), 6-Week Online Course'
  tagline = 'Understand the syllabus, plan your course and teach Christianity, Islam and Judaism with fairness and confidence. Weeks 1 and 2 are open now.'
  durationLabel = '6-week online pathway, about 5 hrs/week (Weeks 1 and 2 open)'
  weeks = 6; passMark = 75; totalQuestions = $questions.Count; examMins = 45
  materials = @(
    [ordered]@{ name = 'Cambridge IGCSE Religious Studies (0490) Syllabus for 2025, 2026 and 2027'; file = '0490-syllabus-2025-2027.pdf'; kind = 'pdf' },
    [ordered]@{ name = 'Implementing the Curriculum with Cambridge: A guide for school leaders'; file = '0510-implementing-the-curriculum.pdf'; kind = 'pdf' })
  units = $units
  questions = $questions
}
$json = $course | ConvertTo-Json -Depth 30 -Compress
$sb = New-Object Text.StringBuilder
foreach ($ch in $json.ToCharArray()) { if ([int]$ch -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) } else { [void]$sb.Append($ch) } }
$out = Join-Path (Split-Path -Parent $here) 'rs0490_course.json'
[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
$tw = 0; foreach ($u in $units) { foreach ($s in $u.sections) { foreach ($p in $s.p) { $tw += ($p -split '\s+').Count } } }
"units: $($units.Count); minutes: $((($units | % { $_.mins }) | Measure-Object -Sum).Sum); body words: $tw; exam questions: $($questions.Count); bytes: $((Get-Item $out).Length)"
