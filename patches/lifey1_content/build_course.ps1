# Builds patches/lifey1_v2.json: the redesigned LIFE-Y1 course object.
#   inputs : original_lifey1.json (verbatim stories, titles, ids, discussion questions)
#            batch1..5.json and special.json (new authored content)
#   output : ..\lifey1_v2.json  (UTF-8, non-ASCII escaped, ready to embed in the bundle)
# Run:  powershell -ExecutionPolicy Bypass -File build_course.ps1
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
function Load($f) { Get-Content (Join-Path $here $f) -Raw -Encoding UTF8 | ConvertFrom-Json }

$orig = Load 'original_lifey1.json'
$special = Load 'special.json'
$batches = @()
foreach ($b in 'batch1.json','batch2.json','batch3.json','batch4.json','batch5.json') { $batches += (Load $b) }
$byN = @{}
foreach ($u in $batches) { $byN[[int]$u.n] = $u }
$specN = @{}
foreach ($u in $special.units) { $specN[[int]$u.n] = $u }

function Shuffle-Check($check, $seed) {
  $out = @(); $qi = 0
  foreach ($q in $check) {
    $rng = New-Object System.Random(($seed * 101 + $qi * 17 + 3))
    $idx = 0..($q.o.Count - 1)
    for ($i = $idx.Count - 1; $i -gt 0; $i--) { $j = $rng.Next(0, $i + 1); $t = $idx[$i]; $idx[$i] = $idx[$j]; $idx[$j] = $t }
    $opts = @(); $newA = 0
    for ($k = 0; $k -lt $idx.Count; $k++) { $opts += [string]$q.o[$idx[$k]]; if ($idx[$k] -eq [int]$q.a) { $newA = $k } }
    $out += [ordered]@{ q = [string]$q.q; o = $opts; a = $newA }
    $qi++
  }
  return ,$out
}
function Sec($art, $h, $p, $ex = $null) {
  $s = [ordered]@{ art = $art; h = $h; p = @($p) }
  if ($ex) { $s['ex'] = [ordered]@{ t = $ex.t; b = @($ex.b) } }
  return $s
}
function Bul($arr) { @($arr | ForEach-Object { [string][char]0x2022 + ' ' + $_ }) }
function Numbered($arr) { $i = 0; @($arr | ForEach-Object { $i++; "$i. $_" }) }

