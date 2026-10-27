# Builds patches\ng_content\img\ for the Nigerian-curriculum notes:
#  - copies the clean pictures taken from the teachers' PDFs (renamed, cropped where a third-party mark sat in a corner)
#  - draws the replacement figures (graphs and diagrams that had a stock-photo watermark or a wrong curve)
#   powershell -ExecutionPolicy Bypass -File make_figures.ps1 -Src C:\Users\PC\AppData\Local\Temp\ng
param([string]$Src = 'C:\Users\PC\AppData\Local\Temp\ng')
Add-Type -AssemblyName System.Drawing
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$out = Join-Path $here 'img'
New-Item -ItemType Directory -Force $out | Out-Null

# ---------- 1. copy / crop ----------
function CopyImg($subject, $id, $name, $crop) {
  $f = Join-Path $Src "$subject\img\img_$id.jpg"
  if (-not (Test-Path $f)) { throw "missing $f" }
  $dest = Join-Path $out $name
  if (-not $crop) { Copy-Item $f $dest -Force; return }
  $im = [Drawing.Image]::FromFile($f)
  $rect = New-Object Drawing.Rectangle $crop[0], $crop[1], $crop[2], $crop[3]
  $bmp = New-Object Drawing.Bitmap $rect.Width, $rect.Height
  $g = [Drawing.Graphics]::FromImage($bmp); $g.DrawImage($im, (New-Object Drawing.Rectangle 0, 0, $rect.Width, $rect.Height), $rect, [Drawing.GraphicsUnit]::Pixel); $g.Dispose()
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object Drawing.Imaging.EncoderParameters 1; $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 92L
  $bmp.Save($dest, $enc, $ep); $bmp.Dispose(); $im.Dispose()
}
$map = @(
  @('phys', 84, 'phy-instruments.jpg', $null), @('phys', 162, 'phy-vector-representation.jpg', $null), @('phys', 168, 'phy-vector-boat.jpg', $null),
  @('phys', 175, 'phy-vector-school.jpg', $null), @('phys', 202, 'phy-speed-variable.jpg', $null), @('phys', 203, 'phy-speed-uniform.jpg', $null),
  @('phys', 212, 'phy-disp-time.jpg', $null), @('phys', 213, 'phy-vt-trapezoid.jpg', $null), @('phys', 245, 'phy-vt-example2.jpg', $null),
  @('phys', 333, 'phy-force-100-60.jpg', $null), @('phys', 342, 'phy-force-resolved.jpg', $null), @('phys', 411, 'phy-pulley-4.jpg', $null),
  @('phys', 424, 'phy-inclined-plane.jpg', $null), @('phys', 448, 'phy-pulley-6.jpg', $null), @('phys', 503, 'phy-thermo-x.jpg', $null),
  @('phys', 511, 'phy-thermo-70.jpg', $null), @('phys', 579, 'phy-states-of-matter.jpg', @(0, 0, 1142, 880)), @('phys', 614, 'phy-fluids-overview.jpg', @(0, 0, 512, 458)),
  @('phys', 689, 'phy-pressure-cylinder.jpg', $null), @('phys', 690, 'phy-j-tube.jpg', $null), @('phys', 713, 'phy-gas-tube-b-high.jpg', $null),
  @('phys', 714, 'phy-gas-tube-b-low.jpg', $null), @('phys', 764, 'phy-pendulum-energy.jpg', $null), @('phys', 806, 'phy-projectile.jpg', $null),
  @('phys', 827, 'phy-projectile-height.jpg', $null), @('phys', 845, 'phy-wave-parts.jpg', $null), @('phys', 876, 'phy-wave-types.jpg', $null),
  @('phys', 889, 'phy-polarisation.jpg', $null), @('phys', 903, 'phy-wave-distance.jpg', $null),
  @('eng', 114, 'eng-family-tree.jpg', $null)
)
foreach ($m in $map) { CopyImg $m[0] $m[1] $m[2] $m[3] }
"copied $($map.Count) pictures"

# ---------- 2. drawing helpers ----------
$ink = [Drawing.Color]::FromArgb(31, 41, 55); $blue = [Drawing.Color]::FromArgb(24, 66, 168); $orange = [Drawing.Color]::FromArgb(217, 119, 6); $green = [Drawing.Color]::FromArgb(5, 150, 105); $grey = [Drawing.Color]::FromArgb(148, 163, 184)
function Canvas($w, $h) { $script:bmp = New-Object Drawing.Bitmap $w, $h; $script:g = [Drawing.Graphics]::FromImage($script:bmp); $script:g.SmoothingMode = 'AntiAlias'; $script:g.TextRenderingHint = 'AntiAliasGridFit'; $script:g.Clear([Drawing.Color]::White) }
function Save($name) { $script:g.Dispose(); $script:bmp.Save((Join-Path $out $name), [Drawing.Imaging.ImageFormat]::Png); $script:bmp.Dispose() }
function PenOf($c, $w) { New-Object Drawing.Pen $c, $w }
function Arrow($c, $w, $x1, $y1, $x2, $y2) { $p = PenOf $c $w; $p.CustomEndCap = New-Object Drawing.Drawing2D.AdjustableArrowCap 5, 6; $script:g.DrawLine($p, [single]$x1, [single]$y1, [single]$x2, [single]$y2); $p.Dispose() }
function Line($c, $w, $x1, $y1, $x2, $y2, $dash) { $p = PenOf $c $w; if ($dash) { $p.DashStyle = 'Dash' }; $script:g.DrawLine($p, [single]$x1, [single]$y1, [single]$x2, [single]$y2); $p.Dispose() }
function Txt($s, $x, $y, $size, $color, $bold) { $st = [Drawing.FontStyle]::Regular; if ($bold) { $st = [Drawing.FontStyle]::Bold }; $f = New-Object Drawing.Font 'Segoe UI', ([single]$size), $st, ([Drawing.GraphicsUnit]::Pixel); $b = New-Object Drawing.SolidBrush $color; $script:g.DrawString($s, $f, $b, [single]$x, [single]$y); $f.Dispose(); $b.Dispose() }
function TxtC($s, $cx, $y, $size, $color, $bold) { $st = [Drawing.FontStyle]::Regular; if ($bold) { $st = [Drawing.FontStyle]::Bold }; $f = New-Object Drawing.Font 'Segoe UI', ([single]$size), $st, ([Drawing.GraphicsUnit]::Pixel); $w = $script:g.MeasureString($s, $f).Width; $b = New-Object Drawing.SolidBrush $color; $script:g.DrawString($s, $f, $b, [single]($cx - $w / 2), [single]$y); $f.Dispose(); $b.Dispose() }
function TxtV($s, $x, $cy, $size, $color) { $f = New-Object Drawing.Font 'Segoe UI', ([single]$size), ([Drawing.FontStyle]::Regular), ([Drawing.GraphicsUnit]::Pixel); $w = $script:g.MeasureString($s, $f).Width; $st = $script:g.Save(); $script:g.TranslateTransform([single]$x, [single]$cy); $script:g.RotateTransform(-90); $b = New-Object Drawing.SolidBrush $color; $script:g.DrawString($s, $f, $b, [single](-$w / 2), 0); $script:g.Restore($st); $f.Dispose(); $b.Dispose() }
function Curve($c, $w, $pts) { $p = PenOf $c $w; $a = @(); foreach ($q in $pts) { $a += New-Object Drawing.PointF ([single]$q[0]), ([single]$q[1]) }; $script:g.DrawCurve($p, [Drawing.PointF[]]$a, 0.5); $p.Dispose() }
function Axes($ox, $oy, $len, $hgt, $xl, $yl) { Arrow $ink 2.5 $ox $oy ($ox + $len) $oy; Arrow $ink 2.5 $ox $oy $ox ($oy - $hgt); TxtC $xl ($ox + $len / 2) ($oy + 10) 22 $ink $false; TxtV $yl ($ox - 30) ($oy - $hgt / 2) 22 $ink }
function Fill($c, $pts) { $a = @(); foreach ($q in $pts) { $a += New-Object Drawing.PointF ([single]$q[0]), ([single]$q[1]) }; $b = New-Object Drawing.SolidBrush $c; $script:g.FillPolygon($b, [Drawing.PointF[]]$a); $b.Dispose() }

# ---------- 3. position-time graphs ----------
Canvas 1200 450
foreach ($k in 0..2) {
  $ox = 80 + $k * 385; $oy = 340
  Axes $ox $oy 300 280 'Time' 'Distance'
}
Line $blue 3.5 80 220 360 220 $false; TxtC 'Stationary object' 220 14 26 $ink $true
Line $blue 3.5 465 340 735 90 $false; TxtC 'Uniform speed' 600 14 26 $ink $true
Curve $blue 3.5 @(@(850, 340), @(910, 330), @(970, 305), @(1030, 250), @(1080, 180), @(1115, 90)); TxtC 'Non-uniform speed' 990 14 26 $ink $true
Txt 'Flat line: no change' 120 395 21 $ink $false
Txt 'Straight slope: steady speed' 450 395 21 $ink $false
Txt 'Curve: speed changing' 850 395 21 $ink $false
Save 'phy-pos-time-graphs.png'

