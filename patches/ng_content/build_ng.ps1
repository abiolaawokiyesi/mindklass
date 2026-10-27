# Builds ..\ng_courses.json : the Nigerian-curriculum subjects shown under Student Subjects > Nigerian Curriculum.
# Each term of each subject is one course (assessmentType "notes"): unit 1 is the introduction and table of contents,
# the other units are lesson notes with pictures, worked examples and practice questions.
# Re-run after editing any unit file, then re-apply with apply_ng.ps1.
#   powershell -ExecutionPolicy Bypass -File build_ng.ps1
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$imgDir = Join-Path $here 'img'
function Load($f) { Get-Content (Join-Path $here $f) -Raw -Encoding UTF8 | ConvertFrom-Json }
$iconOk = @('Target', 'BookOpen', 'PenLine', 'ClipboardCheck', 'Users', 'Shield', 'Award', 'BarChart2', 'Calendar', 'Camera', 'Heart', 'Landmark', 'Layers', 'Megaphone', 'Trophy', 'Zap', 'Volume2', 'ClipboardList', 'LayoutDashboard', 'CheckCircle')
$iconMap = @{ Calculator = 'BarChart2'; Globe = 'Landmark'; Book = 'BookOpen'; Pencil = 'PenLine'; Star = 'Award'; Clock = 'Calendar'; Brain = 'Layers'; Lightbulb = 'Zap' }

# ---- the courses (add new subjects and terms here) ----
$courses = @(
  @{ code = 'NG-SS1-PHY-T1'; group = 'SS1 Physics'; subject = 'Physics'; term = 1; termLabel = ('SS1 ' + [char]0xB7 + ' First Term'); title = 'SS1 Physics: First Term Lesson Notes'
     tagline = 'Measurement, physical quantities, vectors, speed, velocity and acceleration, graphs of motion, force, friction and the equations of motion. Simple notes with pictures, worked examples and practice questions.'
     months = 'Weeks 1 to 10'; files = @('phy1_a.json', 'phy1_b.json', 'phy1_c.json') },
  @{ code = 'NG-SS1-PHY-T2'; group = 'SS1 Physics'; subject = 'Physics'; term = 2; termLabel = ('SS1 ' + [char]0xB7 + ' Second Term'); title = 'SS1 Physics: Second Term Lesson Notes'
     tagline = 'Momentum and Newton''s laws, work, energy and power, simple machines, heat and temperature, specific and latent heat, and the particles of matter. Simple notes with pictures, worked examples and practice questions.'
     months = 'Weeks 1 to 10'; files = @('phy2_a.json', 'phy2_b.json', 'phy2_c.json') },
  @{ code = 'NG-SS1-PHY-T3'; group = 'SS1 Physics'; subject = 'Physics'; term = 3; termLabel = ('SS1 ' + [char]0xB7 + ' Third Term'); title = 'SS1 Physics: Third Term Lesson Notes'
     tagline = 'Fluids at rest and in motion, the gas laws, simple harmonic motion, projectiles and waves. Simple notes with pictures, worked examples and practice questions.'
     months = 'Weeks 1 to 10'; files = @('phy3_a.json', 'phy3_b.json', 'phy3_c.json') }
)
$extra = Join-Path $here 'courses_more.ps1'
if (Test-Path $extra) { $courses += (. $extra) }

function Shuffle($o, $a, $seed) {
  $rng = New-Object System.Random($seed)
  $idx = 0..($o.Count - 1)
  for ($i = $idx.Count - 1; $i -gt 0; $i--) { $j = $rng.Next(0, $i + 1); $t = $idx[$i]; $idx[$i] = $idx[$j]; $idx[$j] = $t }
  $opts = @(); $newA = 0
  for ($k = 0; $k -lt $idx.Count; $k++) { $opts += [string]$o[$idx[$k]]; if ($idx[$k] -eq [int]$a) { $newA = $k } }
  return @{ o = $opts; a = $newA }
}
function Words($s) { return ([string]$s -split '\s+' | Where-Object { $_ }).Count }

