# Draws the three teaching diagrams used in the 0510 Week 4 and Week 5 units into .\img
# powershell -ExecutionPolicy Bypass -File make_images.ps1
Add-Type -AssemblyName System.Drawing
$out = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'img'
New-Item -ItemType Directory $out -Force | Out-Null
function Hex($h) { [Drawing.ColorTranslator]::FromHtml($h) }
function Fnt($size, $bold) { $st = [Drawing.FontStyle]::Regular; if ($bold) { $st = [Drawing.FontStyle]::Bold }; [Drawing.Font]::new('Segoe UI', [single]$size, $st) }
function NewCanvas($w, $h) { $b = New-Object Drawing.Bitmap $w, $h; $g = [Drawing.Graphics]::FromImage($b); $g.SmoothingMode = 'AntiAlias'; $g.TextRenderingHint = 'AntiAlias'; $g.Clear([Drawing.Color]::White); return @($b, $g) }
function Box($g, $x, $y, $w, $h, $hex, $title, $sub, $fs) {
  $br = New-Object Drawing.SolidBrush (Hex $hex)
  $path = New-Object Drawing.Drawing2D.GraphicsPath; $r = 18
  $path.AddArc($x, $y, $r, $r, 180, 90); $path.AddArc($x + $w - $r, $y, $r, $r, 270, 90); $path.AddArc($x + $w - $r, $y + $h - $r, $r, $r, 0, 90); $path.AddArc($x, $y + $h - $r, $r, $r, 90, 90); $path.CloseFigure()
  $g.FillPath($br, $path)
  $f = Fnt $fs $true; $f2 = Fnt ([Math]::Max(10, [int]($fs * 0.6))) $false; $wb = [Drawing.Brushes]::White
  $sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'; $sf.LineAlignment = 'Center'
  $r1 = New-Object Drawing.RectangleF($x, ($y + $h * 0.06), $w, ($h * 0.40)); $r2 = New-Object Drawing.RectangleF(($x + 8), ($y + $h * 0.46), ($w - 16), ($h * 0.50))
  $g.DrawString($title, $f, $wb, $r1, $sf); if ($sub) { $g.DrawString($sub, $f2, $wb, $r2, $sf) }
}
function Arrow($g, $x1, $y1, $x2, $y2) { $p = New-Object Drawing.Pen (Hex '#475569'), 5; $p.EndCap = 'ArrowAnchor'; $g.DrawLine($p, $x1, $y1, $x2, $y2) }
function Caption($g, $text, $w, $y) { $sf = New-Object Drawing.StringFormat; $sf.Alignment = 'Center'; $g.DrawString($text, (Fnt 22 $true), (New-Object Drawing.SolidBrush (Hex '#1e293b')), (New-Object Drawing.RectangleF(0, $y, $w, 44)), $sf) }

# 1. lesson timeline
$c = NewCanvas 1400 420; $b = $c[0]; $g = $c[1]
Caption $g 'A 55 minute lesson: shape and timing' 1400 16
$items = @(@('Starter', '6 min', '#0ea5e9', 6), @('Input', '12 min', '#2158e8', 12), @('Guided practice', '12 min', '#7c3aed', 12), @('Free production', '15 min', '#059669', 15), @('Plenary', '8 min', '#d97706', 8), @('Close', '1-2', '#dc2626', 2))
$minW = 90; $total = 1320
$w = @(); foreach ($i in $items) { $w += [Math]::Max($minW, $total * $i[3] / 55) }
$sum = ($w | Measure-Object -Sum).Sum; $x = 40
for ($k = 0; $k -lt $items.Count; $k++) {
  $i = $items[$k]; $bw = [int]($w[$k] * $total / $sum); $fs = 22; if ($bw -lt 200) { $fs = 15 }; if ($bw -lt 130) { $fs = 12 }
  Box $g $x 90 ($bw - 6) 190 $i[2] $i[0] $i[1] $fs; $x += $bw
}
$g.DrawString('Starter: wake up the class. Input: meet the language. Guided practice: use it with support. Free production: use it alone. Plenary: check the objective.', (Fnt 17 $false), (New-Object Drawing.SolidBrush (Hex '#334155')), (New-Object Drawing.RectangleF(40, 310, 1320, 80)))
$b.Save("$out\0510-lesson-timeline.png", [Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()

# 2. skills chain
$c = NewCanvas 1400 380; $b = $c[0]; $g = $c[1]
Caption $g 'The skills chain: from input to output' 1400 14
$steps = @(@('1 Input', 'read or listen for meaning', '#2158e8'), @('2 Noticing', 'look at the language', '#7c3aed'), @('3 Practice', 'controlled tasks', '#0ea5e9'), @('4 Output', 'speak or write', '#059669'), @('5 Feedback', 'improve and redo', '#d97706'))
$x = 30
foreach ($s in $steps) { Box $g $x 80 230 170 $s[2] $s[0] $s[1] 24; if ($s[0] -notlike '5*') { Arrow $g ($x + 232) 165 ($x + 266) 165 }; $x += 268 }
$p = New-Object Drawing.Pen (Hex '#d97706'), 4; $p.DashStyle = 'Dash'; $g.DrawArc($p, 300, 215, 800, 110, 0, 180)
$g.DrawString('Feedback leads to a new try', (Fnt 16 $false), (New-Object Drawing.SolidBrush (Hex '#b45309')), 560, 322)
$b.Save("$out\0510-skills-chain.png", [Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()

# 3. TBL framework
$c = NewCanvas 1400 520; $b = $c[0]; $g = $c[1]
Caption $g 'Willis task-based learning framework' 1400 14
Box $g 40 80 300 360 '#2158e8' 'PRE-TASK' 'Introduce the topic and the task. Brainstorm words. Hear a model.' 28
Arrow $g 346 260 400 260
Box $g 405 80 590 70 '#0b7a5a' 'TASK CYCLE' '' 28
Box $g 405 165 180 275 '#059669' 'Task' 'Pairs or groups do the task. The teacher monitors.' 26
Box $g 600 165 180 275 '#10b981' 'Planning' 'Prepare to report. Ask for language help.' 24
Box $g 795 165 200 275 '#34d399' 'Report' 'Tell or show the class. Compare results.' 26
Arrow $g 1001 260 1055 260
Box $g 1060 80 300 360 '#7c3aed' 'LANGUAGE FOCUS' 'Look at useful language. Practise words and patterns.' 26
$g.DrawString('Students use language first. Then they study it.', (Fnt 17 $false), (New-Object Drawing.SolidBrush (Hex '#334155')), 40, 462)
$b.Save("$out\0510-tbl-framework.png", [Drawing.Imaging.ImageFormat]::Png); $g.Dispose(); $b.Dispose()
Get-ChildItem $out | Select-Object Name, Length