# ---------- 4. velocity-time graph, worked example 1 ----------
Canvas 900 560
$ox = 120; $oy = 470; $sx = 11.5; $sy = 13.2
function PX($t) { $script:ox + $t * $script:sx }; function PY($v) { $script:oy - $v * $script:sy }
Fill ([Drawing.Color]::FromArgb(219, 234, 254)) @(@((PX 0), (PY 0)), @((PX 20), (PY 0)), @((PX 20), (PY 25)))
Fill ([Drawing.Color]::FromArgb(209, 250, 229)) @(@((PX 20), (PY 0)), @((PX 50), (PY 0)), @((PX 50), (PY 25)), @((PX 20), (PY 25)))
Fill ([Drawing.Color]::FromArgb(254, 243, 199)) @(@((PX 50), (PY 0)), @((PX 60), (PY 0)), @((PX 50), (PY 25)))
Axes $ox $oy 740 400 't (s)' 'v (m/s)'
Line $grey 1.5 (PX 0) (PY 25) (PX 20) (PY 25) $true; Line $grey 1.5 (PX 20) (PY 0) (PX 20) (PY 25) $true; Line $grey 1.5 (PX 50) (PY 0) (PX 50) (PY 25) $true
$pl = PenOf $blue 4; $script:g.DrawLines($pl, [Drawing.PointF[]]@((New-Object Drawing.PointF ([single](PX 0)), ([single](PY 0))), (New-Object Drawing.PointF ([single](PX 20)), ([single](PY 25))), (New-Object Drawing.PointF ([single](PX 50)), ([single](PY 25))), (New-Object Drawing.PointF ([single](PX 60)), ([single](PY 0))))); $pl.Dispose()
foreach ($t in 0, 20, 50, 60) { TxtC "$t" (PX $t) ($oy + 8) 20 $ink $false }
TxtC '25' ($ox - 22) ((PY 25) - 12) 20 $ink $false
TxtC 'A = 250 m' (PX 14) (PY 7) 20 $ink $true
TxtC 'A = 750 m' (PX 35) (PY 12) 22 $ink $true
TxtC 'A = 125 m' (PX 54) (PY 5) 18 $ink $true
TxtC 'Total distance = 250 + 750 + 125 = 1125 m' 470 22 20 $blue $true
Save 'phy-vt-example1.png'

# ---------- 5. types of motion ----------
Canvas 1200 640
TxtC 'Types of motion' 600 12 32 $ink $true
$bx = @(20, 410, 800); $by = @(66, 350); $pw = 380; $ph = 270
$k = 0
foreach ($r in 0..1) { foreach ($c in 0..2) { if ($k -lt 5) { $p = PenOf $grey 2; $script:g.DrawRectangle($p, [single]$bx[$c], [single]$by[$r], [single]$pw, [single]$ph); $p.Dispose() }; $k++ } }
function Cap($title, $sub, $cx, $y) { TxtC $title $cx $y 26 $ink $true; TxtC $sub $cx ($y + 30) 21 $ink $false }
# linear
$cx = $bx[0]; $cy = $by[0]
$b = New-Object Drawing.SolidBrush $blue; $script:g.FillRectangle($b, [single]($cx + 60), [single]($cy + 60), 90, 50); $b.Dispose()
$b = New-Object Drawing.SolidBrush $ink; $script:g.FillEllipse($b, [single]($cx + 75), [single]($cy + 102), 22, 22); $script:g.FillEllipse($b, [single]($cx + 115), [single]($cy + 102), 22, 22); $b.Dispose()
Arrow $orange 4 ($cx + 165) ($cy + 85) ($cx + 330) ($cy + 85); Cap 'Linear motion' '(a car on a straight road)' ($cx + 190) ($cy + 190)
# curvilinear
$cx = $bx[1]; $cy = $by[0]
Curve $blue 3 @(@(($cx + 40), ($cy + 170)), @(($cx + 110), ($cy + 70)), @(($cx + 190), ($cy + 40)), @(($cx + 270), ($cy + 70)), @(($cx + 340), ($cy + 170)))
$b = New-Object Drawing.SolidBrush $orange; $script:g.FillEllipse($b, [single]($cx + 180), [single]($cy + 30), 22, 22); $b.Dispose()
Cap 'Curvilinear motion' '(a kicked ball)' ($cx + 190) ($cy + 190)
# circular
$cx = $bx[2]; $cy = $by[0]
$p = PenOf $blue 3; $script:g.DrawEllipse($p, [single]($cx + 120), [single]($cy + 20), 140, 140); $p.Dispose()
$b = New-Object Drawing.SolidBrush $orange; $script:g.FillEllipse($b, [single]($cx + 249), [single]($cy + 79), 22, 22); $b.Dispose()
Arrow $green 3 ($cx + 260) ($cy + 90) ($cx + 260) ($cy + 40)
Cap 'Circular motion' '(a stone on a string)' ($cx + 190) ($cy + 190)
# rotational (fan)
$cx = $bx[0] + 190; $cy = $by[1] + 100
$b = New-Object Drawing.SolidBrush $blue
foreach ($a in 0, 120, 240) { $st = $script:g.Save(); $script:g.TranslateTransform([single]$cx, [single]$cy); $script:g.RotateTransform([single]$a); $script:g.FillEllipse($b, -14, -75, 28, 75); $script:g.Restore($st) }
$b.Dispose(); $b = New-Object Drawing.SolidBrush $ink; $script:g.FillEllipse($b, [single]($cx - 12), [single]($cy - 12), 24, 24); $b.Dispose()
$p = PenOf $orange 3; $script:g.DrawArc($p, [single]($cx - 90), [single]($cy - 90), 180, 180, 200, 120); $p.Dispose()
Cap 'Rotational motion' '(a ceiling fan)' $cx ($by[1] + 190)
# oscillatory (pendulum)
$cx = $bx[1] + 190; $cy = $by[1]
$b = New-Object Drawing.SolidBrush $ink; $script:g.FillRectangle($b, [single]($cx - 60), [single]($cy + 8), 120, 10); $b.Dispose()
Line $ink 2 $cx ($cy + 18) $cx ($cy + 150) $false
Line $grey 2 $cx ($cy + 18) ($cx - 75) ($cy + 135) $true; Line $grey 2 $cx ($cy + 18) ($cx + 75) ($cy + 135) $true
$b = New-Object Drawing.SolidBrush $orange; $script:g.FillEllipse($b, [single]($cx - 14), [single]($cy + 148), 28, 28); $b.Dispose()
$p = PenOf $green 3; $script:g.DrawArc($p, [single]($cx - 95), [single]($cy + 50), 190, 130, 40, 100); $p.Dispose()
Cap 'Oscillatory motion' '(a pendulum)' $cx ($by[1] + 190)
Save 'phy-types-of-motion.png'
# ---------- 6. vector triangle ----------
Canvas 800 440
Arrow $blue 4 90 340 400 340; Arrow $orange 4 400 340 600 140; Arrow $green 5 90 340 600 140
Line $grey 2 400 340 540 340 $true
$p = PenOf $grey 2; $script:g.DrawArc($p, 365, 305, 70, 70, 315, 45); $p.Dispose()
TxtC 'A' 245 352 28 $blue $true; TxtC 'B' 525 225 28 $orange $true; TxtC 'R = A + B' 185 232 26 $green $true
Txt ([string][char]0x03B8) 438 308 26 $ink $true
Txt 'Draw A, then draw B from the head of A.' 90 15 18 $ink $false
Txt 'The resultant R joins the start of A to the end of B.' 90 42 18 $ink $false
Save 'phy-vector-triangle.png'

# ---------- 7. Boyle's law graphs ----------
Canvas 1000 440
Axes 90 360 340 300 'Volume V' 'Pressure P'
$pts = @(); foreach ($v in 0.5, 0.7, 1, 1.4, 2, 2.8, 4) { $pts += ,@((90 + $v * 75), (360 - (4 / $v) * 32)) }; Curve $blue 3.5 $pts
TxtC 'P against V: a curve (hyperbola)' 260 14 22 $ink $true
Axes 560 360 340 300 '1 / Volume' 'Pressure P'
Line $blue 3.5 560 360 880 100 $false
TxtC 'P against 1/V: a straight line' 730 14 22 $ink $true
Save 'phy-boyle-graphs.png'

