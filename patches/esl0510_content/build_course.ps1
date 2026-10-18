# Builds ..\esl0510se_course.json : the teacher course "Cambridge IGCSE ESL (0510), 5-week online course".
# Week 1 only for now. To add Week 2..5: append units to a new weekN_units.json, list it below,
# and add questions to a weekN_questions.json. Re-run, then re-apply the patch.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Load($f) { Get-Content (Join-Path $here $f) -Raw -Encoding UTF8 | ConvertFrom-Json }
$unitFiles = @('week1_units.json','week2_units.json','new_units.json','impl_unit.json','week3_units.json')
$extraFiles = @('extras_week1.json','extras_week2.json')
$order = @('x1','ximpl','x2','x3','x4','x5','x11','x12','x6','x13','x7','x8','x9','x10','x14','x15','x16','x17','x18','x19')
$questionFiles = @('week1_questions.json','week2_questions.json','extra_questions.json','week3_questions.json')

function Shuffle($o, $a, $seed) {
  $rng = New-Object System.Random($seed)
  $idx = 0..($o.Count - 1)
  for ($i = $idx.Count - 1; $i -gt 0; $i--) { $j = $rng.Next(0, $i + 1); $t = $idx[$i]; $idx[$i] = $idx[$j]; $idx[$j] = $t }
  $opts = @(); $newA = 0
  for ($k = 0; $k -lt $idx.Count; $k++) { $opts += [string]$o[$idx[$k]]; if ($idx[$k] -eq [int]$a) { $newA = $k } }
  return @{ o = $opts; a = $newA }
}

$units = @(); $seed = 11
$extras = @{}
foreach ($ef in $extraFiles) { $o = Load $ef; foreach ($pr in $o.PSObject.Properties) { $extras[$pr.Name] = @($pr.Value) } }
$byId = @{}
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
    $byId[$u.id] = [ordered]@{ id = $u.id; n = [int]$u.n; week = [int]$u.week; title = $u.title; mins = [int]$u.mins; icon = $u.icon; summary = $u.summary; keyWords = @($u.keyWords); sections = $secs; activity = $u.activity; check = $checks }
  }
}
$num = 0
foreach ($id in $order) {
  $u2 = $byId[$id]; if (-not $u2) { throw "missing unit $id" }
  $num++; $u2['n'] = $num
  $w = 0; foreach ($s3 in $u2.sections) { foreach ($p3 in $s3.p) { $w += ($p3 -split '\s+').Count }; if ($s3.Contains('ex')) { foreach ($b3 in $s3.ex.b) { $w += ($b3 -split '\s+').Count } } }
  $u2['mins'] = [int]([math]::Ceiling(($w / 60 + 30) / 5) * 5)
  $units += $u2
}
$questions = @()
foreach ($f in $questionFiles) {
  foreach ($q in (Load $f)) { $seed++; $s = Shuffle $q.o $q.a $seed; $questions += [ordered]@{ ao = $q.ao; q = [string]$q.q; o = $s.o; a = $s.a; why = $q.why } }
}

$course = [ordered]@{
  code = '0510SE'; cat = 'Cambridge'; subject = 'English as a Second Language'
  title = 'Cambridge IGCSE English as a Second Language (0510), 5-Week Online Course'
  tagline = 'Know the syllabus, teach the four skills and prepare your students with confidence. Weeks 1 to 3 are open now.'
  durationLabel = '5-week online pathway, about 5 hrs/week (Weeks 1 to 3 open)'
  weeks = 5; passMark = 75; totalQuestions = $questions.Count; examMins = 40
  materials = @([ordered]@{ name = 'Cambridge IGCSE ESL (0510) Syllabus 2024 to 2026 (Speaking Endorsement)'; file = '0510-syllabus-2024-2026.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 1 Question Paper: Reading and Writing (June 2024, 0510/11)'; file = '0510-june-2024-paper-1-questions.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 1 Mark Scheme (June 2024, 0510/11)'; file = '0510-june-2024-paper-1-markscheme.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 2 Mark Scheme: Listening (June 2024, 0510/21)'; file = '0510-june-2024-paper-2-markscheme.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 2 Listening Audio (June 2024, MP3)'; file = '0510-june-2024-paper-2-audio.mp3'; kind = 'audio' }, [ordered]@{ name = 'Implementing the Curriculum with Cambridge: A guide for school leaders'; file = '0510-implementing-the-curriculum.pdf'; kind = 'pdf' })
  units = $units
  questions = $questions
}
$json = $course | ConvertTo-Json -Depth 30 -Compress
$sb = New-Object Text.StringBuilder
foreach ($ch in $json.ToCharArray()) { if ([int]$ch -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) } else { [void]$sb.Append($ch) } }
$out = Join-Path (Split-Path -Parent $here) 'esl0510se_course.json'
[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
$w = 0; foreach ($u in $units) { foreach ($s in $u.sections) { foreach ($p in $s.p) { $w += ($p -split '\s+').Count } } }
"units: $($units.Count); minutes: $((($units | % { $_.mins }) | Measure-Object -Sum).Sum); body words: $w; exam questions: $($questions.Count); bytes: $((Get-Item $out).Length)"