$warn = @(); $usedImg = @{}; $all = [ordered]@{}; $report = @()
$seed = 5000
foreach ($c in $courses) {
  $units = @(); $n = 0
  foreach ($f in $c.files) {
    foreach ($u in (Load $f)) {
      $n++
      $checks = @()
      if (-not $u.check -or @($u.check).Count -lt 3) { $warn += "$($u.id): fewer than 3 practice questions" }
      foreach ($q in @($u.check)) {
        $seed++
        if (@($q.o).Count -ne 4) { $warn += "$($u.id): question needs 4 options: $($q.q)" }
        $s = Shuffle @($q.o) 0 $seed
        $checks += [ordered]@{ q = [string]$q.q; o = $s.o; a = $s.a }
      }
      $secs = @(); $w = 0
      foreach ($s2 in @($u.sections)) {
        $sec = [ordered]@{ h = [string]$s2.h; p = @($s2.p | ForEach-Object { [string]$_ }) }
        foreach ($p3 in $sec.p) { $w += Words $p3 }
        if ($s2.tbl) {
          $rows = @(); foreach ($r in @($s2.tbl.rows)) { $rows += , @($r | ForEach-Object { [string]$_ }) }
          $hd = @($s2.tbl.head | ForEach-Object { [string]$_ })
          foreach ($r in $rows) { if ($r.Count -ne $hd.Count) { $warn += "$($u.id): table row width differs in '$($s2.h)'" }; foreach ($cell in $r) { $w += Words $cell } }
          $sec['tbl'] = [ordered]@{ head = $hd; rows = $rows }
        }
        if ($s2.img) {
          $file = [string]$s2.img.src
          if (-not (Test-Path (Join-Path $imgDir $file))) { $warn += "$($u.id): picture missing: $file" }
          $usedImg[$file] = $true
          $sec['img'] = [ordered]@{ src = "/materials/ng/$file"; alt = [string]$s2.img.alt; cap = [string]$s2.img.cap }
        }
        if ($s2.ex) {
          $sec['ex'] = [ordered]@{ t = [string]$s2.ex.t; b = @($s2.ex.b | ForEach-Object { [string]$_ }) }
          foreach ($b3 in $sec.ex.b) { $w += Words $b3 }
        }
        $secs += $sec
      }
      $mins = [int][math]::Ceiling($w / 110 + 6)
      $icon = [string]$u.icon; if ($iconMap.ContainsKey($icon)) { $icon = $iconMap[$icon] }
      if ($iconOk -notcontains $icon) { $warn += "$($u.id): icon '$icon' not in the app icon set" }
      $units += [ordered]@{ id = [string]$u.id; n = $n; week = [int]$u.week; title = [string]$u.title; mins = $mins; icon = $icon; summary = [string]$u.summary; keyWords = @($u.keyWords | ForEach-Object { [string]$_ }); sections = $secs; activity = [string]$u.activity; check = $checks }
    }
  }
  $tw = 0; foreach ($u in $units) { foreach ($s in $u.sections) { foreach ($p in $s.p) { $tw += Words $p } } }
  $report += "$($c.code): $($units.Count) units, $tw body words, $((($units | ForEach-Object { $_.mins }) | Measure-Object -Sum).Sum) min"
  $term = [ordered]@{
    code = $c.code; subject = $c.group; group = $c.group; cat = 'Nigerian Curriculum'; year = 'SS1'; term = [int]$c.term
    termLabel = $c.termLabel; title = $c.title; tagline = $c.tagline; months = $c.months
    passMark = 0; totalQuestions = 0; examMins = 0; assessmentType = 'notes'; materials = @(); units = $units
  }
  $all[$c.code] = $term
}
foreach ($f in (Get-ChildItem $imgDir -File)) { if (-not $usedImg.ContainsKey($f.Name)) { $warn += "picture not used by any unit: $($f.Name)" } }
$report
if ($warn.Count) { $warn; if ($warn | Where-Object { $_ -notmatch 'not used by any unit' }) { throw 'fix the warnings above first' } }
$json = $all | ConvertTo-Json -Depth 30 -Compress
$sb = New-Object Text.StringBuilder
foreach ($ch in $json.ToCharArray()) { if ([int]$ch -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) } else { [void]$sb.Append($ch) } }
$text = $sb.ToString().Replace('\\u00b7', '·')
$out = Join-Path (Split-Path -Parent $here) 'ng_courses.json'
[IO.File]::WriteAllText($out, $text, (New-Object Text.UTF8Encoding($false)))
"courses: $($all.Count); bytes: $((Get-Item $out).Length)"