# ---------- 8. refraction ----------
Canvas 760 520
$b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(224, 242, 254)); $script:g.FillRectangle($b, 0, 260, 760, 260); $b.Dispose()
Line $ink 2.5 0 260 760 260 $false
Line $grey 2 380 60 380 480 $true
Arrow $orange 4 180 60 380 260; Arrow $blue 4 380 260 580 60; Arrow $green 4 380 260 476 440
TxtC 'Normal' 380 36 17 $ink $false; Txt 'Air' 20 220 22 $ink $true; Txt 'Glass' 20 275 22 $ink $true
Txt 'Incident ray' 120 40 17 $orange $true; Txt 'Reflected ray' 560 40 17 $blue $true; Txt 'Refracted ray' 490 420 17 $green $true
$p = PenOf $orange 2; $script:g.DrawArc($p, 330, 210, 100, 100, 225, 45); $p.Dispose(); Txt 'i' 356 212 22 $orange $true
$p = PenOf $green 2; $script:g.DrawArc($p, 340, 220, 80, 80, 62, 28); $p.Dispose(); Txt 'r' 388 290 22 $green $true
Txt 'The ray bends towards the normal in glass (i is larger than r).' 120 485 17 $ink $false
Save 'phy-refraction.png'
# ---------- 9. plot arc of a story ----------
Canvas 1000 470
Arrow $ink 2.5 60 400 960 400
Txt 'Time' 900 405 20 $ink $false
$pl = PenOf $blue 5
$script:g.DrawCurve($pl, [Drawing.PointF[]]@((New-Object Drawing.PointF 70, 340), (New-Object Drawing.PointF 200, 335), (New-Object Drawing.PointF 360, 250), (New-Object Drawing.PointF 500, 90), (New-Object Drawing.PointF 640, 230), (New-Object Drawing.PointF 790, 320), (New-Object Drawing.PointF 930, 335)), 0.5); $pl.Dispose()
$b = New-Object Drawing.SolidBrush $orange; $script:g.FillEllipse($b, 488, 78, 24, 24); $b.Dispose()
TxtC 'CLIMAX' 500 14 24 $orange $true; TxtC '(the turning point)' 500 42 18 $ink $false
TxtC '1. Introduction' 140 285 22 $ink $true; TxtC 'characters and setting' 140 313 18 $ink $false
TxtC '2. Rising action' 250 150 22 $ink $true; TxtC 'the problem grows' 250 178 18 $ink $false
TxtC '4. Falling action' 770 140 22 $ink $true; TxtC 'results of the climax' 770 168 18 $ink $false
TxtC '5. Resolution' 870 245 22 $ink $true; TxtC 'the story ends' 870 273 18 $ink $false
TxtC '3. Climax' 500 420 22 $ink $true
Save 'eng-plot-arc.png'
# ---------- 10. maths: log graphs and the quadratic graph ----------
function GridXY($ox, $oy, $u, $x0, $x1, $y0, $y1) {
  for ($i = [int][math]::Ceiling($x0); $i -le [int][math]::Floor($x1); $i++) { Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 ($ox + $i * $u) ($oy - $y1 * $u) ($ox + $i * $u) ($oy - $y0 * $u) $false }
  for ($j = [int][math]::Ceiling($y0); $j -le [int][math]::Floor($y1); $j++) { Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 ($ox + $x0 * $u) ($oy - $j * $u) ($ox + $x1 * $u) ($oy - $j * $u) $false }
  Arrow $ink 2.5 ($ox + $x0 * $u) $oy ($ox + $x1 * $u + 10) $oy; Arrow $ink 2.5 $ox ($oy - $y0 * $u) $ox ($oy - $y1 * $u - 10)
  for ($i = [int][math]::Ceiling($x0); $i -le [int][math]::Floor($x1); $i++) { if ($i -ne 0) { TxtC "$i" ($ox + $i * $u) ($oy + 6) 18 $ink $false } }
  for ($j = [int][math]::Ceiling($y0); $j -le [int][math]::Floor($y1); $j++) { if ($j -ne 0) { Txt "$j" ($ox - 30) ($oy - $j * $u - 11) 18 $ink $false } }
}
Canvas 760 700
$u = 90; $ox = 260; $oy = 440
GridXY $ox $oy $u (-2) 4 (-2) 4
Line $grey 2 ($ox - 2 * $u) ($oy + 2 * $u) ($ox + 4 * $u) ($oy - 4 * $u) $true
$pts = @(); for ($x = -2.0; $x -le 0.62; $x += 0.1) { $pts += ,@(($ox + $x * $u), ($oy - [math]::Pow(10, $x) * $u)) }; Curve $blue 4 $pts
$pts = @(); foreach ($x in 0.012, 0.03, 0.06, 0.12, 0.25, 0.5, 1, 2, 3, 4) { $pts += ,@(($ox + $x * $u), ($oy - [math]::Log10($x) * $u)) }; Curve $orange 4 $pts
TxtC 'y = 10^x' ($ox - 0.9 * $u) ($oy - 3.6 * $u) 22 $blue $true
TxtC 'y = log10 x' ($ox + 3.2 * $u) ($oy - 1.1 * $u) 22 $orange $true
Txt 'y = x' ($ox + 3.3 * $u) ($oy - 3.9 * $u) 20 $grey $true
$b = New-Object Drawing.SolidBrush $ink; foreach ($pt in @(@(0, 1), @(1, 0))) { $script:g.FillEllipse($b, [single]($ox + $pt[0] * $u - 6), [single]($oy - $pt[1] * $u - 6), 12, 12) }; $b.Dispose()
Txt '(0, 1)' ($ox + 8) ($oy - 1 * $u - 28) 18 $ink $true; Txt '(1, 0)' ($ox + 1 * $u + 6) ($oy + 10) 18 $ink $true
Save 'mth-log-graphs.png'

Canvas 800 640
$u = 80; $ox = 280; $oy = 370; $uy = 50
for ($i = -2; $i -le 4; $i++) { Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 ($ox + $i * $u) ($oy - 6 * $uy) ($ox + $i * $u) ($oy + 5 * $uy) $false }
for ($j = -5; $j -le 6; $j++) { Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 ($ox - 2 * $u) ($oy - $j * $uy) ($ox + 4 * $u) ($oy - $j * $uy) $false }
Arrow $ink 2.5 ($ox - 2 * $u - 10) $oy ($ox + 4 * $u + 20) $oy; Arrow $ink 2.5 $ox ($oy + 5 * $uy + 10) $ox ($oy - 6 * $uy - 20)
for ($i = -2; $i -le 4; $i++) { if ($i -ne 0) { TxtC "$i" ($ox + $i * $u) ($oy + 6) 18 $ink $false } }
for ($j = -5; $j -le 6; $j++) { if ($j -ne 0) { Txt "$j" ($ox - 32) ($oy - $j * $uy - 11) 18 $ink $false } }
Txt 'x' ($ox + 4 * $u + 26) ($oy - 10) 22 $ink $true; Txt 'y' ($ox + 10) ($oy - 6 * $uy - 30) 22 $ink $true
Line $grey 2 ($ox + 1 * $u) ($oy - 6 * $uy) ($ox + 1 * $u) ($oy + 5 * $uy) $true
Txt 'axis of symmetry: x = 1' ($ox + 1 * $u + 8) ($oy - 5.5 * $uy) 18 $ink $false
$pts = @(); for ($x = -2.0; $x -le 4.01; $x += 0.25) { $pts += ,@(($ox + $x * $u), ($oy - ($x * $x - 2 * $x - 3) * $uy)) }; Curve $blue 4 $pts
$b = New-Object Drawing.SolidBrush $orange
foreach ($pt in @(@(-2, 5), @(-1, 0), @(0, -3), @(1, -4), @(2, -3), @(3, 0), @(4, 5))) { $script:g.FillEllipse($b, [single]($ox + $pt[0] * $u - 7), [single]($oy - $pt[1] * $uy - 7), 14, 14) }
$b.Dispose()
Txt 'vertex (1, -4)' ($ox + 1 * $u + 12) ($oy + 4 * $uy - 8) 20 $ink $true
Txt 'root (-1, 0)' ($ox - 1 * $u - 118) ($oy - 36) 20 $ink $true
Txt 'root (3, 0)' ($ox + 3 * $u - 30) ($oy + 30) 20 $ink $true
Txt 'y-intercept (0, -3)' ($ox - 190) ($oy + 3 * $uy - 10) 20 $ink $true
TxtC 'y = x^2 - 2x - 3' ($ox - 1.0 * $u) ($oy - 5.9 * $uy) 22 $blue $true
Save 'mth-quadratic-graph.png'
# ---------- 11. maths: constructions and loci ----------
function ArcS($c, $w, $cx, $cy, $r, $a1, $a2, $dash) { $pn = PenOf $c $w; if ($dash) { $pn.DashStyle = 'Dash' }; $script:g.DrawArc($pn, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](-$a2), [single]($a2 - $a1)); $pn.Dispose() }
function Dot($c, $x, $y, $r) { $b = New-Object Drawing.SolidBrush $c; $script:g.FillEllipse($b, [single]($x - $r), [single]($y - $r), [single](2 * $r), [single](2 * $r)); $b.Dispose() }
function AngOf($cx, $cy, $x, $y) { [math]::Atan2(-($y - $cy), ($x - $cx)) * 180 / [math]::PI }
$light = [Drawing.Color]::FromArgb(100, 116, 139)

