# Builds ..\esl0510se_course.json : the teacher course "Cambridge IGCSE ESL (0510), 5-week online course".
# Week 1 only for now. To add Week 2..5: append units to a new weekN_units.json, list it below,
# and add questions to a weekN_questions.json. Re-run, then re-apply the patch.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Load($f) { Get-Content (Join-Path $here $f) -Raw -Encoding UTF8 | ConvertFrom-Json }
$unitFiles = @('week1_units.json','week2_units.json','new_units.json','impl_unit.json','week3_units.json','toc_unit.json','week4a_units.json','week4b_units.json','week5a_units.json','week5b_units.json','week5c_units.json')
$extraFiles = @('extras_week1.json','extras_week2.json','extras_new.json')
$order = @('x0','x1','ximpl','x2','x3','x4','x5','x11','x12','x6','x13','x7','x8','x9','x10','x14','x15','x16','x17','x18','x19','x20','x21','x22','x23','x24','x25','x26','x27','x28','x29','x30','x31','x32','x33','x34')
$questionFiles = @('week1_questions.json','week2_questions.json','extra_questions.json','week3_questions.json','week45_questions.json')
# Icon names the app knows (the Ci map in app.js); anything else falls back to a book.
$iconMap = @{ Map = 'Target'; Clock = 'Calendar'; ListChecks = 'ClipboardList'; Mic = 'Volume2'; Headphones = 'Volume2'; MessageCircle = 'Users'; BookOpen = 'BookOpen'; Layers = 'Layers' }
$artOk = @('command','build','weigh','society','science','data','interpret','sample','ethics','culture','roles','social','agency','control','law','identity','global','layers','chance','gap','help','migrate','planet','family','marriage','home','school','achieve','crime','measure','theory','punish','target','steps','chart','mark','search','write','match','read','talk','listen','scale')
$artWarn = @()

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
      if ($artOk -notcontains $s2.art) { $artWarn += "unit $($u.id): unknown art '$($s2.art)'" }
      $sec = [ordered]@{ h = $s2.h; art = $s2.art; p = @($s2.p) }
      if ($s2.ex) { $sec['ex'] = [ordered]@{ t = $s2.ex.t; b = @($s2.ex.b) } }
      if ($s2.img) { $sec['img'] = [ordered]@{ src = $s2.img.src; alt = $s2.img.alt; cap = $s2.img.cap } }
      $secs += $sec
    }
    if ($extras.ContainsKey($u.id)) { foreach ($x in $extras[$u.id]) { $sec = [ordered]@{ h = $x.h; art = $x.art; p = @($x.p) }; if ($x.ex) { $sec['ex'] = [ordered]@{ t = $x.ex.t; b = @($x.ex.b) } }; $secs += $sec } }
    $icon = $u.icon; if ($iconMap.ContainsKey($icon)) { $icon = $iconMap[$icon] }
    $byId[$u.id] = [ordered]@{ id = $u.id; n = [int]$u.n; week = [int]$u.week; title = $u.title; mins = [int]$u.mins; icon = $icon; summary = $u.summary; keyWords = @($u.keyWords); sections = $secs; activity = $u.activity; check = $checks }
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

if ($artWarn.Count) { $artWarn; throw 'fix the art warnings above first' }
# the table of contents and the wrap-up mention the number of final questions
$qc = [string]$questions.Count
foreach ($u in $units) { foreach ($s in $u.sections) { $s['p'] = @($s['p'] | ForEach-Object { ([string]$_).Replace('{{QCOUNT}}', $qc) }) } }
$course = [ordered]@{
  code = '0510SE'; cat = 'Cambridge'; subject = 'English as a Second Language'
  title = 'Cambridge IGCSE English as a Second Language (0510), 5-Week Online Course'
  tagline = 'Know the syllabus, mark like an examiner, plan the year and every lesson, and teach and create resources with confidence. All five weeks are open, with a full table of contents.'
  durationLabel = '5-week online pathway, about 5 hrs/week (all 5 weeks open)'
  weeks = 5; passMark = 75; totalQuestions = $questions.Count; examMins = 90
  materials = @([ordered]@{ name = 'Cambridge IGCSE ESL (0510) Syllabus 2024 to 2026 (Speaking Endorsement)'; file = '0510-syllabus-2024-2026.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 1 Question Paper: Reading and Writing (June 2024, 0510/11)'; file = '0510-june-2024-paper-1-questions.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 1 Mark Scheme (June 2024, 0510/11)'; file = '0510-june-2024-paper-1-markscheme.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 2 Mark Scheme: Listening (June 2024, 0510/21)'; file = '0510-june-2024-paper-2-markscheme.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Paper 2 Listening Audio (June 2024, MP3)'; file = '0510-june-2024-paper-2-audio.mp3'; kind = 'audio' }, [ordered]@{ name = 'Principal Examiner Report for Teachers (June 2024, Speaking Endorsement)'; file = '0510-june-2024-examiner-report.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Specimen Paper 1: Reading and Writing (for examination from 2024)'; file = '0510-specimen-paper-1.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Specimen Paper 1 Mark Scheme (for examination from 2024)'; file = '0510-specimen-paper-1-markscheme.pdf'; kind = 'pdf' }, [ordered]@{ name = 'Implementing the Curriculum with Cambridge: A guide for school leaders'; file = '0510-implementing-the-curriculum.pdf'; kind = 'pdf' })
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