$ideaArt = @{ 3='identity'; 5='ethics'; 8='identity'; 9='help'; 17='identity'; 20='scale'; 21='help'; 23='culture'; 27='data'; 28='scale'; 29='ethics'; 31='roles'; 33='global'; 34='data'; 35='global'; 36='control'; 37='identity'; 39='data'; 46='help' }
$units = @()
foreach ($ou in $orig.units) {
  $n = [int]$ou.n
  $nu = [ordered]@{ id = $ou.id; n = $n; title = $ou.title; mins = 60; icon = $ou.icon }
  if ($n -eq 0) {
    $s = $specN[0]
    $nu.title = $s.title; $nu.mins = $s.mins; $nu.icon = $s.icon; $nu['summary'] = $s.summary
    $nu['keyWords'] = @($s.keyWords)
    $secs = @()
    foreach ($x in $s.sections) { $secs += (Sec $x.art $x.h $x.p $x.ex) }
    $nu['sections'] = $secs; $nu['activity'] = $s.activity
    $nu['check'] = Shuffle-Check $s.check 0
  }
  elseif ($specN.ContainsKey($n)) {
    $s = $specN[$n]
    $nu.title = $s.title; $nu.icon = $s.icon; $nu['summary'] = $s.summary
    $nu['keyWords'] = @($s.keyWords)
    $secs = @()
    $secs += (Sec 'target' 'Your learning goals' (@('By the end of this capstone you will be able to:') + (Bul $s.goals)))
    $secs += (Sec 'talk' 'Warm-up (5 min)' @($s.warmup))
    $secs += (Sec 'steps' 'The challenge brief' $s.brand @{ t = 'Deliverables checklist'; b = $s.deliver })
    $secs += (Sec 'scale' 'How you will be judged' (@('This capstone is assessed with a rubric, not a written exam. Judges look for:') + (Bul $s.rubric)) @{ t = 'Awards you can earn'; b = @($s.awards) })
    $secs += (Sec 'build' 'Build your presentation' $s.timeline)
    $secs += (Sec 'listen' 'Give feedback: Two Stars and a Wish' @('After each presentation the audience gives two stars (two specific things done well) and one wish (one specific thing to improve). Feedback must be kind, specific and about the work, not the person.','When you receive feedback, write it down without defending yourself, then choose one change to make.'))
    $secs += (Sec 'steps' 'Preparation checklist' (Bul @('Rehearse out loud at least twice with a timer','Bring every deliverable in your portfolio, plus a backup copy','Prepare answers to the three hardest questions you expect','Arrive early and test any technology you will use')))
    $secs += (Sec 'identity' 'Reflect in your journal' $s.reflect)
    $secs += (Sec 'achieve' 'Key takeaways and self-rating' ((Bul @('Evidence is stronger than claims','Coherence and honesty matter more than polish','Feedback is a gift that speeds up your growth')) + @('Self-rating (1 to 5): How confident do I feel about presenting my work, and what would move me up one point?')))
    $nu['sections'] = $secs
    $nu['activity'] = "Present this quarter's capstone, collect the rubric feedback and add your presentation, feedback and a one-page reflection to your portfolio. Assessment is entirely through the project rubric; there is no written exam."
    $nu['check'] = Shuffle-Check $s.check $n
  }
  else {
    $c = $byN[$n]
    if (-not $c) { throw "No authored content for unit $n" }
    $ice = ''; $story = $null; $disc = $null
    foreach ($sec in $ou.sections) {
      if ($sec.h -like 'Welcome*') { $ice = ([string]$sec.p[0]) -replace '^Icebreaker:\s*', '' }
      if ($sec.art -eq 'read') { $story = $sec }
      if ($sec.h -eq 'Discussion Questions') { $disc = $sec }
    }
    $storyHead = ([string]$story.h) -replace "^This Week.s Story\s*.\s*", ''
    $nu['summary'] = $c.summary
    $nu['keyWords'] = @($c.keywords)
    $secs = @()
    $secs += (Sec 'target' 'Your learning goals' (@('By the end of this unit you will be able to:') + (Bul $c.goals)))
    $secs += (Sec 'talk' 'Warm-up (5 min)' @($ice))
    $secs += (Sec 'read' ('True story: ' + $storyHead) $story.p)
    $secs += (Sec 'listen' 'Think about it' $disc.p)
    $ia = 'science'; if ($ideaArt.ContainsKey($n)) { $ia = $ideaArt[$n] }
    $secs += (Sec $ia 'The big idea' $c.idea @{ t = 'In one line'; b = @($c.oneLine) })
    $secs += (Sec 'steps' ('The method: ' + $c.methodName) (Numbered $c.steps))
    $secs += (Sec 'scale' 'See it in action' @(('The situation: ' + $c.scenarioSetup), ('How it often goes wrong: ' + $c.scenarioWrong)) @{ t = 'A better approach'; b = $c.scenarioBetter })
    $secs += (Sec 'search' 'Common mistakes and quick fixes' $c.mistakes)
    $secs += (Sec 'build' 'Practice lab (about 30 min)' $c.lab)
    $secs += (Sec 'identity' 'Reflect in your journal' $c.reflect)
    $secs += (Sec 'achieve' 'Key takeaways and self-rating' ((Bul $c.takeaways) + @('Self-rating (1 to 5): How confident do I feel using this skill right now, and what is one thing that would raise my score by a point?')))
    $nu['sections'] = $secs
    $nu['activity'] = "This week's challenge: " + $c.challenge
    $nu['check'] = Shuffle-Check $c.check $n
  }
  $units += $nu
}

$course = [ordered]@{}
foreach ($p in $orig.PSObject.Properties) { if ($p.Name -ne 'units' -and $p.Name -ne 'questions' -and $p.Name -ne 'materials') { $course[$p.Name] = $p.Value } }
$course['tagline'] = $special.course.tagline
$course['months'] = $special.course.months
$course['title'] = 'One-Year Life Skills Academy: Learn. Lead. Impact.'
$course['passMark'] = 0; $course['totalQuestions'] = 0; $course['examMins'] = 0
$course['assessmentType'] = 'project'
$course['capstones'] = @($special.course.capstones | ForEach-Object { [ordered]@{ week = [int]$_.week; title = $_.title; desc = $_.desc; rubric = @($_.rubric); awards = @($_.awards) } })
$course['materials'] = [ordered]@{}
$course['units'] = $units
$course['questions'] = @()

$json = $course | ConvertTo-Json -Depth 30 -Compress
# escape every non-ASCII char so the file is pure ASCII (safe to embed byte-for-byte in the bundle)
$sb = New-Object Text.StringBuilder
foreach ($ch in $json.ToCharArray()) { if ([int]$ch -gt 126) { [void]$sb.Append(('\u{0:x4}' -f [int]$ch)) } else { [void]$sb.Append($ch) } }
$outFile = Join-Path (Split-Path -Parent $here) 'lifey1_v2.json'
[IO.File]::WriteAllText($outFile, $sb.ToString(), (New-Object Text.UTF8Encoding($false)))

$words = 0; foreach ($u in $units) { foreach ($s in $u.sections) { foreach ($p in $s.p) { $words += ($p -split '\s+').Count } } }
"units: $($units.Count); body words (incl. stories): $words; checks: $((($units | ForEach-Object { $_.check.Count }) | Measure-Object -Sum).Sum); file bytes: $((Get-Item $outFile).Length)"