# angle bisector
Canvas 720 540
$bx = 120; $by = 420; $c70 = [math]::Cos(70 * [math]::PI / 180); $s70 = [math]::Sin(70 * [math]::PI / 180); $c35 = [math]::Cos(35 * [math]::PI / 180); $s35 = [math]::Sin(35 * [math]::PI / 180)
Line $ink 3 $bx $by 600 $by $false; Line $ink 3 $bx $by ($bx + 400 * $c70) ($by - 400 * $s70) $false
$px = $bx + 150 * $c70; $py = $by - 150 * $s70; $qx = $bx + 150; $qy = $by
$d = 150 * $c35 + [math]::Sqrt(125 * 125 - [math]::Pow(150 * $s35, 2)); $rx = $bx + $d * $c35; $ry = $by - $d * $s35
ArcS $light 2 $bx $by 150 0 70 $false
$aq = AngOf $qx $qy $rx $ry; ArcS $blue 2.5 $qx $qy 125 ($aq - 22) ($aq + 22) $false
$ap = AngOf $px $py $rx $ry; ArcS $orange 2.5 $px $py 125 ($ap - 22) ($ap + 22) $false
Line $green 4 $bx $by ($bx + 330 * $c35) ($by - 330 * $s35) $false
foreach ($pt in @(@($bx, $by), @($px, $py), @($qx, $qy), @($rx, $ry))) { Dot $ink $pt[0] $pt[1] 6 }
Txt 'B' ($bx - 30) ($by + 4) 26 $ink $true; Txt 'C' 600 ($by + 6) 26 $ink $true; Txt 'A' ($bx + 400 * $c70 - 10) ($by - 400 * $s70 - 36) 26 $ink $true
Txt 'P' ($px - 34) ($py - 8) 24 $blue $true; Txt 'Q' ($qx + 4) ($qy + 8) 24 $orange $true; Txt 'R' ($rx + 8) ($ry - 30) 24 $green $true
Txt 'bisector' ($bx + 330 * $c35 + 8) ($by - 330 * $s35 - 28) 22 $green $true
Txt '1  Arc from B cuts both arms at P and Q.' 30 470 20 $ink $false
Txt '2  Equal arcs from P and Q meet at R.   3  Join B to R.' 30 498 20 $ink $false
Save 'mth-angle-bisector.png'

# 60 degrees
Canvas 720 470
$ppx = 110; $ppy = 390; $qqx = 330; $rrx = 220; $rry = $ppy - 220 * [math]::Sin(60 * [math]::PI / 180)
Line $ink 3 60 $ppy 600 $ppy $false
ArcS $blue 2.5 $ppx $ppy 220 0 78 $false; ArcS $orange 2.5 $qqx $ppy 220 102 180 $false
Line $green 4 $ppx $ppy $rrx $rry $false; Line $light 2 $qqx $ppy $rrx $rry $true
ArcS $ink 2 $ppx $ppy 55 0 60 $false; Txt '60' ($ppx + 62) ($ppy - 44) 22 $ink $true
foreach ($pt in @(@($ppx, $ppy), @($qqx, $ppy), @($rrx, $rry))) { Dot $ink $pt[0] $pt[1] 6 }
Txt 'P' ($ppx - 30) ($ppy + 6) 26 $ink $true; Txt 'Q' ($qqx + 6) ($ppy + 6) 26 $ink $true; Txt 'R' ($rrx - 10) ($rry - 38) 26 $ink $true
Txt 'PQ = PR = QR (the compass radius), so PQR is equilateral' 30 415 20 $ink $false; Txt 'and angle P = 60 degrees.' 30 441 20 $ink $false
Save 'mth-construct-60.png'

# 90 degrees
Canvas 720 570
$py0 = 330; $pcx = 350
Line $ink 3 60 $py0 640 $py0 $false
ArcS $light 2 $pcx $py0 90 0 180 $false
$aZ = AngOf 260 $py0 350 210; $aZ2 = AngOf 440 $py0 350 210
ArcS $blue 2.5 260 $py0 150 ($aZ - 22) ($aZ + 22) $false; ArcS $blue 2.5 260 $py0 150 (-$aZ - 22) (-$aZ + 22) $false
ArcS $orange 2.5 440 $py0 150 ($aZ2 - 22) ($aZ2 + 22) $false; ArcS $orange 2.5 440 $py0 150 (-$aZ2 - 22) (-$aZ2 + 22) $false
Line $green 4 $pcx 190 $pcx 470 $false
$sq = PenOf $ink 2; $script:g.DrawRectangle($sq, $pcx, ($py0 - 26), 26, 26); $sq.Dispose()
foreach ($pt in @(@(260, $py0), @(440, $py0), @($pcx, $py0), @($pcx, 210), @($pcx, 450))) { Dot $ink $pt[0] $pt[1] 6 }
Txt 'X' 238 ($py0 + 8) 24 $blue $true; Txt 'Y' 446 ($py0 + 8) 24 $orange $true; Txt 'P' ($pcx - 28) ($py0 + 8) 24 $ink $true; Txt 'Z' ($pcx + 10) 186 24 $green $true; Txt 'W' ($pcx + 10) 450 24 $green $true
Txt '1  Small arc from P cuts the line at X and Y.' 30 490 20 $ink $false
Txt '2  Larger arcs from X and Y meet at Z (and W).' 30 513 20 $ink $false; Txt '3  Join Z to P: angle ZPY = 90 degrees.' 30 538 20 $ink $false
Save 'mth-construct-90.png'

# the four loci
Canvas 1000 740
$cells = @(@(20, 20), @(520, 20), @(20, 390), @(520, 390)); $cw = 460; $ch = 330
foreach ($cell in $cells) { $pn = PenOf ([Drawing.Color]::FromArgb(203, 213, 225)) 2; $script:g.DrawRectangle($pn, [single]$cell[0], [single]$cell[1], [single]$cw, [single]$ch); $pn.Dispose() }
# (a) circle
$cx = 250; $cy = 165; $pn = PenOf $blue 4; $script:g.DrawEllipse($pn, [single]($cx - 100), [single]($cy - 100), 200, 200); $pn.Dispose(); Dot $ink $cx $cy 6; Txt 'X' ($cx + 8) ($cy - 8) 24 $ink $true; Line $light 2 $cx $cy ($cx + 100) $cy $true; Txt '3 cm' ($cx + 30) ($cy - 28) 20 $ink $false
TxtC '1. Fixed distance from a point: a circle' $cx 340 20 $ink $true
# (b) two points
$cx = 750; Dot $ink ($cx - 110) $cy 6; Dot $ink ($cx + 110) $cy 6; Txt 'A' ($cx - 134) ($cy + 8) 24 $ink $true; Txt 'B' ($cx + 122) ($cy + 8) 24 $ink $true
Line $light 2 ($cx - 110) $cy ($cx + 110) $cy $true; Line $green 4 $cx 50 $cx 295 $false; Dot $orange $cx 90 6; Txt 'P' ($cx + 10) 70 22 $orange $true
TxtC '2. Equidistant from A and B: perpendicular bisector' $cx 340 20 $ink $true
# (c) parallel lines
$cx = 250; $cy2 = 535; Line $ink 3 ($cx - 130) $cy2 ($cx + 130) $cy2 $false; Line $blue 4 ($cx - 130) ($cy2 - 60) ($cx + 130) ($cy2 - 60) $false; Line $blue 4 ($cx - 130) ($cy2 + 60) ($cx + 130) ($cy2 + 60) $false
Txt 'A' ($cx - 160) ($cy2 - 14) 24 $ink $true; Txt 'B' ($cx + 138) ($cy2 - 14) 24 $ink $true; Txt '2 cm' ($cx + 30) ($cy2 - 52) 20 $ink $false; Txt '2 cm' ($cx + 30) ($cy2 + 24) 20 $ink $false
TxtC '3. Fixed distance from a line: two parallel lines' $cx 710 20 $ink $true
# (d) angle bisectors
$cx = 750; $cy3 = 535; $a1 = 15 * [math]::PI / 180; $a2 = 105 * [math]::PI / 180; $bis = 60 * [math]::PI / 180; $bis2 = 150 * [math]::PI / 180
foreach ($an in @($a1, $a2)) { Line $ink 3 ($cx - 150 * [math]::Cos($an)) ($cy3 + 150 * [math]::Sin($an)) ($cx + 150 * [math]::Cos($an)) ($cy3 - 150 * [math]::Sin($an)) $false }
foreach ($an in @($bis, $bis2)) { Line $green 4 ($cx - 150 * [math]::Cos($an)) ($cy3 + 150 * [math]::Sin($an)) ($cx + 150 * [math]::Cos($an)) ($cy3 - 150 * [math]::Sin($an)) $true }
Dot $ink $cx $cy3 6
TxtC '4. Equidistant from two lines: angle bisectors' $cx 710 20 $ink $true
Save 'mth-loci.png'

