# Builds ..\safetot_course.json : teacher course "Safeguarding Training of Trainers and Capacity Building" (code SAFETOT).
# 22 units over 6 weeks (unit 1 is the table of contents) and a 100-question end-of-course assessment.
# Re-run after editing any units_*.json or questions_*.json, then re-apply with apply_safetot.ps1.
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Load($f) { Get-Content (Join-Path $here $f) -Raw -Encoding UTF8 | ConvertFrom-Json }
$unitFiles = @('units_a.json', 'units_b.json', 'units_c.json', 'units_d.json', 'units_e.json')
$questionFiles = @('questions_1.json', 'questions_2.json')
$iconMap = @{ Map = 'Target'; BarChart3 = 'BarChart2'; Home = 'LayoutDashboard'; UserPlus = 'Users'; UserCheck = 'CheckCircle'; HeartHandshake = 'Heart'; Scale = 'Landmark'; ListChecks = 'ClipboardList'; Flag = 'Trophy' }
$artOk = @('command','build','weigh','society','science','data','interpret','sample','ethics','culture','roles','social','agency','control','law','identity','global','layers','chance','gap','help','migrate','planet','family','marriage','home','school','achieve','crime','measure','theory','punish','target','steps','chart','mark','search','write','match','read','talk','listen','scale')

function Shuffle($o, $a, $seed) {
  $rng = New-Object System.Random($seed)
  $idx = 0..($o.Count - 1)
  for ($i = $idx.Count - 1; $i -gt 0; $i--) { $j = $rng.Next(0, $i + 1); $t = $idx[$i]; $idx[$i] = $idx[$j]; $idx[$j] = $t }
  $opts = @(); $newA = 0
  for ($k = 0; $k -lt $idx.Count; $k++) { $opts += [string]$o[$idx[$k]]; if ($idx[$k] -eq [int]$a) { $newA = $k } }
  return @{ o = $opts; a = $newA }
}
$units = @(); $seed = 2001; $warn = @()
foreach ($f in $unitFiles) {
  foreach ($u in (Load $f)) {
    $checks = @()
    foreach ($q in $u.check) { $seed++; $s = Shuffle $q.o $q.a $seed; $checks += [ordered]@{ q = [string]$q.q; o = $s.o; a = $s.a } }
    $secs = @()
    foreach ($s2 in $u.sections) {
      if ($artOk -notcontains $s2.art) { $warn += "unit $($u.id): unknown art '$($s2.art)'" }
      $sec = [ordered]@{ h = $s2.h; art = $s2.art; p = @($s2.p) }
      if ($s2.ex) { $sec['ex'] = [ordered]@{ t = $s2.ex.t; b = @($s2.ex.b) } }
      if ($s2.img) { $sec['img'] = [ordered]@{ src = $s2.img.src; alt = $s2.img.alt; cap = $s2.img.cap } }
      $secs += $sec
    }
    $w = 0; foreach ($s3 in $secs) { foreach ($p3 in $s3.p) { $w += ($p3 -split '\s+').Count }; if ($s3.Contains('ex')) { foreach ($b3 in $s3.ex.b) { $w += ($b3 -split '\s+').Count } } }
    $mins = [int]([math]::Ceiling(($w / 60 + 30) / 5) * 5)
    $icon = $u.icon; if ($iconMap.ContainsKey($icon)) { $icon = $iconMap[$icon] }
    $units += [ordered]@{ id = $u.id; n = [int]$u.n; week = [int]$u.week; title = $u.title; mins = $mins; icon = $icon; summary = $u.summary; keyWords = @($u.keyWords); sections = $secs; activity = $u.activity; check = $checks }
  }
}
$questions = @(); $seed = 9001
foreach ($f in $questionFiles) {
  foreach ($q in (Load $f)) {
    $c = @($q.o | ForEach-Object { ($_.Trim() -split '\s+').Count })
    if (($c | Select-Object -Unique).Count -ne 1) { $warn += "question '$($q.q)' option word counts differ: $($c -join ',')" }
    $seed++; $s = Shuffle $q.o $q.a $seed
    $questions += [ordered]@{ ao = $q.ao; q = [string]$q.q; o = $s.o; a = $s.a; why = $q.why }
  }
}
if ($warn.Count) { $warn; throw 'fix the warnings above first' }
$course = [ordered]@{
  code = 'SAFETOT'; cat = 'Safeguarding'; subject = 'Safeguarding Training of Trainers'
  title = 'Safeguarding Training of Trainers and Capacity Building (6-Week Course)'
  tagline = 'Build a safe organisation and train others: policies, culture, roles, risk assessment, safer recruitment, reporting, response, media and awareness. Starts with a full table of contents.'
  durationLabel = '6-week online pathway, about 3 to 4 hrs/week'
  weeks = 6; passMark = 75; totalQuestions = $questions.Count; examMins = 120
  materials = @()
  units = $units
  questions = $questions
}
$json = $course | ConvertTo-Json -Depth 30 -Compress
$sb = New-Object Text.StringBuilder
foreach ($ch in $json.ToCharArray()) { if ([int]$ch -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) } else { [void]$sb.Append($ch) } }
$out = Join-Path (Split-Path -Parent $here) 'safetot_course.json'
[IO.File]::WriteAllText($out, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
$tw = 0; foreach ($u in $units) { foreach ($s in $u.sections) { foreach ($p in $s.p) { $tw += ($p -split '\s+').Count } } }
$pos = @(0, 0, 0, 0); foreach ($q in $questions) { $pos[$q.a]++ }
"units: $($units.Count); minutes: $((($units | ForEach-Object { $_.mins }) | Measure-Object -Sum).Sum); body words: $tw; exam questions: $($questions.Count); answer positions A/B/C/D: $($pos -join '/'); bytes: $((Get-Item $out).Length)"