# the goat problem (1 m = 50 px)
Canvas 800 520
$gp = @(230, 260); $gq = @(480, 260)
$b1 = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(70, 24, 66, 168)); $b2 = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(70, 217, 119, 6))
$script:g.FillEllipse($b1, [single]($gp[0] - 200), [single]($gp[1] - 200), 400, 400); $script:g.FillEllipse($b2, [single]($gq[0] - 150), [single]($gq[1] - 150), 300, 300); $b1.Dispose(); $b2.Dispose()
$pn = PenOf $blue 3; $script:g.DrawEllipse($pn, [single]($gp[0] - 200), [single]($gp[1] - 200), 400, 400); $pn.Dispose(); $pn = PenOf $orange 3; $script:g.DrawEllipse($pn, [single]($gq[0] - 150), [single]($gq[1] - 150), 300, 300); $pn.Dispose()
Line $ink 2 $gp[0] $gp[1] $gq[0] $gq[1] $true; Dot $ink $gp[0] $gp[1] 7; Dot $ink $gq[0] $gq[1] 7
Txt 'P' ($gp[0] - 26) ($gp[1] + 4) 26 $blue $true; Txt 'Q' ($gq[0] + 8) ($gq[1] + 4) 26 $orange $true
TxtC '5 m' (($gp[0] + $gq[0]) / 2) ($gp[1] + 10) 20 $ink $false
TxtC 'Rope from P: 4 m' $gp[0] 14 20 $blue $true; TxtC 'Rope from Q: 3 m' 690 430 20 $orange $true
Arrow $ink 2 400 470 400 $gp[1]
TxtC 'The goat can graze only in the overlap' 400 480 20 $ink $true
Save 'mth-goat.png'
# ---------- 12. maths: geometry proofs and trigonometry ----------
$rt = [string][char]0x221A; $dg = [string][char]0xB0; $th = [string][char]0x03B8
function RadOf($d) { $d * [math]::PI / 180 }
function PolarPt($cx, $cy, $r, $deg) { @(($cx + $r * [math]::Cos((RadOf $deg))), ($cy - $r * [math]::Sin((RadOf $deg)))) }

# triangle angle sum proof
Canvas 760 480
$A = @(330, 150); $B = @(160, 380); $C = @(600, 380)
Line $light 3 80 150 700 150 $true
Line $ink 4 $B[0] $B[1] $C[0] $C[1] $false; Line $ink 4 $B[0] $B[1] $A[0] $A[1] $false; Line $ink 4 $A[0] $A[1] $C[0] $C[1] $false
$ab = [math]::Atan2(230, 170) * 180 / [math]::PI; $ac = [math]::Atan2(230, 270) * 180 / [math]::PI
ArcS $blue 3 $B[0] $B[1] 50 0 $ab $false; Txt 'b' ($B[0] + 58) ($B[1] - 36) 24 $blue $true
ArcS $blue 3 $A[0] $A[1] 50 180 (180 + $ab) $false; Txt 'b' ($A[0] - 70) ($A[1] + 12) 24 $blue $true
ArcS $orange 3 $C[0] $C[1] 50 (180 - $ac) 180 $false; Txt 'c' ($C[0] - 76) ($C[1] - 36) 24 $orange $true
ArcS $orange 3 $A[0] $A[1] 50 (360 - $ac) 360 $false; Txt 'c' ($A[0] + 56) ($A[1] + 8) 24 $orange $true
ArcS $green 3 $A[0] $A[1] 50 (180 + $ab) (360 - $ac) $false; Txt 'a' ($A[0] - 8) ($A[1] + 56) 24 $green $true
Txt 'A' ($A[0] - 10) ($A[1] - 38) 26 $ink $true; Txt 'B' ($B[0] - 30) ($B[1] + 4) 26 $ink $true; Txt 'C' ($C[0] + 8) ($C[1] + 4) 26 $ink $true; Txt 'X' 50 128 24 $light $true; Txt 'Y' 706 128 24 $light $true
Txt "XY is parallel to BC. Along the line XY: b + a + c = 180$dg" 120 430 22 $ink $false
Save 'mth-triangle-proof.png'

# exterior angle
Canvas 760 460
$A = @(300, 130); $B = @(120, 370); $C = @(430, 370); $D = @(680, 370)
Line $ink 4 $B[0] $B[1] $D[0] $D[1] $false; Line $ink 4 $B[0] $B[1] $A[0] $A[1] $false; Line $ink 4 $A[0] $A[1] $C[0] $C[1] $false
$ang = [math]::Atan2(240, ($A[0] - $C[0])) * 180 / [math]::PI; $angB = [math]::Atan2(240, 180) * 180 / [math]::PI
ArcS $orange 4 $C[0] $C[1] 70 0 $ang $false; ArcS $ink 2 $C[0] $C[1] 40 $ang 180 $false
Txt 'exterior angle' ($C[0] + 80) ($C[1] - 70) 22 $orange $true
ArcS $blue 3 $B[0] $B[1] 55 0 $angB $false; Txt 'b' ($B[0] + 62) ($B[1] - 36) 24 $blue $true
Txt 'a' ($A[0] - 8) ($A[1] + 56) 24 $green $true; ArcS $green 3 $A[0] $A[1] 50 (180 + $angB) (360 - (180 - $ang)) $false
Txt 'c' ($C[0] - 50) ($C[1] - 40) 22 $ink $true
Txt 'A' ($A[0] - 10) ($A[1] - 38) 26 $ink $true; Txt 'B' ($B[0] - 30) ($B[1] + 4) 26 $ink $true; Txt 'C' ($C[0] - 8) ($C[1] + 10) 26 $ink $true; Txt 'D' ($D[0] + 6) ($D[1] + 4) 26 $ink $true
Txt 'exterior angle ACD = a + b' 220 420 24 $ink $true
Save 'mth-exterior-angle.png'

# Z, F and C patterns
Canvas 1000 390
foreach ($k in 0..2) {
  $x0 = 20 + $k * 330
  $p1 = @(($x0 + 126), 130); $p2 = @(($x0 + 194), 260)
  Line $ink 3 ($x0 + 10) 130 ($x0 + 300) 130 $false; Line $ink 3 ($x0 + 10) 260 ($x0 + 300) 260 $false
  Line $light 3 ($x0 + 90) 60 ($x0 + 230) 330 $false
  $tl = [math]::Atan2(270, 140) * 180 / [math]::PI
  if ($k -eq 0) { ArcS $blue 3 $p1[0] $p1[1] 36 (360 - $tl) 360 $false; ArcS $blue 3 $p2[0] $p2[1] 36 (180 - $tl) 180 $false; Txt 'a' ($p1[0] + 22) ($p1[1] + 6) 22 $blue $true; Txt 'a' ($p2[0] - 44) ($p2[1] - 32) 22 $blue $true; TxtC 'Z: alternate angles are equal' ($x0 + 150) 350 17 $ink $true }
  if ($k -eq 1) { ArcS $blue 3 $p1[0] $p1[1] 36 0 (180 - $tl) $false; ArcS $blue 3 $p2[0] $p2[1] 36 0 (180 - $tl) $false; Txt 'a' ($p1[0] + 24) ($p1[1] - 40) 22 $blue $true; Txt 'a' ($p2[0] + 24) ($p2[1] - 40) 22 $blue $true; TxtC 'F: corresponding angles are equal' ($x0 + 150) 350 17 $ink $true }
  if ($k -eq 2) { ArcS $blue 3 $p1[0] $p1[1] 36 (360 - $tl) 360 $false; ArcS $orange 3 $p2[0] $p2[1] 36 0 (180 - $tl) $false; Txt 'a' ($p1[0] + 22) ($p1[1] + 6) 22 $blue $true; Txt 'b' ($p2[0] + 24) ($p2[1] - 40) 22 $orange $true; TxtC ('C: co-interior angles add up to 180' + [string][char]0xB0) ($x0 + 150) 350 17 $ink $true }
}
Save 'mth-parallel-angles.png'

# trig sides
Canvas 900 470
$P = @(160, 90); $Q = @(160, 390); $R = @(600, 390)
Line $ink 4 $P[0] $P[1] $Q[0] $Q[1] $false; Line $ink 4 $Q[0] $Q[1] $R[0] $R[1] $false; Line $green 4 $P[0] $P[1] $R[0] $R[1] $false
$sq = PenOf $ink 2; $script:g.DrawRectangle($sq, $Q[0], ($Q[1] - 28), 28, 28); $sq.Dispose()
$tt = [math]::Atan2(300, 440) * 180 / [math]::PI; ArcS $orange 3 $R[0] $R[1] 70 (180 - $tt) 180 $false; Txt $th ($R[0] - 100) ($R[1] - 36) 26 $orange $true
Txt 'Opposite' 50 205 22 $blue $true; Txt '(OPP)' 70 231 22 $blue $true; Txt 'Adjacent (ADJ)' 280 ($Q[1] + 10) 22 $ink $true; Txt 'Hypotenuse (HYP)' 210 275 22 $green $true
Txt 'P' ($P[0] - 6) ($P[1] - 34) 24 $ink $true; Txt 'Q' ($Q[0] - 30) ($Q[1] + 4) 24 $ink $true; Txt 'R' ($R[0] + 10) ($R[1] + 4) 24 $ink $true
Txt 'SOH   sin = OPP / HYP' 640 150 22 $ink $true; Txt 'CAH   cos = ADJ / HYP' 640 190 22 $ink $true; Txt 'TOA   tan = OPP / ADJ' 640 230 22 $ink $true
Txt 'The sides are named' 640 290 20 $ink $false; Txt "for the angle $th at R." 640 316 20 $ink $false
Save 'mth-trig-sides.png'

# special triangles
Canvas 900 460
Line $ink 4 80 380 320 380 $false; Line $ink 4 80 380 80 140 $false; Line $green 4 80 140 320 380 $false
$sq = PenOf $ink 2; $script:g.DrawRectangle($sq, 80, 352, 28, 28); $sq.Dispose()
Txt '1' 190 392 26 $ink $true; Txt '1' 46 250 26 $ink $true; Txt "${rt}2" 214 240 26 $green $true; Txt "45$dg" 222 356 22 $orange $true; Txt "45$dg" 88 205 22 $orange $true
TxtC "45$dg, 45$dg, 90$dg triangle" 200 420 22 $ink $true
Line $ink 4 560 380 760 380 $false; Line $ink 4 560 380 560 207 $false; Line $green 4 560 207 760 380 $false
$sq = PenOf $ink 2; $script:g.DrawRectangle($sq, 560, 352, 28, 28); $sq.Dispose()
Txt '1' 650 392 26 $ink $true; Txt "${rt}3" 500 280 26 $ink $true; Txt '2' 676 270 26 $green $true; Txt "60$dg" 688 356 22 $orange $true; Txt "30$dg" 568 255 22 $orange $true
TxtC "30$dg, 60$dg, 90$dg triangle" 660 420 22 $ink $true
Save 'mth-special-triangles.png'

# elevation and depression
Canvas 760 470
$tw = @(560, 130); $car = @(170, 400)
Line $ink 3 80 400 700 400 $false; Line $ink 6 $tw[0] 400 $tw[0] $tw[1] $false; Line $light 3 140 $tw[1] $tw[0] $tw[1] $true; Line $green 3 $car[0] $car[1] $tw[0] $tw[1] $false
$ang = [math]::Atan2(270, 390) * 180 / [math]::PI
ArcS $orange 3 $tw[0] $tw[1] 80 180 (180 + $ang) $false; Txt $th ($tw[0] - 112) ($tw[1] + 14) 24 $orange $true
ArcS $blue 3 $car[0] $car[1] 80 0 $ang $false; Txt $th ($car[0] + 90) ($car[1] - 40) 24 $blue $true
$b = New-Object Drawing.SolidBrush $ink; $script:g.FillRectangle($b, ($car[0] - 36), ($car[1] - 22), 60, 22); $script:g.FillEllipse($b, ($car[0] - 30), ($car[1] - 8), 14, 14); $script:g.FillEllipse($b, ($car[0] + 4), ($car[1] - 8), 14, 14); $b.Dispose()
Txt 'angle of depression' 240 84 20 $orange $true; Txt 'angle of elevation' 300 350 20 $blue $true; Txt 'horizontal' 150 ($tw[1] + 8) 20 $light $false; Txt 'tower' ($tw[0] + 14) 250 22 $ink $true
Txt 'depression = elevation (alternate angles)' 200 440 20 $ink $false
Save 'mth-elevation.png'

# ASTC
Canvas 640 560
$cx = 320; $cy = 280
Arrow $ink 2.5 40 $cy 610 $cy; Arrow $ink 2.5 $cx 470 $cx 20
TxtC 'ALL positive' 470 160 28 $green $true; TxtC "Quadrant I: 0$dg - 90$dg" 470 200 20 $ink $false
TxtC 'SIN positive' 170 160 28 $blue $true; TxtC "Quadrant II: 90$dg - 180$dg" 170 200 20 $ink $false
TxtC 'TAN positive' 170 360 28 $orange $true; TxtC "Quadrant III: 180$dg - 270$dg" 170 400 20 $ink $false
TxtC 'COS positive' 470 360 28 $ink $true; TxtC "Quadrant IV: 270$dg - 360$dg" 470 400 20 $ink $false
TxtC 'A   S   T   C : All Students Take Cash' $cx 515 22 $ink $true
Save 'mth-astc.png'

# unit circle
Canvas 780 720
$cx = 390; $cy = 340; $R0 = 250
$pn = PenOf $ink 3; $script:g.DrawEllipse($pn, [single]($cx - $R0), [single]($cy - $R0), [single](2 * $R0), [single](2 * $R0)); $pn.Dispose()
Arrow $ink 2 ($cx - $R0 - 40) $cy ($cx + $R0 + 40) $cy; Arrow $ink 2 $cx ($cy + $R0 + 40) $cx ($cy - $R0 - 40)
$pp = PolarPt $cx $cy $R0 40
Line $green 4 $cx $cy $pp[0] $pp[1] $false; Line $orange 3 $pp[0] $pp[1] $pp[0] $cy $true; Line $blue 4 $cx $cy $pp[0] $cy $false
ArcS $ink 2 $cx $cy 60 0 40 $false; Txt $th ($cx + 66) ($cy - 38) 24 $ink $true
Dot $green $pp[0] $pp[1] 8; Txt 'P (cos, sin)' ($pp[0] + 10) ($pp[1] - 30) 22 $green $true
Txt 'cos' (($cx + $pp[0]) / 2 - 18) ($cy + 8) 22 $blue $true; Txt 'sin' ($pp[0] + 8) (($pp[1] + $cy) / 2 - 6) 22 $orange $true
Txt "1" ($cx + $R0 + 8) ($cy + 8) 20 $ink $false; Txt "0$dg or 360$dg  (1, 0)" ($cx + $R0 - 40) ($cy + 34) 20 $ink $true
Txt "90$dg  (0, 1)" ($cx + 12) ($cy - $R0 - 30) 20 $ink $true; Txt "180$dg  (-1, 0)" ($cx - $R0 - 40) ($cy + 34) 20 $ink $true; Txt "270$dg  (0, -1)" ($cx + 12) ($cy + $R0 + 8) 20 $ink $true
Txt 'radius = 1' ($cx - 150) ($cy - 150) 20 $green $false
Save 'mth-unit-circle.png'

# sine and cosine graphs
Canvas 1000 520
$ox = 90; $oy = 260; $ux = 2.4; $uy = 170
foreach ($d in 0, 90, 180, 270, 360) { Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 ($ox + $d * $ux) ($oy - 1.2 * $uy) ($ox + $d * $ux) ($oy + 1.2 * $uy) $false; TxtC "$d$dg" ($ox + $d * $ux) ($oy + 6) 20 $ink $false }
foreach ($v in -1, 1) { Line ([Drawing.Color]::FromArgb(226, 232 , 240)) 1 $ox ($oy - $v * $uy) ($ox + 360 * $ux) ($oy - $v * $uy) $false; Txt "$v" ($ox - 36) ($oy - $v * $uy - 12) 20 $ink $false }
Arrow $ink 2.5 ($ox - 10) $oy ($ox + 360 * $ux + 30) $oy; Arrow $ink 2.5 $ox ($oy + 1.3 * $uy) $ox ($oy - 1.3 * $uy)
$pts = @(); for ($d = 0; $d -le 360; $d += 10) { $pts += ,@(($ox + $d * $ux), ($oy - [math]::Sin((RadOf $d)) * $uy)) }; Curve $blue 4 $pts
$pts = @(); for ($d = 0; $d -le 360; $d += 10) { $pts += ,@(($ox + $d * $ux), ($oy - [math]::Cos((RadOf $d)) * $uy)) }; Curve $orange 4 $pts
Txt 'y = sin x' 600 60 24 $blue $true; Txt 'y = cos x' 740 60 24 $orange $true
Txt "Period 360$dg, amplitude 1" 90 470 22 $ink $false
Save 'mth-trig-graphs.png'

# tangent graph
Canvas 1000 560
$ox = 90; $oy = 280; $ux = 2.4; $uy = 70
foreach ($d in 0, 90, 180, 270, 360) { TxtC "$d$dg" ($ox + $d * $ux) ($oy + 6) 20 $ink $false }
Arrow $ink 2.5 ($ox - 10) $oy ($ox + 360 * $ux + 30) $oy; Arrow $ink 2.5 $ox ($oy + 3.5 * $uy) $ox ($oy - 3.5 * $uy)
foreach ($d in 90, 270) { Line $light 2 ($ox + $d * $ux) ($oy - 3.4 * $uy) ($ox + $d * $ux) ($oy + 3.4 * $uy) $true }
foreach ($br in @(@(0, 80), @(100, 260), @(280, 360))) {
  $pts = @(); for ($d = $br[0]; $d -le $br[1]; $d += 5) { $t = [math]::Tan((RadOf $d)); if ([math]::Abs($t) -le 3.3) { $pts += ,@(($ox + $d * $ux), ($oy - $t * $uy)) } }
  if ($pts.Count -gt 1) { Curve $blue 4 $pts }
}
Txt 'y = tan x' 420 500 24 $blue $true; Txt 'asymptote at 90°' ($ox + 90 * $ux + 8) 60 20 $light $true; Txt 'asymptote at 270°' ($ox + 270 * $ux + 8) 60 20 $light $true
Txt "Period 180$dg" 90 520 22 $ink $false
Save 'mth-tan-graph.png'
# ---------- 13. maths: mensuration and statistics ----------
$pi = [string][char]0x03C0; $sq2 = [string][char]0xB2; $cb3 = [string][char]0xB3; $dg = [string][char]0xB0
function PtOn($cx, $cy, $r, $a) { @(($cx + $r * [math]::Cos((RadOf $a))), ($cy - $r * [math]::Sin((RadOf $a)))) }
function FillPoly($c, $pts) { $arr = @(); foreach ($q in $pts) { $arr += New-Object Drawing.PointF ([single]$q[0]), ([single]$q[1]) }; $b = New-Object Drawing.SolidBrush $c; $script:g.FillPolygon($b, [Drawing.PointF[]]$arr); $b.Dispose() }
function Ellip($c, $w, $cx, $cy, $rx, $ry, $dash) { $pn = PenOf $c $w; if ($dash) { $pn.DashStyle = 'Dash' }; $script:g.DrawEllipse($pn, [single]($cx - $rx), [single]($cy - $ry), [single](2 * $rx), [single](2 * $ry)); $pn.Dispose() }
$blueL = [Drawing.Color]::FromArgb(110, 24, 66, 168); $orangeL = [Drawing.Color]::FromArgb(120, 217, 119, 6); $greenL = [Drawing.Color]::FromArgb(90, 5, 150, 105)

# parts of a circle
Canvas 780 620
$cx = 390; $cy = 310; $r = 230
$b = New-Object Drawing.SolidBrush $blueL; $script:g.FillPie($b, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](-85), [single](60)); $b.Dispose()
$sg = @(); for ($a = 205; $a -le 335; $a += 5) { $sg += ,(PtOn $cx $cy $r $a) }; FillPoly $orangeL $sg
Ellip $ink 4 $cx $cy $r $r $false
Line $ink 3 $cx $cy (($PtOn = PtOn $cx $cy $r 25)[0]) $PtOn[1] $false; Line $ink 3 $cx $cy ((PtOn $cx $cy $r 85)[0]) ((PtOn $cx $cy $r 85)[1]) $false
ArcS $blue 8 $cx $cy $r 25 85 $false
Line $green 4 ($cx - $r) $cy ($cx + $r) $cy $true
$c1 = PtOn $cx $cy $r 205; $c2 = PtOn $cx $cy $r 335; Line $orange 5 $c1[0] $c1[1] $c2[0] $c2[1] $false
$rd = PtOn $cx $cy $r 150; Line $ink 3 $cx $cy $rd[0] $rd[1] $false
Dot $ink $cx $cy 7
Txt 'centre' ($cx + 10) ($cy + 10) 22 $ink $true; Txt 'radius' ($cx - 190) ($cy - 78) 22 $ink $true; Txt 'diameter' ($cx - 200) ($cy + 10) 22 $green $true
Txt 'arc' ($cx + 190) ($cy - 215) 24 $blue $true; Txt 'sector' ($cx + 70) ($cy - 150) 24 $blue $true
Txt 'chord' ($cx - 40) ($cy + 128) 22 $orange $true; Txt 'segment' ($cx - 52) ($cy + 168) 22 $orange $true
Save 'mth-circle-parts.png'

# sector folded to a cone
Canvas 900 500
$ax = 230; $ay = 60; $rr = 280
$sect = @(@($ax, $ay)); for ($a = 235; $a -le 305; $a += 5) { $sect += ,(PtOn $ax $ay $rr $a) }; FillPoly $blueL $sect
$e1 = PtOn $ax $ay $rr 235; $e2 = PtOn $ax $ay $rr 305
Line $ink 3 $ax $ay $e1[0] $e1[1] $false; Line $ink 3 $ax $ay $e2[0] $e2[1] $false; ArcS $blue 5 $ax $ay $rr 235 305 $false
Txt 'radius = slant height l' ($ax - 190) 190 20 $ink $true; Txt 'arc = 2πR' ($ax - 50) ($ay + $rr + 12) 22 $blue $true
ArcS $ink 2 $ax $ay 70 235 305 $false; Txt ([string][char]0x03B8) ($ax - 8) ($ay + 74) 24 $ink $true
Arrow $ink 4 450 250 540 250; Txt 'FOLD' 455 215 22 $ink $true
$tx = 720; $ty = 70; $by = 400
FillPoly $blueL @(@($tx, $ty), @(($tx - 140), $by), @(($tx + 140), $by))
Ellip $ink 3 $tx $by 140 40 $false
Line $ink 3 $tx $ty ($tx - 140) $by $false; Line $ink 3 $tx $ty ($tx + 140) $by $false
Line $light 2 $tx $ty $tx $by $true; Line $green 3 $tx $by ($tx + 140) $by $false
Txt 'h' ($tx + 8) 220 24 $light $true; Txt 'R' ($tx + 62) ($by + 8) 24 $green $true; Txt 'l' ($tx + 82) 200 24 $ink $true
Txt 'l' 0 0 1 $ink $false
Txt 'CSA = πRl' ($tx - 52) 450 22 $ink $true
Save 'mth-sector-cone.png'

# solids
Canvas 1140 700
function Cuboid3($x, $y, $w, $h, $d, $c) { $o = $d * 0.6; Line $c 3 $x $y ($x + $w) $y $false; Line $c 3 $x $y $x ($y + $h) $false; Line $c 3 ($x + $w) $y ($x + $w) ($y + $h) $false; Line $c 3 $x ($y + $h) ($x + $w) ($y + $h) $false; Line $c 3 ($x + $o) ($y - $o) ($x + $w + $o) ($y - $o) $true; Line $c 3 ($x + $w + $o) ($y - $o) ($x + $w + $o) ($y + $h - $o) $false; Line $c 3 $x $y ($x + $o) ($y - $o) $false; Line $c 3 ($x + $w) $y ($x + $w + $o) ($y - $o) $false; Line $c 3 ($x + $w) ($y + $h) ($x + $w + $o) ($y + $h - $o) $false }
Cuboid3 100 170 120 120 120 $ink; TxtC 'Cube' 175 340 24 $ink $true; TxtC ("TSA = 6l$sq2    V = l$cb3") 190 372 20 $ink $false
Cuboid3 470 190 220 100 100 $ink; TxtC 'Cuboid' 560 340 24 $ink $true; TxtC ("TSA = 2(lw + lh + wh)    V = lwh") 590 372 20 $ink $false
Ellip $ink 3 900 130 80 24 $false; Line $ink 3 820 130 820 290 $false; Line $ink 3 980 130 980 290 $false; $pn = PenOf $ink 3; $script:g.DrawArc($pn, 820, 266, 160, 48, 0, 180); $pn.Dispose(); $pn = PenOf $ink 3; $pn.DashStyle = 'Dash'; $script:g.DrawArc($pn, 820, 266, 160, 48, 180, 180); $pn.Dispose()
TxtC 'Cylinder' 900 340 24 $ink $true; TxtC ("TSA = 2${pi}r(r + h)    V = ${pi}r${sq2}h") 900 372 20 $ink $false
Line $ink 3 190 440 130 580 $false; Line $ink 3 190 440 270 580 $false; $pn = PenOf $ink 3; $script:g.DrawArc($pn, 120, 560, 160, 40, 0, 180); $pn.Dispose(); $pn = PenOf $ink 3; $pn.DashStyle = 'Dash'; $script:g.DrawArc($pn, 120, 560, 160, 40, 180, 180); $pn.Dispose()
TxtC 'Cone' 200 630 24 $ink $true; TxtC ("TSA = ${pi}R(R + l)    V = 1/3 ${pi}R${sq2}h") 220 662 20 $ink $false
Line $ink 3 560 440 470 590 $false; Line $ink 3 560 440 640 560 $false; Line $ink 3 560 440 560 600 $true; Line $ink 3 470 590 640 560 $false; Line $ink 3 470 590 540 610 $false; Line $ink 3 540 610 640 560 $false; Line $ink 3 560 440 540 610 $false
TxtC 'Square pyramid' 560 630 24 $ink $true; TxtC ("TSA = l$sq2 + 2ls    V = 1/3 l${sq2}h") 580 662 20 $ink $false
Line $ink 3 860 470 960 590 $false; Line $ink 3 860 470 790 590 $false; Line $ink 3 790 590 960 590 $false; Line $ink 3 860 470 920 440 $false; Line $ink 3 920 440 1020 560 $false; Line $ink 3 960 590 1020 560 $false; Line $ink 3 920 440 880 470 $true
TxtC 'Triangular prism' 900 630 24 $ink $true; TxtC 'V = base area x length' 900 662 20 $ink $false
Save 'mth-solids.png'

# frustum
Canvas 860 580
$ax = 300; $ay = 40; $cyb = 480; $RR = 220; $cyc = 260
FillPoly $greenL @(@(($ax - 110), $cyc), @(($ax + 110), $cyc), @(($ax + $RR), $cyb), @(($ax - $RR), $cyb))
Line $ink 3 $ax $ay ($ax - $RR) $cyb $false; Line $ink 3 $ax $ay ($ax + $RR) $cyb $false
Ellip $ink 3 $ax $cyb $RR 45 $false; Ellip $ink 3 $ax $cyc 110 22 $false
Line $light 2 $ax $ay $ax $cyb $true
Line $green 3 $ax $cyb ($ax + $RR) $cyb $false; Line $orange 3 $ax $cyc ($ax + 110) $cyc $false
Txt 'R' ($ax + 100) ($cyb + 8) 24 $green $true; Txt 'r' ($ax + 44) ($cyc + 4) 24 $orange $true
Line $ink 2 600 $ay 600 $cyb $false; Line $ink 2 590 $ay 610 $ay $false; Line $ink 2 590 $cyb 610 $cyb $false; Txt 'H' 616 250 24 $ink $true
Line $blue 2 540 $ay 540 $cyc $false; Line $blue 2 530 $ay 550 $ay $false; Line $blue 2 530 $cyc 550 $cyc $false; Txt 'h_s' 480 140 22 $blue $true
Line $green 2 540 ($cyc + 8) 540 $cyb $false; Txt 'h_f' 482 360 22 $green $true
Txt 'Frustum = large cone - small cone' 40 548 22 $ink $true
Txt 'r / R = h_s / H' 640 120 22 $ink $true; Txt 'H = h_s + h_f' 640 150 22 $ink $true
Save 'mth-frustum.png'

# bar chart of shoe sizes
Canvas 760 520
$ox = 100; $oy = 430; $uy = 38
Arrow $ink 2.5 $ox $oy 700 $oy; Arrow $ink 2.5 $ox $oy $ox 50
foreach ($j in 0..10) { if ($j % 2 -eq 0) { Txt "$j" ($ox - 34) ($oy - $j * $uy - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 $ox ($oy - $j * $uy) 690 ($oy - $j * $uy) $false } }
$vals = @(@(6, 2), @(7, 5), @(8, 8), @(9, 3), @(10, 2)); $k = 0
foreach ($v in $vals) { $x = $ox + 30 + $k * 112; $b = New-Object Drawing.SolidBrush $blue; $script:g.FillRectangle($b, [single]$x, [single]($oy - $v[1] * $uy), 76, [single]($v[1] * $uy)); $b.Dispose(); TxtC "$($v[0])" ($x + 38) ($oy + 6) 20 $ink $false; TxtC "$($v[1])" ($x + 38) ($oy - $v[1] * $uy - 28) 18 $ink $true; $k++ }
TxtC 'Shoe size' 400 475 22 $ink $true; TxtV 'Frequency' 40 240 22 $ink; TxtC 'Shoe sizes of 20 students' 400 12 22 $ink $true
Save 'mth-bar-chart.png'

# histogram of heights
Canvas 860 540
$ox = 110; $oy = 440; $ux = 125; $uy = 19
Arrow $ink 2.5 $ox $oy 820 $oy; Arrow $ink 2.5 $ox $oy $ox 40
foreach ($j in 0, 4, 8, 12, 16, 20) { Txt "$j" ($ox - 38) ($oy - $j * $uy - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 $ox ($oy - $j * $uy) 800 ($oy - $j * $uy) $false }
$fr = @(6, 12, 18, 10, 4); $bd = @('149.5', '154.5', '159.5', '164.5', '169.5', '174.5')
for ($k = 0; $k -lt 5; $k++) { $x = $ox + $k * $ux; $b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(150, 24, 66, 168)); $script:g.FillRectangle($b, [single]$x, [single]($oy - $fr[$k] * $uy), [single]$ux, [single]($fr[$k] * $uy)); $b.Dispose(); $pn = PenOf $ink 2; $script:g.DrawRectangle($pn, [single]$x, [single]($oy - $fr[$k] * $uy), [single]$ux, [single]($fr[$k] * $uy)); $pn.Dispose(); TxtC "$($fr[$k])" ($x + $ux / 2) ($oy - $fr[$k] * $uy - 28) 18 $ink $true }
for ($k = 0; $k -le 5; $k++) { TxtC $bd[$k] ($ox + $k * $ux) ($oy + 6) 18 $ink $false }
TxtC 'Height (cm), class boundaries' 440 485 22 $ink $true; TxtV 'Frequency' 52 250 22 $ink; TxtC 'Heights of 50 SS1 students' 440 8 22 $ink $true
Save 'mth-histogram.png'

# pie chart
Canvas 760 560
$cx = 330; $cy = 290; $r = 210
$b1 = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(24, 66, 168)); $b2 = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(217, 119, 6)); $b3 = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(5, 150, 105))
$script:g.FillPie($b1, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](-90), [single]135)
$script:g.FillPie($b2, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](45), [single]180)
$script:g.FillPie($b3, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](225), [single]45)
$b1.Dispose(); $b2.Dispose(); $b3.Dispose()
foreach ($a in -90, 45, 225) { $pt = @(($cx + $r * [math]::Cos((RadOf $a))), ($cy + $r * [math]::Sin((RadOf $a)))); Line ([Drawing.Color]::White) 4 $cx $cy $pt[0] $pt[1] $false }
Txt 'Arts: 30 students' 560 20 18 $blue $true; Txt ("135$dg") 560 46 22 $blue $true
Txt 'Science: 40 students' 540 480 18 $orange $true; Txt ("180$dg") 540 506 22 $orange $true
Txt 'Commercial:' 22 40 18 $green $true; Txt '10 students' 22 62 18 $green $true; Txt ("45$dg") 22 88 22 $green $true
TxtC 'Total 80 students: 135 + 180 + 45 = 360' 380 535 20 $ink $true
Save 'mth-pie-chart.png'

# frequency polygon over histogram
Canvas 980 540
$ox = 80; $oy = 440; $uxx = 22; $uy = 19; $x0v = 144
function PXv($v) { $script:ox + ($v - $script:x0v) * $script:uxx }
Arrow $ink 2.5 $ox $oy 940 $oy; Arrow $ink 2.5 $ox $oy $ox 40
foreach ($j in 0, 4, 8, 12, 16, 20) { Txt "$j" ($ox - 38) ($oy - $j * $uy - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 $ox ($oy - $j * $uy) 920 ($oy - $j * $uy) $false }
$cls = @(@(149.5, 154.5, 6), @(154.5, 159.5, 12), @(159.5, 164.5, 18), @(164.5, 169.5, 10), @(169.5, 174.5, 4))
foreach ($c in $cls) { $b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(70, 24, 66, 168)); $script:g.FillRectangle($b, [single](PXv $c[0]), [single]($oy - $c[2] * $uy), [single](($c[1] - $c[0]) * $uxx), [single]($c[2] * $uy)); $b.Dispose(); $pn = PenOf $light 2; $script:g.DrawRectangle($pn, [single](PXv $c[0]), [single]($oy - $c[2] * $uy), [single](($c[1] - $c[0]) * $uxx), [single]($c[2] * $uy)); $pn.Dispose() }
$mp = @(@(147, 0), @(152, 6), @(157, 12), @(162, 18), @(167, 10), @(172, 4), @(177, 0))
$pl = PenOf $orange 4; $pa = @(); foreach ($m in $mp) { $pa += New-Object Drawing.PointF ([single](PXv $m[0])), ([single]($oy - $m[1] * $uy)) }; $script:g.DrawLines($pl, [Drawing.PointF[]]$pa); $pl.Dispose()
foreach ($m in $mp) { Dot $orange (PXv $m[0]) ($oy - $m[1] * $uy) 7; TxtC "$($m[0])" (PXv $m[0]) ($oy + 6) 18 $ink $true }
TxtC 'Class midpoints (cm)' 480 485 22 $ink $true; TxtV 'Frequency' 30 250 22 $ink; TxtC 'Frequency polygon (grounded at 147 and 177)' 480 8 22 $ink $true
Save 'mth-freq-polygon.png'
"drawn 32 figures"
Get-ChildItem $out | Measure-Object | ForEach-Object { "images in folder: $($_.Count)" }
