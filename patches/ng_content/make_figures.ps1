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
  @('eng', 114, 'eng-family-tree.jpg', $null),
  @('eco', 141, 'eco-simple-bar.jpg', $null), @('eco', 148, 'eco-component-bar.jpg', @(0, 6, 1391, 863)), @('eco', 156, 'eco-multiple-bar.jpg', @(0, 6, 1594, 933)),
  @('eco', 187, 'eco-histogram-ungrouped.jpg', @(0, 6, 1273, 754)), @('eco', 992, 'eco-industrial-zones.jpg', $null),
  @('bio', 81, 'bio-kingdoms.jpg', $null), @('bio', 102, 'bio-animal-classification.jpg', $null), @('bio', 118, 'bio-grasshopper.jpg', $null), @('bio', 124, 'bio-myriapods.jpg', $null), @('bio', 136, 'bio-fish.jpg', $null),
  @('bio', 137, 'bio-frog-toad.jpg', $null), @('bio', 143, 'bio-lizard.jpg', $null), @('bio', 149, 'bio-bird.jpg', $null), @('bio', 165, 'bio-plant-cell.jpg', $null), @('bio', 166, 'bio-animal-cell.jpg', $null),
  @('bio', 193, 'bio-osmosis-diffusion.jpg', $null), @('bio', 251, 'bio-glycolysis.jpg', $null), @('bio', 257, 'bio-krebs.jpg', $null), @('bio', 280, 'bio-meiosis-prophase1.jpg', $null), @('bio', 281, 'bio-meiosis-metaphase1.jpg', $null),
  @('bio', 287, 'bio-meiosis-anaphase1.jpg', $null), @('bio', 288, 'bio-meiosis-telophase1.jpg', $null), @('bio', 294, 'bio-meiosis-2.jpg', $null), @('bio', 337, 'bio-skeleton.jpg', $null), @('bio', 369, 'bio-xylem-phloem.jpg', $null),
  @('bio', 494, 'bio-trophic-pyramid.jpg', $null), @('bio', 500, 'bio-energy-pyramid.jpg', $null), @('bio', 575, 'bio-bacteria-shapes.jpg', $null), @('bio', 756, 'bio-savanna-desert.jpg', @(0, 0, 1017, 336)), @('bio', 794, 'bio-amoeba-fission.jpg', $null),
  @('bio', 800, 'bio-spirogyra.jpg', @(0, 0, 720, 315)),
  @('chem', 36, 'chem-chemistry-central.jpg', $null), @('chem', 83, 'chem-industries.jpg', @(0, 0, 575, 720)), @('chem', 151, 'chem-particles.jpg', $null), @('chem', 200, 'chem-fractional.jpg', $null), @('chem', 201, 'chem-simple-distillation.jpg', $null),
  @('chem', 207, 'chem-sublimation.jpg', $null), @('chem', 213, 'chem-centrifuge.jpg', @(0, 0, 229, 268)), @('chem', 214, 'chem-chromatography.jpg', $null), @('chem', 220, 'chem-decantation.jpg', $null), @('chem', 221, 'chem-evaporation.jpg', $null),
  @('chem', 227, 'chem-winnowing.jpg', $null), @('chem', 228, 'chem-magnet.jpg', $null), @('chem', 235, 'chem-sieving.jpg', $null), @('chem', 253, 'chem-atom-model.jpg', $null), @('chem', 269, 'chem-bohr.jpg', $null), @('chem', 286, 'chem-periodic-table.jpg', $null), @('eco', 194, 'eco-histogram-grouped.jpg', @(0, 0, 770, 728))
)
foreach ($m in $map) { CopyImg $m[0] $m[1] $m[2] $m[3] }
"copied $($map.Count) pictures"

function PaintOver($name, $x, $y, $w, $h) {
  $path = Join-Path $out $name
  $im = [Drawing.Bitmap]::FromStream((New-Object IO.MemoryStream (, [IO.File]::ReadAllBytes($path))))
  $bmp = New-Object Drawing.Bitmap $im.Width, $im.Height
  $g0 = [Drawing.Graphics]::FromImage($bmp); $g0.DrawImage($im, 0, 0, $im.Width, $im.Height); $g0.Dispose(); $im.Dispose()
  for ($yy = $y; $yy -lt ($y + $h); $yy++) {
    $cl = $bmp.GetPixel(($x - 3), $yy); $cr = $bmp.GetPixel(($x + $w + 3), $yy)
    for ($xx = $x; $xx -lt ($x + $w); $xx++) {
      $t = ($xx - $x) / [double]$w
      $c = [Drawing.Color]::FromArgb([int]($cl.R + ($cr.R - $cl.R) * $t), [int]($cl.G + ($cr.G - $cl.G) * $t), [int]($cl.B + ($cr.B - $cl.B) * $t))
      $bmp.SetPixel($xx, $yy, $c)
    }
  }
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object Drawing.Imaging.EncoderParameters 1; $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 92L
  $bmp.Save($path, $enc, $ep); $bmp.Dispose()
}
PaintOver 'chem-winnowing.jpg' 296 62 130 34
PaintOver 'chem-magnet.jpg' 486 151 130 17
function FillWhite($name, $x, $y, $w, $h) {
  $path = Join-Path $out $name
  $im = [Drawing.Bitmap]::FromStream((New-Object IO.MemoryStream (, [IO.File]::ReadAllBytes($path))))
  $bmp = New-Object Drawing.Bitmap $im.Width, $im.Height
  $g0 = [Drawing.Graphics]::FromImage($bmp); $g0.DrawImage($im, 0, 0, $im.Width, $im.Height); $g0.FillRectangle([Drawing.Brushes]::White, $x, $y, $w, $h); $g0.Dispose(); $im.Dispose()
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object Drawing.Imaging.EncoderParameters 1; $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter ([Drawing.Imaging.Encoder]::Quality), 92L
  $bmp.Save($path, $enc, $ep); $bmp.Dispose()
}
FillWhite 'bio-meiosis-prophase1.jpg' 0 300 105 30
FillWhite 'bio-meiosis-metaphase1.jpg' 0 294 105 22
FillWhite 'bio-meiosis-anaphase1.jpg' 0 266 135 30
FillWhite 'bio-meiosis-telophase1.jpg' 0 324 140 30

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
TxtC 'Shoe size' 400 475 22 $ink $true; TxtV 'Frequency' 18 240 22 $ink; TxtC 'Shoe sizes of 20 students' 400 12 22 $ink $true
Save 'mth-bar-chart.png'

# histogram of heights
Canvas 860 540
$ox = 110; $oy = 440; $ux = 125; $uy = 19
Arrow $ink 2.5 $ox $oy 820 $oy; Arrow $ink 2.5 $ox $oy $ox 40
foreach ($j in 0, 4, 8, 12, 16, 20) { Txt "$j" ($ox - 38) ($oy - $j * $uy - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 $ox ($oy - $j * $uy) 800 ($oy - $j * $uy) $false }
$fr = @(6, 12, 18, 10, 4); $bd = @('149.5', '154.5', '159.5', '164.5', '169.5', '174.5')
for ($k = 0; $k -lt 5; $k++) { $x = $ox + $k * $ux; $b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(150, 24, 66, 168)); $script:g.FillRectangle($b, [single]$x, [single]($oy - $fr[$k] * $uy), [single]$ux, [single]($fr[$k] * $uy)); $b.Dispose(); $pn = PenOf $ink 2; $script:g.DrawRectangle($pn, [single]$x, [single]($oy - $fr[$k] * $uy), [single]$ux, [single]($fr[$k] * $uy)); $pn.Dispose(); TxtC "$($fr[$k])" ($x + $ux / 2) ($oy - $fr[$k] * $uy - 28) 18 $ink $true }
for ($k = 0; $k -le 5; $k++) { TxtC $bd[$k] ($ox + $k * $ux) ($oy + 6) 18 $ink $false }
TxtC 'Height (cm), class boundaries' 440 485 22 $ink $true; TxtV 'Frequency' 16 250 22 $ink; TxtC 'Heights of 50 SS1 students' 440 8 22 $ink $true
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
TxtC 'Class midpoints (cm)' 480 485 22 $ink $true; TxtV 'Frequency' 10 250 22 $ink; TxtC 'Frequency polygon (grounded at 147 and 177)' 480 8 22 $ink $true
Save 'mth-freq-polygon.png'

# ---------- Economics figures ----------
$red = [Drawing.Color]::FromArgb(220, 38, 38)
# demand graph: price = 11 - quantity
Canvas 900 620
$ox = 90; $oy = 520; $ux = 72; $uyy = 40
for ($i = 0; $i -le 10; $i++) { Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 ($ox + $i * $ux) $oy ($ox + $i * $ux) ($oy - 11 * $uyy) $false; Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 $ox ($oy - $i * $uyy) ($ox + 10.5 * $ux) ($oy - $i * $uyy) $false }
Arrow $ink 2.5 $ox $oy ($ox + 10.8 * $ux) $oy; Arrow $ink 2.5 $ox $oy $ox ($oy - 11.3 * $uyy)
for ($i = 1; $i -le 10; $i++) { TxtC "$i" ($ox + $i * $ux) ($oy + 8) 20 $ink $false; Txt "$i" ($ox - 36) ($oy - $i * $uyy - 12) 20 $ink $false }
TxtC 'Quantity demanded' ($ox + 5 * $ux) ($oy + 42) 22 $ink $true; TxtV 'Price (N)' 22 ($oy - 5 * $uyy) 22 $ink
$pa = @(); for ($q = 1; $q -le 10; $q++) { $pa += ,@(($ox + $q * $ux), ($oy - (11 - $q) * $uyy)) }
$pl = PenOf $blue 4; $pts = @(); foreach ($a in $pa) { $pts += New-Object Drawing.PointF ([single]$a[0]), ([single]$a[1]) }; $script:g.DrawLines($pl, [Drawing.PointF[]]$pts); $pl.Dispose()
foreach ($a in $pa) { Dot $orange $a[0] $a[1] 7 }
Txt 'D' ($pa[0][0] + 10) ($pa[0][1] - 30) 26 $blue $true; Txt 'D' ($pa[9][0] - 6) ($pa[9][1] - 36) 26 $blue $true
TxtC 'A demand curve: price falls as quantity demanded rises' 450 6 22 $ink $true
Save 'eco-demand-graph.png'

# pie chart: A 126, B 180, C 54
Canvas 760 620
$cx = 380; $cy = 290; $r = 190
$bA = New-Object Drawing.SolidBrush $blue; $bB = New-Object Drawing.SolidBrush $orange; $bC = New-Object Drawing.SolidBrush $green
$script:g.FillPie($bA, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](-90), [single]126)
$script:g.FillPie($bB, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](36), [single]180)
$script:g.FillPie($bC, [single]($cx - $r), [single]($cy - $r), [single](2 * $r), [single](2 * $r), [single](216), [single]54)
$bA.Dispose(); $bB.Dispose(); $bC.Dispose()
foreach ($a in -90, 36, 216) { $pt = @(($cx + $r * [math]::Cos((RadOf $a))), ($cy + $r * [math]::Sin((RadOf $a)))); Line ([Drawing.Color]::White) 4 $cx $cy $pt[0] $pt[1] $false }
$dg = [string][char]0xB0
TxtC "Town A: 70 000" 640 70 20 $blue $true; TxtC ("126$dg  (35%)") 640 96 22 $blue $true
TxtC "Town B: 100 000" 380 520 20 $orange $true; TxtC ("180$dg  (50%)") 380 544 20 $orange $true
TxtC "Town C: 30 000" 110 190 20 $green $true; TxtC ("54$dg  (15%)") 110 216 22 $green $true
TxtC ("Total 200 000: 126 + 180 + 54 = 360$dg") 380 8 20 $ink $true
Save 'eco-pie-chart.png'

# frequency polygon over histogram of grouped ages
Canvas 900 560
$ox = 90; $oy = 450; $ux = 34; $uyy = 28; $x0e = 5
function PXe($v) { $script:ox + ($v - $script:x0e) * $script:ux }
foreach ($j in 0, 2, 4, 6, 8, 10, 12, 14) { Txt "$j" ($ox - 36) ($oy - $j * $uyy - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(226, 232, 240)) 1 $ox ($oy - $j * $uyy) 820 ($oy - $j * $uyy) $false }
Arrow $ink 2.5 $ox $oy 850 $oy; Arrow $ink 2.5 $ox $oy $ox 40
$cl = @(@(9.5, 12.5, 12, '10 - 12'), @(12.5, 15.5, 8, '13 - 15'), @(15.5, 18.5, 6, '16 - 18'), @(18.5, 21.5, 4, '19 - 21'))
foreach ($c in $cl) { $b = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(90, 24, 66, 168)); $script:g.FillRectangle($b, [single](PXe $c[0]), [single]($oy - $c[2] * $uyy), [single](($c[1] - $c[0]) * $ux), [single]($c[2] * $uyy)); $b.Dispose(); $pn = PenOf $ink 2; $script:g.DrawRectangle($pn, [single](PXe $c[0]), [single]($oy - $c[2] * $uyy), [single](($c[1] - $c[0]) * $ux), [single]($c[2] * $uyy)); $pn.Dispose(); TxtC $c[3] ((PXe $c[0]) + 1.5 * $ux) ($oy + 8) 18 $ink $false }
$mp = @(@(8, 0), @(11, 12), @(14, 8), @(17, 6), @(20, 4), @(23, 0))
$pl = PenOf $orange 4; $pts = @(); foreach ($m in $mp) { $pts += New-Object Drawing.PointF ([single](PXe $m[0])), ([single]($oy - $m[1] * $uyy)) }; $script:g.DrawLines($pl, [Drawing.PointF[]]$pts); $pl.Dispose()
foreach ($m in $mp) { Dot $orange (PXe $m[0]) ($oy - $m[1] * $uyy) 7 }
TxtC 'Age (years)' 470 ($oy + 42) 22 $ink $true; TxtV 'Number of students' 26 250 22 $ink
TxtC 'Frequency polygon: join the midpoints of the tops of the bars' 450 6 22 $ink $true
Save 'eco-freq-polygon.png'

# demand curve with p0, p1, q0, q1
Canvas 760 580
$ox = 110; $oy = 480
Arrow $ink 2.5 $ox $oy 700 $oy; Arrow $ink 2.5 $ox $oy $ox 50
TxtC 'Quantity' 640 ($oy + 12) 22 $ink $true; TxtV 'Price' 30 340 22 $ink
$p0y = 200; $p1y = 300
Curve $blue 4 @(@(190, 90), @(215, 150), @(245, 200), @(300, 255), @(385, 300), @(480, 322), @(580, 332))
Line $ink 1.5 $ox $p0y 245 $p0y $true; Line $ink 1.5 $ox $p1y 385 $p1y $true; Line $ink 1.5 245 $p0y 245 $oy $true; Line $ink 1.5 385 $p1y 385 $oy $true
Dot $orange 245 $p0y 7; Dot $orange 385 $p1y 7
Txt 'P0' 62 ($p0y - 14) 22 $ink $true; Txt 'P1' 62 ($p1y - 14) 22 $ink $true; TxtC 'Q0' 245 ($oy + 10) 22 $ink $true; TxtC 'Q1' 385 ($oy + 10) 22 $ink $true
Txt 'D' 600 308 26 $blue $true; TxtC 'Demand curve: when price falls from P0 to P1,' 400 520 20 $ink $false; TxtC 'quantity demanded rises from Q0 to Q1' 400 546 20 $ink $false
Save 'eco-demand-curve.png'

# supply curve with A(10,15) and B(30,30)
Canvas 760 640
$ox = 110; $oy = 540; $ux = 12; $uyy = 11
Arrow $ink 2.5 $ox $oy 720 $oy; Arrow $ink 2.5 $ox $oy $ox 60
foreach ($v in 10, 20, 30, 40) { TxtC "$v" ($ox + $v * $ux) ($oy + 8) 20 $ink $false; Txt "$v" ($ox - 44) ($oy - $v * $uyy - 12) 20 $ink $false }
TxtC 'Quantity supplied (Q)' 420 ($oy + 42) 22 $ink $true; TxtV 'Price (P)' 36 280 22 $ink
$sp = @(@(($ox + 3 * $ux), ($oy - 11 * $uyy)), @(($ox + 10 * $ux), ($oy - 15 * $uyy)), @(($ox + 20 * $ux), ($oy - 21 * $uyy)), @(($ox + 30 * $ux), ($oy - 30 * $uyy)), @(($ox + 35 * $ux), ($oy - 38 * $uyy)))
Curve $blue 4 $sp
$ax = $ox + 10 * $ux; $ay = $oy - 15 * $uyy; $bx = $ox + 30 * $ux; $by = $oy - 30 * $uyy
Line $ink 1.5 $ox $ay $ax $ay $true; Line $ink 1.5 $ax $ay $ax $oy $true; Line $ink 1.5 $ox $by $bx $by $true; Line $ink 1.5 $bx $by $bx $oy $true
Dot $orange $ax $ay 7; Dot $orange $bx $by 7
Txt 'A (10, 15)' ($ax + 10) ($ay + 10) 20 $ink $true; Txt 'B (30, 30)' ($bx - 98) ($by - 34) 20 $ink $true; Txt 'S' ($sp[4][0] + 10) ($sp[4][1] - 16) 26 $blue $true; Txt 'S' ($sp[0][0] - 24) ($sp[0][1] + 4) 26 $blue $true
TxtC 'Supply curve: a higher price gives a higher quantity supplied' 420 8 22 $ink $true
Save 'eco-supply-curve.png'

# ---------- Economics Term 2 figures ----------
function BoxT($x, $y, $w, $h, $text, $fill) { $b = New-Object Drawing.SolidBrush $fill; $script:g.FillRectangle($b, [single]$x, [single]$y, [single]$w, [single]$h); $b.Dispose(); $pn = PenOf $ink 2; $script:g.DrawRectangle($pn, [single]$x, [single]$y, [single]$w, [single]$h); $pn.Dispose(); TxtC $text ($x + $w / 2) ($y + $h / 2 - 12) 20 $ink $true }
Canvas 980 500
$cBlue = [Drawing.Color]::FromArgb(219, 234, 254); $cOr = [Drawing.Color]::FromArgb(254, 243, 199); $cGr = [Drawing.Color]::FromArgb(209, 250, 229)
TxtC 'Routes from the producer to the consumer' 490 8 24 $ink $true
$routes = @(@('1. Direct (no middlemen)', @('Producer', 'Consumer')), @('2. Short chain', @('Producer', 'Retailer', 'Consumer')), @('3. Usual chain', @('Producer', 'Wholesaler', 'Retailer', 'Consumer')), @('4. Long chain (with an agent)', @('Producer', 'Agent', 'Wholesaler', 'Retailer', 'Consumer')))
$ry = 80
foreach ($r in $routes) {
  Txt $r[0] 30 ($ry - 30) 20 $light $true
  $i = 0
  foreach ($nm in $r[1]) {
    $x = 30 + $i * 190
    $fc = $cBlue; if ($nm -eq 'Consumer') { $fc = $cGr } elseif ($nm -eq 'Producer') { $fc = $cOr }
    BoxT $x $ry 150 56 $nm $fc
    if ($i -lt $r[1].Count - 1) { Arrow $ink 2.5 ($x + 152) ($ry + 28) ($x + 188) ($ry + 28) }
    $i++
  }
  $ry += 108
}
Save 'eco-channels.png'

# production possibility curve
Canvas 780 680
$ox = 110; $oy = 580; $u = 3.8
Arrow $ink 2.5 $ox $oy 740 $oy; Arrow $ink 2.5 $ox $oy $ox 40
foreach ($v in 0, 20, 40, 60, 80, 100, 120, 140) { TxtC "$v" ($ox + $v * $u) ($oy + 8) 18 $ink $false; Txt "$v" ($ox - 48) ($oy - $v * $u - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(236, 240, 245)) 1 $ox ($oy - $v * $u) ($ox + 140 * $u) ($oy - $v * $u) $false }
TxtC 'Consumer goods (units)' 420 ($oy + 38) 22 $ink $true; TxtV 'Capital goods (units)' 30 300 22 $ink
$ppc = @(@(0, 140), @(40, 130), @(60, 120), @(80, 100), @(100, 80), @(120, 50), @(140, 0))
$cp = @(); foreach ($q in $ppc) { $cp += ,@(($ox + $q[0] * $u), ($oy - $q[1] * $u)) }
Curve $blue 4 $cp
$lab = 'A', 'B', 'C', 'D', 'E', 'F', 'G'; $k = 0
foreach ($q in $cp) { Dot $orange $q[0] $q[1] 7; Txt $lab[$k] ($q[0] + 10) ($q[1] - 26) 20 $ink $true; $k++ }
Dot $red ($ox + 50 * $u) ($oy - 50 * $u) 8; Txt 'X: wasteful (inside)' ($ox + 50 * $u + 12) ($oy - 50 * $u - 12) 20 $red $true
Dot $green ($ox + 120 * $u) ($oy - 120 * $u) 8; Txt 'Y: not possible now' ($ox + 120 * $u - 190) ($oy - 120 * $u - 38) 20 $green $true
TxtC 'Production possibility curve' 420 6 24 $ink $true
Save 'eco-ppc.png'

# TP, AP, MP
Canvas 900 950
$ox = 100; $ux = 105
# top panel: TP
$oyT = 400; $uyT = 6.4
Arrow $ink 2.5 $ox $oyT 860 $oyT; Arrow $ink 2.5 $ox $oyT $ox 60
foreach ($v in 0, 10, 20, 30, 40, 50) { Txt "$v" ($ox - 42) ($oyT - $v * $uyT - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(236, 240, 245)) 1 $ox ($oyT - $v * $uyT) 820 ($oyT - $v * $uyT) $false }
foreach ($w in 1..7) { TxtC "$w" ($ox + $w * $ux) ($oyT + 6) 18 $ink $false }
TxtC 'Number of workers' 480 ($oyT + 28) 20 $ink $true; TxtV 'Total product (kg)' 28 230 20 $ink
$tp = @(0, 4, 12, 24, 40, 45, 48, 42)
$pts = @(); foreach ($w in 1..7) { $pts += ,@(($ox + $w * $ux), ($oyT - $tp[$w] * $uyT)) }
Curve $blue 4 $pts
foreach ($q in $pts) { Dot $orange $q[0] $q[1] 7 }
Txt 'TP' ($pts[6][0] + 12) ($pts[6][1] - 10) 24 $blue $true
TxtC 'Total product (TP)' 480 8 22 $ink $true
# bottom panel: AP and MP
$oyB = 780; $uyB = 14
Arrow $ink 2.5 $ox $oyB 860 $oyB; Arrow $ink 2.5 $ox 850 $ox 510
foreach ($v in (-5), 0, 5, 10, 15) { Txt "$v" ($ox - 42) ($oyB - $v * $uyB - 12) 18 $ink $false; Line ([Drawing.Color]::FromArgb(236, 240, 245)) 1 $ox ($oyB - $v * $uyB) 820 ($oyB - $v * $uyB) $false }
foreach ($w in 1..7) { TxtC "$w" ($ox + $w * $ux) ($oyB + 6 + 0) 18 $ink $false }
$ap = @(0, 4, 6, 8, 10, 9, 8, 6); $mp = @(0, 0, 8, 12, 16, 5, 3, (-6))
$apPts = @(); foreach ($w in 1..7) { $apPts += ,@(($ox + $w * $ux), ($oyB - $ap[$w] * $uyB)) }
$mpPts = @(); foreach ($w in 2..7) { $mpPts += ,@(($ox + $w * $ux), ($oyB - $mp[$w] * $uyB)) }
Curve $green 4 $apPts; Curve $red 4 $mpPts
foreach ($q in $apPts) { Dot $green $q[0] $q[1] 6 }; foreach ($q in $mpPts) { Dot $red $q[0] $q[1] 6 }
Txt 'AP' ($apPts[6][0] + 12) ($apPts[6][1] - 24) 22 $green $true; Txt 'MP' ($mpPts[5][0] + 10) ($mpPts[5][1] - 10) 22 $red $true
TxtC 'Number of workers' 480 ($oyB + 92) 20 $ink $true; TxtV 'Output (kg)' 28 650 20 $ink
TxtC 'Average product (AP) and marginal product (MP)' 480 478 22 $ink $true
Save 'eco-tpapmp.png'

# ---------- Economics Term 3 figures ----------
function Pl($c, $w, $pts) { $pn = PenOf $c $w; $a = @(); foreach ($q in $pts) { $a += New-Object Drawing.PointF ([single]$q[0]), ([single]$q[1]) }; $script:g.DrawLines($pn, [Drawing.PointF[]]$a); $pn.Dispose() }
function PlD($c, $w, $pts) { $pn = PenOf $c $w; $pn.DashStyle = 'Dot'; $a = @(); foreach ($q in $pts) { $a += New-Object Drawing.PointF ([single]$q[0]), ([single]$q[1]) }; $script:g.DrawLines($pn, [Drawing.PointF[]]$a); $pn.Dispose() }
function Fn-AC($q) { 30 + 3 * [math]::Pow(($q - 5), 2) }
function Fn-MC($q) { 30 + 3 * [math]::Pow(($q - 5), 2) + 6 * $q * ($q - 5) }
$pale = [Drawing.Color]::FromArgb(236, 240, 245)

# cost curves
Canvas 800 620
$ox = 100; $oy = 540; $ux = 70; $uyc = 3.3
Arrow $ink 2.5 $ox $oy 760 $oy; Arrow $ink 2.5 $ox $oy $ox 50
TxtC 'Output (Q)' 430 ($oy + 30) 22 $ink $true; TxtV 'Cost per unit (N)' 36 300 22 $ink
$ac = @(); for ($q = 1.2; $q -le 8.3; $q += 0.1) { $ac += ,@(($ox + $q * $ux), ($oy - (Fn-AC $q) * $uyc)) }
$mc = @(); for ($q = 0.7; $q -le 6.8; $q += 0.1) { $mc += ,@(($ox + $q * $ux), ($oy - (Fn-MC $q) * $uyc)) }
Pl $blue 4 $ac; Pl $orange 4 $mc
Line $ink 1.5 ($ox + 5 * $ux) ($oy - 30 * $uyc) ($ox + 5 * $ux) $oy $true; Line $ink 1.5 $ox ($oy - 30 * $uyc) ($ox + 5 * $ux) ($oy - 30 * $uyc) $true
Dot $red ($ox + 5 * $ux) ($oy - 30 * $uyc) 8
Txt 'AC' ($ac[$ac.Count - 1][0] + 8) ($ac[$ac.Count - 1][1] - 14) 26 $blue $true; Txt 'MC' ($mc[$mc.Count - 1][0] + 8) ($mc[$mc.Count - 1][1] - 10) 26 $orange $true
TxtC 'Lowest AC: MC cuts AC here' ($ox + 5 * $ux + 80) ($oy - 30 * $uyc + 14) 20 $red $true
TxtC 'U-shaped AC and MC curves' 430 8 24 $ink $true
Save 'eco-cost-curves.png'

# revenue curves (two panels)
Canvas 1040 560
$oy = 380; $uyr = 5
foreach ($panel in 0, 1) {
  $ox = 80 + $panel * 520
  Arrow $ink 2.5 $ox $oy ($ox + 430) $oy; Arrow $ink 2.5 $ox 470 $ox 70
  Txt 'Price / revenue (N)' ($ox - 40) 44 18 $ink $false; TxtC 'Quantity sold' ($ox + 215) ($oy + 78) 20 $ink $true
  foreach ($v in 0, 20, 40, 60) { Txt "$v" ($ox - 34) ($oy - $v * $uyr - 11) 16 $ink $false; Line $pale 1 $ox ($oy - $v * $uyr) ($ox + 410) ($oy - $v * $uyr) $false }
}
$ox = 80
Pl $blue 4 @(@(($ox + 20), ($oy - 50 * $uyr)), @(($ox + 400), ($oy - 50 * $uyr)))
Txt 'AR = MR = D = price' ($ox + 190) ($oy - 50 * $uyr - 34) 20 $blue $true
TxtC 'Perfect competition' ($ox + 215) 14 24 $ink $true
$ox = 600
$arp = @(); for ($q = 0; $q -le 12; $q += 0.5) { $arp += ,@(($ox + $q * 32), ($oy - (60 - 4 * $q) * $uyr)) }
$mrp = @(); for ($q = 0; $q -le 9; $q += 0.5) { $mrp += ,@(($ox + $q * 32), ($oy - (60 - 8 * $q) * $uyr)) }
Pl $blue 4 $arp; Pl $red 4 $mrp
Txt 'AR (= D)' ($arp[$arp.Count - 1][0] - 70) ($arp[$arp.Count - 1][1] + 16) 20 $blue $true; Txt 'MR' ($mrp[$mrp.Count - 1][0] + 10) ($mrp[$mrp.Count - 1][1] - 10) 20 $red $true
TxtC 'Imperfect competition' ($ox + 215) 14 24 $ink $true
Save 'eco-revenue-curves.png'

# utility curves
Canvas 1040 520
$oy = 400
foreach ($panel in 0, 1) {
  $ox = 90 + $panel * 520
  Arrow $ink 2.5 $ox $oy ($ox + 420) $oy; Arrow $ink 2.5 $ox $oy $ox 60
  TxtC 'Units consumed' ($ox + 210) ($oy + 40) 20 $ink $true
  foreach ($j in 1..7) { TxtC "$j" ($ox + $j * 55) ($oy + 6) 16 $ink $false }
}
$ox = 90; $uyu = 10.5
foreach ($v in 0, 10, 20, 30) { Txt "$v" ($ox - 34) ($oy - $v * $uyu - 11) 16 $ink $false; Line $pale 1 $ox ($oy - $v * $uyu) ($ox + 400) ($oy - $v * $uyu) $false }
TxtV 'Total utility' 30 230 20 $ink
$tu = @(0, 10, 18, 24, 28, 30, 31, 31); $pts = @(); foreach ($j in 0..7) { $pts += ,@(($ox + $j * 55), ($oy - $tu[$j] * $uyu)) }
Curve $blue 4 $pts; foreach ($q in $pts) { Dot $orange $q[0] $q[1] 6 }
TxtC 'Total utility (TU)' ($ox + 210) 14 24 $ink $true
$ox = 610; $uym = 26
foreach ($v in 0, 5, 10) { Txt "$v" ($ox - 34) ($oy - $v * $uym - 11) 16 $ink $false; Line $pale 1 $ox ($oy - $v * $uym) ($ox + 400) ($oy - $v * $uym) $false }
TxtV 'Marginal utility' 550 230 20 $ink
$mu = @(0, 10, 8, 6, 4, 2, 1, 0); $pts = @(); foreach ($j in 1..7) { $pts += ,@(($ox + $j * 55), ($oy - $mu[$j] * $uym)) }
Curve $red 4 $pts; foreach ($q in $pts) { Dot $orange $q[0] $q[1] 6 }
TxtC 'Marginal utility (MU)' ($ox + 210) 14 24 $ink $true
Save 'eco-utility.png'

# indifference curves
Canvas 760 640
$ox = 100; $oy = 560; $ux = 40; $uyi = 31
Arrow $ink 2.5 $ox $oy 730 $oy; Arrow $ink 2.5 $ox $oy $ox 40
TxtC 'Bottles of drink' 420 ($oy + 34) 22 $ink $true; TxtV 'Packets of biscuits' 34 300 22 $ink
foreach ($v in 2, 4, 6, 8, 10, 12) { TxtC "$v" ($ox + $v * $ux) ($oy + 6) 16 $ink $false; Txt "$v" ($ox - 34) ($oy - $v * $uyi - 11) 16 $ink $false }
$i1 = @(); for ($x = 1.4; $x -le 12.5; $x += 0.2) { $i1 += ,@(($ox + $x * $ux), ($oy - (16 / $x) * $uyi)) }
$i2 = @(); for ($x = 2.9; $x -le 13.6; $x += 0.2) { $i2 += ,@(($ox + $x * $ux), ($oy - (36 / $x) * $uyi)) }
Pl $blue 4 $i1; Pl $green 4 $i2
foreach ($pt in @(@(8, 2), @(4, 4), @(2, 8))) { Dot $orange ($ox + $pt[0] * $ux) ($oy - $pt[1] * $uyi) 7; Txt "($($pt[0]), $($pt[1]))" ($ox + $pt[0] * $ux + 10) ($oy - $pt[1] * $uyi - 28) 18 $ink $true }
Txt 'IC1' ($i1[$i1.Count - 1][0] - 6) ($i1[$i1.Count - 1][1] - 30) 24 $blue $true; Txt 'IC2' ($i2[$i2.Count - 1][0] - 40) ($i2[$i2.Count - 1][1] - 30) 24 $green $true
TxtC 'Indifference curves' 420 6 24 $ink $true
Save 'eco-indifference.png'

# equilibrium graph: Qd = 120 - 4P, Qs = 4P
Canvas 900 680
$ox = 110; $oy = 580; $uxq = 6.2; $uyp = 17.5
Arrow $ink 2.5 $ox $oy 830 $oy; Arrow $ink 2.5 $ox $oy $ox 40
TxtC 'Quantity (kg)' 470 ($oy + 38) 22 $ink $true; TxtV 'Price (N)' 38 300 22 $ink
foreach ($v in 20, 40, 60, 80, 100, 120) { TxtC "$v" ($ox + $v * $uxq) ($oy + 6) 16 $ink $false }
foreach ($v in 5, 10, 15, 20, 25, 30) { Txt "$v" ($ox - 38) ($oy - $v * $uyp - 11) 16 $ink $false; Line $pale 1 $ox ($oy - $v * $uyp) ($ox + 120 * $uxq) ($oy - $v * $uyp) $false }
Pl $blue 4 @(@(($ox + 8 * $uxq), ($oy - 28 * $uyp)), @(($ox + 108 * $uxq), ($oy - 3 * $uyp)))
Pl $orange 4 @(@(($ox + 12 * $uxq), ($oy - 3 * $uyp)), @(($ox + 112 * $uxq), ($oy - 28 * $uyp)))
Txt 'D' ($ox + 108 * $uxq + 8) ($oy - 3 * $uyp - 34) 26 $blue $true; Txt 'S' ($ox + 112 * $uxq + 8) ($oy - 28 * $uyp - 12) 26 $orange $true
Line $ink 1.5 $ox ($oy - 15 * $uyp) ($ox + 60 * $uxq) ($oy - 15 * $uyp) $true; Line $ink 1.5 ($ox + 60 * $uxq) ($oy - 15 * $uyp) ($ox + 60 * $uxq) $oy $true
Dot $red ($ox + 60 * $uxq) ($oy - 15 * $uyp) 9
Txt 'Equilibrium:' ($ox + 75 * $uxq) ($oy - 17.2 * $uyp) 20 $red $true; Txt 'price N15, 60 kg' ($ox + 75 * $uxq) ($oy - 17.2 * $uyp + 24) 20 $red $true
Line $green 3 ($ox + 20 * $uxq) ($oy - 25 * $uyp) ($ox + 100 * $uxq) ($oy - 25 * $uyp) $true
TxtC 'At N25: excess supply (80 kg)' ($ox + 60 * $uxq) ($oy - 25 * $uyp - 28) 18 $green $true
Line $green 3 ($ox + 20 * $uxq) ($oy - 5 * $uyp) ($ox + 100 * $uxq) ($oy - 5 * $uyp) $true
TxtC 'At N5: excess demand (80 kg)' ($ox + 82 * $uxq) ($oy - 5 * $uyp + 8) 18 $green $true
TxtC 'Equilibrium of the yam market' 470 6 24 $ink $true
Save 'eco-equilibrium.png'

# four shifts
Canvas 1040 870
function Panel($px, $py, $title, $res, $dShift, $sShift) {
  $w = 400; $h = 300
  Arrow $ink 2 $px ($py + $h) ($px + $w) ($py + $h); Arrow $ink 2 $px ($py + $h) $px $py
  Txt 'Price' ($px + 8) ($py - 2) 16 $ink $false; Txt 'Quantity' ($px + $w - 70) ($py + $h + 4) 16 $ink $false
  TxtC $title ($px + $w / 2) ($py - 38) 22 $ink $true
  $d0 = @(@(($px + 90), ($py + 40)), @(($px + 320), ($py + 260))); $s0 = @(@(($px + 90), ($py + 260)), @(($px + 320), ($py + 40)))
  PlD $blue 3 $d0; PlD $orange 3 $s0
  $d1 = @(@(($px + 90 + $dShift), ($py + 40)), @(($px + 320 + $dShift), ($py + 260))); $s1 = @(@(($px + 90 + $sShift), ($py + 260)), @(($px + 320 + $sShift), ($py + 40)))
  if ($dShift -ne 0) { Pl $blue 4 $d1 } else { Pl $blue 4 $d0 }
  if ($sShift -ne 0) { Pl $orange 4 $s1 } else { Pl $orange 4 $s0 }
  Dot $grey ($px + 205) ($py + 150) 7
  $nx = $px + 205 + ($dShift + $sShift) / 2; $ny = $py + 150 - ($dShift - $sShift) * 0.4785
  Dot $red $nx $ny 8
  Txt 'D' ($px + 326 + $dShift) ($py + 250) 18 $blue $true; Txt 'S' ($px + 326 + $sShift) ($py + 24) 18 $orange $true
  TxtC $res ($px + $w / 2) ($py + $h + 30) 18 $red $true
}
Panel 70 70 'Demand increases' 'Price rises, quantity rises' 70 0
Panel 570 70 'Demand decreases' 'Price falls, quantity falls' (-70) 0
Panel 70 480 'Supply increases' 'Price falls, quantity rises' 0 (-70)
Panel 570 480 'Supply decreases' 'Price rises, quantity falls' 0 70
Save 'eco-shifts.png'

# market structure
Canvas 1040 560
$cols = @(
 @('Monopoly', [Drawing.Color]::FromArgb(245, 158, 11), 'One seller', 'Unique product,', 'no close substitute', 'Entry blocked', 'Public water supply'),
 @('Oligopoly', [Drawing.Color]::FromArgb(16, 185, 129), 'A few large sellers', 'Identical or branded', '', 'Entry difficult', 'Telecoms, cement'),
 @('Monopolistic', [Drawing.Color]::FromArgb(59, 130, 246), 'Many sellers', 'Similar but branded', '', 'Entry easy', 'Restaurants, salons'),
 @('Perfect', [Drawing.Color]::FromArgb(139, 92, 246), 'Very many sellers', 'Identical goods', '', 'Free entry and exit', 'Local vegetable market'))
$cols[2][0] = 'Monopolistic'
$x = 20
TxtC 'Market structures compared' 520 6 26 $ink $true
for ($i = 0; $i -lt 4; $i++) {
  $c = $cols[$i]; $cx = $x + $i * 255
  $b = New-Object Drawing.SolidBrush $c[1]; $script:g.FillRectangle($b, [single]$cx, 50, 235, 70); $b.Dispose()
  $title = $c[0]; $sub = ''
  if ($i -eq 2) { $title = 'Monopolistic'; $sub = 'competition' } elseif ($i -eq 3) { $title = 'Perfect'; $sub = 'competition' }
  TxtC $title ($cx + 117) 58 24 ([Drawing.Color]::White) $true; if ($sub) { TxtC $sub ($cx + 117) 86 24 ([Drawing.Color]::White) $true }
  $bg = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(243, 246, 250)); $script:g.FillRectangle($bg, [single]$cx, 120, 235, 400); $bg.Dispose()
  $labels = 'SELLERS', 'PRODUCT', 'ENTRY', 'EXAMPLE'
  Txt 'Sellers' ($cx + 14) 140 18 $light $true; TxtC $c[2] ($cx + 117) 168 20 $ink $true
  Txt 'Product' ($cx + 14) 230 18 $light $true; TxtC $c[3] ($cx + 117) 258 20 $ink $true; if ($c[4]) { TxtC $c[4] ($cx + 117) 282 20 $ink $true }
  Txt 'Entry' ($cx + 14) 340 18 $light $true; TxtC $c[5] ($cx + 117) 368 20 $ink $true
  Txt 'Example' ($cx + 14) 430 18 $light $true; TxtC $c[6] ($cx + 117) 458 18 $ink $true
}
Save 'eco-market-structure.png'

# monopoly graph
Canvas 860 680
$ox = 100; $oy = 600; $uxm = 60; $uym2 = 5.4
Arrow $ink 2.5 $ox $oy 820 $oy; Arrow $ink 2.5 $ox $oy $ox 40
TxtC 'Quantity' 460 ($oy + 34) 22 $ink $true; TxtV 'Price, cost and revenue' 34 320 22 $ink
$qs = 3.958; $pr = 90 - 7 * $qs; $acq = 25 + 2.5 * [math]::Pow(($qs - 3.5), 2)
$rect = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(110, 120, 220, 230))
$script:g.FillRectangle($rect, [single]$ox, [single]($oy - $pr * $uym2), [single]($qs * $uxm), [single](($pr - $acq) * $uym2)); $rect.Dispose()
$ar = @(); for ($q = 0; $q -le 11; $q += 0.5) { $ar += ,@(($ox + $q * $uxm), ($oy - (90 - 7 * $q) * $uym2)) }
$mr = @(); for ($q = 0; $q -le 6.4; $q += 0.4) { $mr += ,@(($ox + $q * $uxm), ($oy - (90 - 14 * $q) * $uym2)) }
$acp = @(); for ($q = 0.9; $q -le 8; $q += 0.2) { $acp += ,@(($ox + $q * $uxm), ($oy - (25 + 2.5 * [math]::Pow(($q - 3.5), 2)) * $uym2)) }
$mcp = @(); for ($q = 0.3; $q -le 5.6; $q += 0.1) { $mcp += ,@(($ox + $q * $uxm), ($oy - (25 + 2.5 * [math]::Pow(($q - 3.5), 2) + 5 * $q * ($q - 3.5)) * $uym2)) }
Pl $blue 4 $ar; Pl $red 4 $mr; Pl $green 4 $acp; Pl $orange 4 $mcp
Line $ink 1.5 ($ox + $qs * $uxm) ($oy - $pr * $uym2) ($ox + $qs * $uxm) $oy $true
Dot $ink ($ox + $qs * $uxm) ($oy - (90 - 14 * $qs) * $uym2) 7; Dot $blue ($ox + $qs * $uxm) ($oy - $pr * $uym2) 7; Dot $green ($ox + $qs * $uxm) ($oy - $acq * $uym2) 7
Txt 'AR (demand)' ($ar[$ar.Count - 1][0] - 110) ($ar[$ar.Count - 1][1] + 16) 20 $blue $true; Txt 'MR' ($mr[$mr.Count - 1][0] + 10) ($mr[$mr.Count - 1][1] - 4) 22 $red $true
Txt 'AC' ($acp[$acp.Count - 1][0] + 8) ($acp[$acp.Count - 1][1] - 12) 22 $green $true; Txt 'MC' ($mcp[$mcp.Count - 1][0] + 8) ($mcp[$mcp.Count - 1][1] - 12) 22 $orange $true
TxtC 'Q*' ($ox + $qs * $uxm) ($oy + 6) 20 $ink $true
Txt 'Supernormal' ($ox + 8) ($oy - 57.5 * $uym2) 20 $ink $true; Txt 'profit' ($ox + 8) ($oy - 57.5 * $uym2 + 22) 20 $ink $true
Txt 'P' ($ox - 28) ($oy - $pr * $uym2 - 12) 20 $blue $true
TxtC 'Monopoly: output where MC = MR, price from AR' 460 6 24 $ink $true
Save 'eco-monopoly.png'

# perfect competition: short run and long run
Canvas 1160 600
$oy = 520; $ucx = 64; $ucy = 5.6
foreach ($panel in 0, 1) {
  $ox = 90 + $panel * 560
  Arrow $ink 2.5 $ox $oy ($ox + 440) $oy; Arrow $ink 2.5 $ox $oy $ox 80
  TxtC 'Quantity' ($ox + 220) ($oy + 30) 20 $ink $true; TxtV 'Price and cost' ($ox - 58) 300 20 $ink
  $acp = @(); for ($q = 1.8; $q -le 8; $q += 0.2) { $acp += ,@(($ox + $q * $ucx), ($oy - (30 + 3 * [math]::Pow(($q - 5), 2)) * $ucy)) }
  $mcp = @(); for ($q = 1.0; $q -le 6.8; $q += 0.1) { $mcp += ,@(($ox + $q * $ucx), ($oy - (30 + 3 * [math]::Pow(($q - 5), 2) + 6 * $q * ($q - 5)) * $ucy)) }
  if ($panel -eq 0) {
    $rect = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(110, 120, 220, 230))
    $script:g.FillRectangle($rect, [single]$ox, [single]($oy - 60 * $ucy), [single](5.81 * $ucx), [single](28 * $ucy)); $rect.Dispose()
  }
  Pl $green 4 $acp; Pl $orange 4 $mcp
  Txt 'AC' ($acp[$acp.Count - 1][0] + 8) ($acp[$acp.Count - 1][1] - 12) 22 $green $true; Txt 'MC' ($mcp[$mcp.Count - 1][0] + 8) ($mcp[$mcp.Count - 1][1] - 12) 22 $orange $true
}
$ox = 90
Line $blue 4 $ox ($oy - 60 * $ucy) ($ox + 430) ($oy - 60 * $ucy) $false
Txt 'Blue line: P = AR = MR = D' ($ox + 8) 56 20 $blue $true
Line $ink 1.5 ($ox + 5.81 * $ucx) ($oy - 60 * $ucy) ($ox + 5.81 * $ucx) $oy $true
Dot $red ($ox + 5.81 * $ucx) ($oy - 60 * $ucy) 7
Txt 'Supernormal' ($ox + 20) ($oy - 46 * $ucy - 14) 20 $ink $true; Txt 'profit' ($ox + 20) ($oy - 46 * $ucy + 8) 20 $ink $true
TxtC 'Short run' ($ox + 220) 24 24 $ink $true
$ox = 650
Line $blue 4 $ox ($oy - 30 * $ucy) ($ox + 430) ($oy - 30 * $ucy) $false
Txt 'Blue line: P = AR = MR = D' ($ox + 8) 56 20 $blue $true
Line $ink 1.5 ($ox + 5 * $ucx) ($oy - 30 * $ucy) ($ox + 5 * $ucx) $oy $true
Dot $red ($ox + 5 * $ucx) ($oy - 30 * $ucy) 8
Txt 'Normal profit only' ($ox + 8) ($oy - 72 * $ucy) 20 $ink $true; Txt '(P = lowest AC)' ($ox + 8) ($oy - 72 * $ucy + 22) 20 $ink $true
TxtC 'Long run' ($ox + 220) 24 24 $ink $true
Save 'eco-perfect-comp.png'

# ---------- Chemistry Term 1 figures ----------
$white = [Drawing.Color]::White
$glass = [Drawing.Color]::FromArgb(70, 125, 211, 252); $liq = [Drawing.Color]::FromArgb(150, 56, 189, 248); $liqOr = [Drawing.Color]::FromArgb(200, 251, 191, 36)
function GlassOut($pts) { $pn = PenOf $ink 3; $a = @(); foreach ($q in $pts) { $a += New-Object Drawing.PointF ([single]$q[0]), ([single]$q[1]) }; $script:g.DrawLines($pn, [Drawing.PointF[]]$a); $pn.Dispose() }
function RectF($c, $x, $y, $w, $h) { $b = New-Object Drawing.SolidBrush $c; $script:g.FillRectangle($b, [single]$x, [single]$y, [single]$w, [single]$h); $b.Dispose() }
function PieF($c, $x, $y, $w, $h, $a1, $a2) { $b = New-Object Drawing.SolidBrush $c; $script:g.FillPie($b, [single]$x, [single]$y, [single]$w, [single]$h, [single]$a1, [single]$a2); $b.Dispose() }
function ArcP($x, $y, $w, $h, $a1, $a2) { $pn = PenOf $ink 3; $script:g.DrawArc($pn, [single]$x, [single]$y, [single]$w, [single]$h, [single]$a1, [single]$a2); $pn.Dispose() }

Canvas 1100 600
TxtC 'Common laboratory apparatus' 550 8 26 $ink $true
$by = 250
$cx = 150
RectF $liq ($cx - 50) ($by - 70) 100 70
GlassOut @(@(($cx - 56), ($by - 124)), @(($cx - 50), ($by - 120)), @(($cx - 50), $by), @(($cx + 50), $by), @(($cx + 50), ($by - 120)))
foreach ($m in 30, 60, 90) { Line $ink 2 ($cx + 50) ($by - $m) ($cx + 34) ($by - $m) $false }
TxtC 'Beaker' $cx ($by + 14) 22 $ink $true
$cx = 400
FillPoly $liq @(@(($cx - 45), ($by - 45)), @(($cx + 45), ($by - 45)), @(($cx + 70), $by), @(($cx - 70), $by))
GlassOut @(@(($cx - 15), ($by - 150)), @(($cx - 15), ($by - 100)), @(($cx - 70), $by), @(($cx + 70), $by), @(($cx + 15), ($by - 100)), @(($cx + 15), ($by - 150)))
Line $ink 3 ($cx - 20) ($by - 150) ($cx + 20) ($by - 150) $false
TxtC 'Conical flask' $cx ($by + 14) 22 $ink $true
$cx = 640
RectF $liq ($cx - 17) ($by - 100) 34 82
PieF $liq ($cx - 17) ($by - 35) 34 34 0 180
GlassOut @(@(($cx - 18), ($by - 170)), @(($cx - 18), ($by - 18)))
GlassOut @(@(($cx + 18), ($by - 170)), @(($cx + 18), ($by - 18)))
ArcP ($cx - 18) ($by - 36) 36 36 0 180
TxtC 'Test tube' $cx ($by + 14) 22 $ink $true
$cx = 900
PieF $liq ($cx - 58) ($by - 118) 116 116 0 180
Ellip $ink 3 $cx ($by - 60) 60 60 $false
RectF $white ($cx - 14) ($by - 124) 28 12
GlassOut @(@(($cx - 15), ($by - 170)), @(($cx - 15), ($by - 112)))
GlassOut @(@(($cx + 15), ($by - 170)), @(($cx + 15), ($by - 112)))
TxtC 'Round-bottomed flask' $cx ($by + 14) 22 $ink $true
$by = 520
$cx = 150
RectF $liq ($cx - 22) ($by - 90) 44 80
GlassOut @(@(($cx - 22), ($by - 175)), @(($cx - 22), ($by - 10)), @(($cx + 22), ($by - 10)), @(($cx + 22), ($by - 175)))
Ellip $ink 3 $cx ($by - 4) 40 6 $false
foreach ($m in 1..7) { Line $ink 2 ($cx - 22) ($by - 10 - $m * 22) ($cx - 8) ($by - 10 - $m * 22) $false }
TxtC 'Measuring cylinder' $cx ($by + 14) 22 $ink $true
$cx = 400
RectF $grey ($cx - 60) ($by - 8) 120 10
Line $ink 5 ($cx - 44) ($by - 8) ($cx - 44) ($by - 190) $false
Line $ink 4 ($cx - 44) ($by - 140) ($cx - 8) ($by - 140) $false
RectF $liq ($cx - 7) ($by - 170) 14 130
GlassOut @(@(($cx - 8), ($by - 190)), @(($cx - 8), ($by - 40)), @(($cx - 3), ($by - 12)))
GlassOut @(@(($cx + 8), ($by - 190)), @(($cx + 8), ($by - 40)), @(($cx + 3), ($by - 12)))
RectF $ink ($cx - 18) ($by - 46) 36 6
foreach ($m in 1..8) { Line $ink 2 ($cx + 8) ($by - 40 - $m * 16) ($cx + 18) ($by - 40 - $m * 16) $false }
TxtC 'Burette and stand' $cx ($by + 14) 22 $ink $true
$cx = 640
FillPoly $liq @(@(($cx - 18), ($by - 110)), @(($cx + 18), ($by - 110)), @(($cx + 18), ($by - 80)), @(($cx + 4), ($by - 60)), @(($cx + 4), ($by - 12)), @(($cx - 4), ($by - 12)), @(($cx - 4), ($by - 60)), @(($cx - 18), ($by - 80)))
GlassOut @(@(($cx - 4), ($by - 190)), @(($cx - 4), ($by - 140)), @(($cx - 18), ($by - 120)), @(($cx - 18), ($by - 80)), @(($cx - 4), ($by - 60)), @(($cx - 4), ($by - 12)), @($cx, ($by - 2)))
GlassOut @(@(($cx + 4), ($by - 190)), @(($cx + 4), ($by - 140)), @(($cx + 18), ($by - 120)), @(($cx + 18), ($by - 80)), @(($cx + 4), ($by - 60)), @(($cx + 4), ($by - 12)), @($cx, ($by - 2)))
Line $ink 2 ($cx - 8) ($by - 165) ($cx + 8) ($by - 165) $false
TxtC 'Pipette' $cx ($by + 14) 22 $ink $true
$cx = 900
FillPoly $liqOr @(@(($cx - 14), ($by - 92)), @(($cx), ($by - 160)), @(($cx + 14), ($by - 92)))
RectF $ink ($cx - 10) ($by - 90) 20 80
RectF $white ($cx - 5) ($by - 40) 10 14
Ellip $ink 3 $cx ($by - 8) 44 8 $false
RectF $ink ($cx - 44) ($by - 10) 88 8
TxtC 'Bunsen burner' $cx ($by + 14) 22 $ink $true
Save 'chem-apparatus.png'

# changes of state
Canvas 860 470
TxtC 'Changes of state' 430 6 26 $ink $true
$rnd = New-Object System.Random 7
$bx = 30, 330, 630
$names = 'SOLID', 'LIQUID', 'GAS'
for ($i = 0; $i -lt 3; $i++) {
  RectF ([Drawing.Color]::FromArgb(243, 246, 250)) $bx[$i] 70 200 200
  $pn = PenOf $ink 2; $script:g.DrawRectangle($pn, [single]$bx[$i], 70, 200, 200); $pn.Dispose()
  TxtC $names[$i] ($bx[$i] + 100) 276 22 $ink $true
}
foreach ($r in 0..4) { foreach ($c in 0..4) { Dot $blue (50 + $c * 36) (90 + $r * 36) 13 } }
$lp = @(@(355, 110), @(395, 100), @(440, 120), @(375, 150), @(420, 160), @(470, 150), @(355, 195), @(400, 205), @(445, 210), @(485, 190), @(380, 245), @(430, 250), @(475, 238))
foreach ($q in $lp) { Dot $orange ($q[0] + 0) $q[1] 13 }
$gp = @(@(660, 100), @(740, 120), @(690, 170), @(780, 100), @(720, 225), @(660, 245), @(790, 190))
foreach ($q in $gp) { Dot $green $q[0] $q[1] 11 }
$dgs = @(@(30, 'Melting', 'Freezing', 1), @(330, 'Vaporisation', 'Condensation', 1))
foreach ($d in $dgs) {
  $x1 = $d[0] + 205; $x2 = $d[0] + 295
  Arrow $red 3 $x1 130 $x2 130; Arrow $blue 3 $x2 200 $x1 200
  TxtC $d[1] (($x1 + $x2) / 2) 104 16 $red $true; TxtC $d[2] (($x1 + $x2) / 2) 208 16 $blue $true
}
Arrow $red 3 130 330 730 330; Arrow $blue 3 730 400 130 400
TxtC 'Sublimation (solid to gas, heat taken in)' 430 298 20 $red $true
TxtC 'Deposition (gas to solid, heat given out)' 430 408 20 $blue $true
TxtC 'Red arrows: heat taken in.  Blue arrows: heat given out.' 430 440 18 $light $false
Save 'chem-change-of-state.png'

# filtration
Canvas 720 600
TxtC 'Filtration' 360 6 26 $ink $true
$cx = 360
FillPoly $liq @(@(($cx - 96), 175), @(($cx + 96), 175), @(($cx + 4), 262), @(($cx - 4), 262))
foreach ($q in @(@(-70, 190), @(-40, 205), @(-10, 190), @(20, 207), @(50, 192), @(-25, 232), @(15, 238), @(0, 252))) { Dot ([Drawing.Color]::FromArgb(150, 90, 60, 30)) ($cx + $q[0]) $q[1] 5 }
GlassOut @(@(($cx - 120), 120), @(($cx - 14), 262), @(($cx - 14), 330))
GlassOut @(@(($cx + 120), 120), @(($cx + 14), 262), @(($cx + 14), 330))
Line $orange 4 ($cx - 108) 128 $cx 258 $false
Line $orange 4 ($cx + 108) 128 $cx 258 $false
Line $ink 3 ($cx - 126) 120 ($cx + 126) 120 $false
foreach ($y in 345, 385) { Dot $blue $cx $y 5 }
RectF $liq ($cx - 70) 470 140 64
GlassOut @(@(($cx - 70), 400), @(($cx - 70), 536), @(($cx + 70), 536), @(($cx + 70), 400))
Txt 'Funnel' ($cx + 140) 135 20 $ink $true; Line $ink 1.5 ($cx + 138) 148 ($cx + 100) 150 $false
Txt 'Filter paper' ($cx + 140) 195 20 $ink $true; Line $ink 1.5 ($cx + 138) 208 ($cx + 70) 205 $false
Txt 'Residue stays on the paper' 20 285 20 $ink $true; Line $ink 1.5 280 296 ($cx - 8) 250 $false
Txt 'Filtrate (clear liquid)' ($cx + 90) 485 20 $ink $true; Line $ink 1.5 ($cx + 88) 500 ($cx + 50) 500 $false
Txt 'Beaker' ($cx - 160) 470 20 $ink $true
Txt 'Mixture of insoluble solid and liquid' ($cx - 240) 80 20 $ink $true; Arrow $ink 2 $cx 106 $cx 160
Save 'chem-filtration.png'

# pH scale
Canvas 1100 480
TxtC 'The pH scale' 550 6 26 $ink $true
$pc = @(@(229, 57, 53), @(239, 83, 60), @(244, 121, 53), @(248, 160, 46), @(250, 200, 48), @(230, 225, 60), @(170, 210, 70), @(100, 190, 90), @(60, 180, 140), @(40, 160, 190), @(50, 130, 210), @(70, 100, 200), @(95, 80, 190), @(120, 60, 170), @(140, 50, 150))
for ($i = 0; $i -le 14; $i++) {
  $c = [Drawing.Color]::FromArgb($pc[$i][0], $pc[$i][1], $pc[$i][2]); RectF $c (60 + $i * 65) 200 65 60
  TxtC "$i" (60 + $i * 65 + 32) 218 24 $white $true
}
TxtC 'ACIDIC' 190 270 22 $red $true; TxtC 'NEUTRAL' 515 270 22 $green $true; TxtC 'ALKALINE' 840 270 22 $blue $true
$ex = @(@(0, 'Battery acid', 1), @(2, 'Lemon juice', 0), @(3, 'Vinegar', 1), @(4.5, 'Tomato', 0), @(7, 'Pure water', 1), @(8.5, 'Baking soda', 0), @(10, 'Soap', 1), @(11.5, 'Ammonia', 0), @(13, 'Bleach', 1))
foreach ($e in $ex) {
  $x = 60 + $e[0] * 65 + 32
  if ($e[2] -eq 1) { Line $ink 1.5 $x 262 $x 330 $false; TxtC $e[1] $x 336 20 $ink $true } else { Line $ink 1.5 $x 198 $x 130 $false; TxtC $e[1] $x 100 20 $ink $true }
}
TxtC 'pH below 7 = acid     pH 7 = neutral     pH above 7 = alkali' 550 420 22 $ink $false
Save 'chem-ph-scale.png'

# combining volumes
Canvas 920 470
$sb2 = [string][char]0x2082
TxtC "Volumes of gases that combine are in simple whole-number ratios" 460 6 24 $ink $true
function VBox($x, $baseY, $units, $c, $lab) { RectF $c $x ($baseY - $units * 60) 110 ($units * 60); $pn = PenOf $ink 2.5; $script:g.DrawRectangle($pn, [single]$x, [single]($baseY - $units * 60), 110, [single]($units * 60)); $pn.Dispose(); TxtC $lab ($x + 55) ($baseY - $units * 30 - 14) 22 $ink $true; TxtC ("$units volume" + $(if ($units -gt 1) { 's' } else { '' })) ($x + 55) ($baseY + 8) 18 $ink $false }
$cH = [Drawing.Color]::FromArgb(191, 219, 254); $cO = [Drawing.Color]::FromArgb(254, 202, 202); $cS = [Drawing.Color]::FromArgb(226, 232, 240); $cCl = [Drawing.Color]::FromArgb(187, 247, 208); $cHCl = [Drawing.Color]::FromArgb(254, 240, 138)
$bs = 180
VBox 80 $bs 2 $cH ("H$sb2"); Txt '+' 215 ($bs - 90) 36 $ink $true; VBox 270 $bs 1 $cO ("O$sb2"); Txt ([string][char]0x2192) 410 ($bs - 90) 40 $ink $true; VBox 500 $bs 2 $cS ("H$sb2" + 'O')
Txt "Ratio 2 : 1 : 2" 680 ($bs - 70) 26 $red $true
$bs = 400
VBox 80 $bs 1 $cH ("H$sb2"); Txt '+' 215 ($bs - 55) 36 $ink $true; VBox 270 $bs 1 $cCl ("Cl$sb2"); Txt ([string][char]0x2192) 410 ($bs - 90) 40 $ink $true; VBox 500 $bs 2 $cHCl 'HCl'
Txt "Ratio 1 : 1 : 2" 680 ($bs - 70) 26 $red $true
Save 'chem-gay-lussac.png'

# balancing an equation
Canvas 1000 600
$sb2 = [string][char]0x2082; $arr = [string][char]0x2192
function AtH($x, $y) { Dot $white $x $y 14; Ellip $ink 2 $x $y 14 14 $false }
function AtO($x, $y) { Dot ([Drawing.Color]::FromArgb(248, 113, 113)) $x $y 22; Ellip $ink 2 $x $y 22 22 $false }
function MolH2($x, $y) { AtH ($x - 14) $y; AtH ($x + 14) $y }
function MolO2($x, $y) { AtO ($x - 22) $y; AtO ($x + 22) $y }
function MolH2O($x, $y) { AtH ($x - 28) ($y + 24); AtH ($x + 28) ($y + 24); AtO $x $y }
TxtC "Word equation:  hydrogen + oxygen $arr water" 500 8 24 $blue $true
TxtC 'Skeleton equation (not balanced)' 500 56 22 $ink $true
MolH2 150 150; Txt '+' 225 130 36 $ink $true; MolO2 330 150; Txt $arr 440 125 40 $ink $true; MolH2O 580 140
Txt 'Left: H = 2, O = 2' 700 120 20 $ink $false; Txt 'Right: H = 2, O = 1' 700 148 20 $ink $false; Txt 'Not equal' 700 178 22 $red $true
TxtC 'Balanced equation' 500 262 22 $ink $true
MolH2 100 370; MolH2 175 370; Txt '+' 245 350 36 $ink $true; MolO2 340 370; Txt $arr 440 345 40 $ink $true; MolH2O 580 360; MolH2O 690 360
Txt 'Left: H = 4, O = 2' 780 340 20 $ink $false; Txt 'Right: H = 4, O = 2' 780 368 20 $ink $false; Txt 'Equal: balanced' 780 398 22 $green $true
TxtC ("2H$sb2 + O$sb2 $arr 2H$sb2" + "O") 500 470 30 $ink $true
Save 'chem-balancing.png'


# ---------- Chemistry Term 2 figures ----------
$sup2 = [string][char]0xB2; $sup3 = [string][char]0xB3; $dot = [string][char]0xB7; $times = [string][char]0xD7; $div = [string][char]0xF7; $arr = [string][char]0x2192
$boxc = [Drawing.Color]::FromArgb(243, 246, 250)
function BoxL($cx, $cy, $w, $h, $t, $fc) { RectF $fc ($cx - $w / 2) ($cy - $h / 2) $w $h; $pn = PenOf $ink 2.5; $script:g.DrawRectangle($pn, [single]($cx - $w / 2), [single]($cy - $h / 2), [single]$w, [single]$h); $pn.Dispose(); TxtC $t $cx ($cy - 13) 22 $ink $true }

# mole map
Canvas 940 600
TxtC 'The mole links everything' 470 6 26 $ink $true
Dot ([Drawing.Color]::FromArgb(254, 240, 138)) 470 310 70; Ellip $ink 3 470 310 70 70 $false; TxtC 'MOLE' 470 288 28 $ink $true; TxtC '(n)' 470 320 24 $ink $true
BoxL 470 90 300 64 'Mass (g)' ([Drawing.Color]::FromArgb(219, 234, 254))
BoxL 800 310 240 64 'Particles' ([Drawing.Color]::FromArgb(254, 226, 226))
BoxL 470 535 320 64 ("Gas volume (dm$sup3 at STP)") ([Drawing.Color]::FromArgb(209, 250, 229))
BoxL 140 310 240 64 'Solution' ([Drawing.Color]::FromArgb(237, 233, 254))
Arrow $blue 3 455 238 455 126; Arrow $blue 3 485 126 485 238
Txt ("$times molar mass") 500 160 18 $blue $true; Txt ("$div molar mass") 250 160 18 $blue $true
Arrow $red 3 542 295 678 295; Arrow $red 3 678 325 542 325
TxtC ("$times 6.022 $times 10" + [char]0xB2 + [char]0xB3) 610 262 18 $red $true; TxtC ("$div 6.022 $times 10" + [char]0xB2 + [char]0xB3) 610 335 18 $red $true
Arrow $green 3 455 382 455 502; Arrow $green 3 485 502 485 382
Txt ("$times 22.4") 500 430 18 $green $true; Txt ("$div 22.4") 380 430 18 $green $true
Arrow ([Drawing.Color]::FromArgb(109, 40, 217)) 3 398 295 262 295; Arrow ([Drawing.Color]::FromArgb(109, 40, 217)) 3 262 325 398 325
TxtC ("$times conc. $times V") 330 262 18 ([Drawing.Color]::FromArgb(109, 40, 217)) $true; TxtC ("$div conc.") 330 335 18 ([Drawing.Color]::FromArgb(109, 40, 217)) $true
Save 'chem-mole-map.png'

# ethanol pie
Canvas 760 520
TxtC 'Percentage composition of ethanol, C2H6O' 380 6 24 $ink $true
$pcx = 380; $pcy = 280; $pr = 190
$bC = New-Object Drawing.SolidBrush ([Drawing.Color]::FromArgb(75, 85, 99)); $bO = New-Object Drawing.SolidBrush $orange; $bHh = New-Object Drawing.SolidBrush $blue
$script:g.FillPie($bC, [single]($pcx - $pr), [single]($pcy - $pr), [single](2 * $pr), [single](2 * $pr), [single](-90), [single](187.9))
$script:g.FillPie($bO, [single]($pcx - $pr), [single]($pcy - $pr), [single](2 * $pr), [single](2 * $pr), [single](97.9), [single](125.3))
$script:g.FillPie($bHh, [single]($pcx - $pr), [single]($pcy - $pr), [single](2 * $pr), [single](2 * $pr), [single](223.2), [single](46.8))
$bC.Dispose(); $bO.Dispose(); $bHh.Dispose()
foreach ($a in -90, 97.9, 223.2) { $pt = @(($pcx + $pr * [math]::Cos((RadOf $a))), ($pcy + $pr * [math]::Sin((RadOf $a)))); Line $white 4 $pcx $pcy $pt[0] $pt[1] $false }
TxtC 'Carbon 52.2%' 560 150 22 $ink $true; TxtC 'Oxygen 34.8%' 200 400 22 $orange $true; TxtC 'Hydrogen 13.0%' 170 190 22 $blue $true
Save 'chem-ethanol-pie.png'

# gas laws
Canvas 1040 530
TxtC 'Boyle''s law' 270 6 24 $ink $true; TxtC 'Charles'' law' 780 6 24 $ink $true
$ox = 80; $oy = 410
Arrow $ink 2.5 $ox $oy 460 $oy; Arrow $ink 2.5 $ox $oy $ox 60
TxtC 'Volume' 270 ($oy + 34) 20 $ink $true; TxtV 'Pressure' 30 235 20 $ink
$pts = @(); for ($v = 1.0; $v -le 10; $v += 0.25) { $pts += ,@(($ox + $v * 36), ($oy - (100 / $v) * 3.2)) }
Pl $blue 4 $pts
TxtC 'P is inversely proportional to V (PV = constant)' 270 485 18 $ink $false
$ox = 590
Arrow $ink 2.5 $ox $oy 980 $oy; Arrow $ink 2.5 $ox $oy $ox 60
TxtC 'Temperature (K)' 780 ($oy + 34) 20 $ink $true; TxtV 'Volume' 540 235 20 $ink
Pl $red 4 @(@($ox, $oy), @(($ox + 340), ($oy - 300)))
Dot $ink $ox $oy 6; Txt '0 K' ($ox - 40) ($oy + 8) 18 $ink $true
TxtC 'V is directly proportional to T (kelvin)' 780 485 18 $ink $false
Save 'chem-gas-laws.png'

# electron shells
Canvas 1000 430
TxtC 'Electron shells (arrangements)' 500 6 24 $ink $true
function ShellAtom($cx, $cy, $counts, $name, $arrange) {
  $radii = 38, 70, 102, 134
  for ($s = 0; $s -lt $counts.Count; $s++) {
    Ellip $grey 2 $cx $cy $radii[$s] $radii[$s] $false
    $n = $counts[$s]
    for ($k = 0; $k -lt $n; $k++) { $a = ($k / $n) * 2 * [math]::PI + 0.4 * $s; Dot $blue ($cx + $radii[$s] * [math]::Cos($a)) ($cy + $radii[$s] * [math]::Sin($a)) 6 }
  }
  Dot $red $cx $cy 20; TxtC $name $cx ($cy - 11) 18 $white $true
  TxtC $arrange $cx ($cy + 150) 22 $ink $true
}
ShellAtom 120 215 @(2, 6) 'O' '2, 6'
ShellAtom 370 215 @(2, 8, 1) 'Na' '2, 8, 1'
ShellAtom 640 215 @(2, 8, 7) 'Cl' '2, 8, 7'
ShellAtom 890 215 @(2, 8, 8) 'Ar' '2, 8, 8'
Save 'chem-electron-shells.png'

# bonding
Canvas 1100 440
TxtC 'Ionic bonding' 190 6 24 $ink $true; TxtC 'Covalent: H2' 550 6 24 $ink $true; TxtC 'Covalent: H2O' 900 6 24 $ink $true
function SmallShells($cx, $cy, $counts, $name, $skipLast) {
  $radii = 22, 42, 62
  for ($s = 0; $s -lt $counts.Count; $s++) { Ellip $grey 2 $cx $cy $radii[$s] $radii[$s] $false; $n = $counts[$s]; for ($k = 0; $k -lt $n; $k++) { if ($skipLast -and $s -eq ($counts.Count - 1) -and $k -eq 0) { continue }; $a = ($k / $n) * 2 * [math]::PI; Dot $blue ($cx + $radii[$s] * [math]::Cos($a)) ($cy + $radii[$s] * [math]::Sin($a)) 5 } }
  Dot $red $cx $cy 14; TxtC $name $cx ($cy - 8) 14 $white $true
}
SmallShells 105 190 @(2, 8, 1) 'Na' $true
SmallShells 335 190 @(2, 8, 7) 'Cl' $false
Dot $orange 167 190 6; Arrow $orange 2.5 175 176 293 176
TxtC 'e- moves from Na to Cl' 220 100 18 $orange $true
TxtC 'Na loses 1 e-: Na+' 105 275 18 $ink $true; TxtC 'Cl gains 1 e-: Cl-' 335 275 18 $ink $true
TxtC 'Opposite charges attract: NaCl' 220 330 20 $green $true
Ellip $ink 3 520 190 50 50 $false; Ellip $ink 3 580 190 50 50 $false
Dot $red 520 190 10; Dot $red 580 190 10; TxtC 'H' 520 180 12 $white $true; TxtC 'H' 580 180 12 $white $true
Dot $blue 550 172 6; Dot $orange 550 208 6
TxtC 'One shared pair: H-H' 550 275 18 $ink $true; TxtC 'single covalent bond' 550 300 18 $ink $true
Ellip $ink 3 900 150 55 55 $false; Ellip $ink 3 840 245 38 38 $false; Ellip $ink 3 960 245 38 38 $false
Dot $red 900 150 12; Dot $red 840 245 8; Dot $red 960 245 8
TxtC 'O' 900 140 14 $white $true
Dot $blue 868 198 6; Dot $orange 858 210 6; Dot $blue 932 198 6; Dot $orange 942 210 6
TxtC 'O shares one pair with each H' 900 310 18 $ink $true; TxtC '2 single bonds' 900 334 18 $ink $true
Save 'chem-bonding.png'

# redox electron transfer
Canvas 1000 480
TxtC 'Zn + CuSO4 -> ZnSO4 + Cu: electrons move from zinc to copper ions' 500 6 22 $ink $true
BoxL 150 150 150 80 'Zn atom' ([Drawing.Color]::FromArgb(226, 232, 240))
BoxL 500 150 190 80 ("Zn$sup2" + [char]0x207A + " ion") ([Drawing.Color]::FromArgb(219, 234, 254))
Arrow $red 3 230 150 400 150; TxtC ('loses 2 e-') 315 112 20 $red $true
BoxL 150 360 190 80 ("Cu$sup2" + [char]0x207A + " ion") ([Drawing.Color]::FromArgb(186, 230, 253))
BoxL 500 360 150 80 'Cu atom' ([Drawing.Color]::FromArgb(254, 215, 170))
Arrow $blue 3 250 360 420 360; TxtC ('gains 2 e-') 335 322 20 $blue $true
Line $orange 3 200 192 200 290 $true; Arrow $orange 3 200 290 200 316
TxtC '2 e-' 232 240 20 $orange $true
Txt 'OXIDATION (OIL)' 640 110 22 $red $true; Txt 'Zn loses electrons' 640 140 20 $ink $false; Txt 'Zn is the reducing agent' 640 166 20 $ink $false
Txt 'REDUCTION (RIG)' 640 320 22 $blue $true; Txt ("Cu$sup2" + [char]0x207A + " gains electrons") 640 350 20 $ink $false; Txt ("Cu$sup2" + [char]0x207A + " is the oxidising agent") 640 376 20 $ink $false
Save 'chem-redox.png'

# saturation beakers
Canvas 1000 470
TxtC 'Types of solution' 500 6 24 $ink $true
$rnd2 = New-Object System.Random 11
$bxs = 170, 500, 830
$ttl = 'Unsaturated', 'Saturated', 'Supersaturated'
$sub = 'all solute dissolved', 'extra solute at the bottom', 'crystals form (unstable)'
for ($i = 0; $i -lt 3; $i++) {
  $cx = $bxs[$i]
  RectF $liq ($cx - 80) 150 160 190
  GlassOut @(@(($cx - 80), 90), @(($cx - 80), 340), @(($cx + 80), 340), @(($cx + 80), 90))
  TxtC $ttl[$i] $cx 360 24 $ink $true; TxtC $sub[$i] $cx 394 18 $light $false
}
foreach ($k in 1..6) { Dot $white ($bxs[0] - 60 + $rnd2.Next(0, 120)) (170 + $rnd2.Next(0, 150)) 3 }
foreach ($k in 1..8) { Dot $white ($bxs[1] - 60 + $rnd2.Next(0, 120)) (170 + $rnd2.Next(0, 110)) 3 }
foreach ($k in 0..9) { Dot $ink ($bxs[1] - 54 + $k * 12) 330 7 }
Line $ink 2 $bxs[2] 70 $bxs[2] 250 $false
foreach ($pp in @(@(0, 250, 22), @(-22, 290, 14), @(26, 292, 16), @(-6, 318, 12), @(40, 322, 10), @(-44, 322, 10))) { FillPoly ([Drawing.Color]::FromArgb(230, 255, 255, 255)) @(@(($bxs[2] + $pp[0]), ($pp[1] - $pp[2])), @(($bxs[2] + $pp[0] + $pp[2] * 0.7), ($pp[1])), @(($bxs[2] + $pp[0]), ($pp[1] + $pp[2])), @(($bxs[2] + $pp[0] - $pp[2] * 0.7), ($pp[1]))); }
Save 'chem-saturation.png'

# solubility curve
Canvas 940 640
TxtC 'Solubility curve of potassium nitrate (KNO3)' 470 6 24 $ink $true
$ox = 100; $oy = 560; $sx = 8.2; $sy = 2.5
Arrow $ink 2.5 $ox $oy 900 $oy; Arrow $ink 2.5 $ox $oy $ox 50
TxtC 'Temperature (C)' 480 ($oy + 44) 22 $ink $true; TxtV 'Solubility (g per 100 g water)' 14 300 22 $ink
foreach ($t in 0, 10, 20, 30, 40, 50, 60, 70, 80, 90, 100) { TxtC "$t" ($ox + $t * $sx) ($oy + 8) 16 $ink $false }
foreach ($v in 0, 25, 50, 75, 100, 125, 150, 175, 200) { Txt "$v" ($ox - 48) ($oy - $v * $sy - 11) 16 $ink $false; Line $pale 1 $ox ($oy - $v * $sy) ($ox + 100 * $sx) ($oy - $v * $sy) $false }
$kd = @(@(0, 13), @(10, 21), @(20, 32), @(30, 46), @(40, 64), @(50, 85), @(60, 110), @(70, 130), @(80, 150))
$kp = @(); foreach ($q in $kd) { $kp += ,@(($ox + $q[0] * $sx), ($oy - $q[1] * $sy)) }
Curve $blue 4 $kp
foreach ($q in $kp) { Dot $orange $q[0] $q[1] 6 }
Line $ink 1.5 ($ox + 20 * $sx) ($oy - 32 * $sy) ($ox + 20 * $sx) $oy $true; Line $ink 1.5 $ox ($oy - 32 * $sy) ($ox + 20 * $sx) ($oy - 32 * $sy) $true
Line $ink 1.5 ($ox + 40 * $sx) ($oy - 64 * $sy) ($ox + 40 * $sx) $oy $true; Line $ink 1.5 $ox ($oy - 64 * $sy) ($ox + 40 * $sx) ($oy - 64 * $sy) $true
Txt '32 g at 20 C' ($ox + 20 * $sx + 8) ($oy - 32 * $sy - 28) 18 $ink $true; Txt '64 g at 40 C' ($ox + 40 * $sx + 8) ($oy - 64 * $sy - 28) 18 $ink $true
TxtC 'Unsaturated (below the curve)' 650 480 20 $green $true
TxtC 'More than can dissolve (above the curve)' 330 130 20 $red $true
TxtC 'Saturated: on the curve' 700 130 20 $blue $true
Save 'chem-solubility-curve.png'


# ---------- Chemistry Term 3 figures ----------
$sb = @{ '2' = [string][char]0x2082; '3' = [string][char]0x2083; '4' = [string][char]0x2084; '6' = [string][char]0x2086; '8' = [string][char]0x2088 }
$cgrey = [Drawing.Color]::FromArgb(75, 85, 99); $hlight = [Drawing.Color]::FromArgb(226, 232, 240)
function AtomC($x, $y, $sym) { if ($sym -eq 'C') { Dot $cgrey $x $y 17; TxtC 'C' $x ($y - 11) 18 $white $true } else { Dot $hlight $x $y 12; Ellip $ink 1.5 $x $y 12 12 $false; TxtC $sym $x ($y - 9) 14 $ink $true } }
function Bond($x1, $y1, $x2, $y2) { Line $ink 3 $x1 $y1 $x2 $y2 $false }

Canvas 1100 440
TxtC 'Simple hydrocarbons' 550 6 26 $ink $true
$cy = 190
# methane
$cx = 140
foreach ($d in @(@(-55, -55), @(55, -55), @(-55, 55), @(55, 55))) { Bond $cx $cy ($cx + $d[0]) ($cy + $d[1]) }
foreach ($d in @(@(-55, -55), @(55, -55), @(-55, 55), @(55, 55))) { AtomC ($cx + $d[0]) ($cy + $d[1]) 'H' }
AtomC $cx $cy 'C'
TxtC 'Methane' $cx 300 22 $ink $true; TxtC ("CH" + $sb['4']) $cx 330 22 $blue $true; TxtC 'alkane' $cx 362 18 $light $false
# ethane
$cx = 410
Bond ($cx - 35) $cy ($cx + 35) $cy
foreach ($side in -1, 1) { $x = $cx + $side * 35; Bond $x $cy $x ($cy - 62); Bond $x $cy $x ($cy + 62); Bond $x $cy ($x + $side * 62) $cy; AtomC $x ($cy - 62) 'H'; AtomC $x ($cy + 62) 'H'; AtomC ($x + $side * 62) $cy 'H' }
AtomC ($cx - 35) $cy 'C'; AtomC ($cx + 35) $cy 'C'
TxtC 'Ethane' $cx 300 22 $ink $true; TxtC ("C" + $sb['2'] + "H" + $sb['6']) $cx 330 22 $blue $true; TxtC 'alkane' $cx 362 18 $light $false
# ethene
$cx = 700
Line $ink 3 ($cx - 35) ($cy - 5) ($cx + 35) ($cy - 5) $false; Line $ink 3 ($cx - 35) ($cy + 5) ($cx + 35) ($cy + 5) $false
foreach ($side in -1, 1) { $x = $cx + $side * 35; Bond $x $cy ($x + $side * 45) ($cy - 55); Bond $x $cy ($x + $side * 45) ($cy + 55); AtomC ($x + $side * 45) ($cy - 55) 'H'; AtomC ($x + $side * 45) ($cy + 55) 'H' }
AtomC ($cx - 35) $cy 'C'; AtomC ($cx + 35) $cy 'C'
TxtC 'Ethene' $cx 300 22 $ink $true; TxtC ("C" + $sb['2'] + "H" + $sb['4']) $cx 330 22 $blue $true; TxtC 'alkene (C=C)' $cx 362 18 $light $false
# ethyne
$cx = 970
Line $ink 3 ($cx - 40) ($cy - 8) ($cx + 40) ($cy - 8) $false; Line $ink 3 ($cx - 40) $cy ($cx + 40) $cy $false; Line $ink 3 ($cx - 40) ($cy + 8) ($cx + 40) ($cy + 8) $false
Bond ($cx - 40) $cy ($cx - 100) $cy; Bond ($cx + 40) $cy ($cx + 100) $cy
AtomC ($cx - 100) $cy 'H'; AtomC ($cx + 100) $cy 'H'; AtomC ($cx - 40) $cy 'C'; AtomC ($cx + 40) $cy 'C'
TxtC 'Ethyne' $cx 300 22 $ink $true; TxtC ("C" + $sb['2'] + "H" + $sb['2']) $cx 330 22 $blue $true; TxtC ('alkyne (C' + [char]0x2261 + 'C)') $cx 362 18 $light $false
Save 'chem-hydrocarbons.png'

# butane isomers
Canvas 900 380
TxtC 'The two isomers of C4H10 (hydrogen atoms not shown)' 450 6 24 $ink $true
$pts = @(@(80, 230), @(160, 170), @(240, 230), @(320, 170))
for ($i = 0; $i -lt 3; $i++) { Bond $pts[$i][0] $pts[$i][1] $pts[$i + 1][0] $pts[$i + 1][1] }
foreach ($q in $pts) { AtomC $q[0] $q[1] 'C' }
TxtC 'Butane' 200 285 22 $ink $true; TxtC 'straight chain' 200 315 18 $light $false
$p2 = @(@(540, 220), @(620, 170), @(700, 220))
Bond 540 220 620 170; Bond 620 170 700 220; Bond 620 170 620 100
foreach ($q in $p2) { AtomC $q[0] $q[1] 'C' }
AtomC 620 100 'C'
TxtC '2-Methylpropane' 620 285 22 $ink $true; TxtC 'branched chain' 620 315 18 $light $false
Save 'chem-butane-isomers.png'

# cis / trans
Canvas 1200 470
TxtC 'Cis and trans isomers' 600 6 26 $ink $true
function CTMol($cx, $cy, $tl, $bl, $tr, $br, $title, $sub) {
  Line $ink 3 ($cx - 35) ($cy - 5) ($cx + 35) ($cy - 5) $false; Line $ink 3 ($cx - 35) ($cy + 5) ($cx + 35) ($cy + 5) $false
  Bond ($cx - 35) $cy ($cx - 80) ($cy - 60); Bond ($cx - 35) $cy ($cx - 80) ($cy + 60); Bond ($cx + 35) $cy ($cx + 80) ($cy - 60); Bond ($cx + 35) $cy ($cx + 80) ($cy + 60)
  AtomC ($cx - 35) $cy 'C'; AtomC ($cx + 35) $cy 'C'
  TxtC $tl ($cx - 92) ($cy - 90) 22 $blue $true; TxtC $bl ($cx - 92) ($cy + 66) 22 $ink $true; TxtC $tr ($cx + 92) ($cy - 90) 22 $blue $true; TxtC $br ($cx + 92) ($cy + 66) 22 $ink $true
  TxtC $title $cx ($cy + 120) 22 $ink $true; TxtC $sub $cx ($cy + 148) 18 $light $false
}
$ch3 = 'CH' + $sb['3']
CTMol 150 210 $ch3 'H' $ch3 'H' 'cis-But-2-ene' 'CH3 groups on the same side'
CTMol 450 210 $ch3 'H' 'H' $ch3 'trans-But-2-ene' 'CH3 groups on opposite sides'
CTMol 750 210 'Cl' 'H' 'Cl' 'H' 'cis-1,2-Dichloroethene' 'Cl atoms on the same side'
CTMol 1050 210 'Cl' 'H' 'H' 'Cl' 'trans-1,2-Dichloroethene' 'Cl atoms on opposite sides'
Save 'chem-cis-trans.png'

# fractionating column
Canvas 900 700
TxtC 'Fractional distillation of crude oil' 450 6 26 $ink $true
$gb = New-Object Drawing.Drawing2D.LinearGradientBrush ((New-Object Drawing.Point 0, 70), (New-Object Drawing.Point 0, 590), ([Drawing.Color]::FromArgb(186, 230, 253)), ([Drawing.Color]::FromArgb(251, 146, 60)))
$script:g.FillRectangle($gb, 320, 70, 170, 520); $gb.Dispose()
$pn = PenOf $ink 3; $script:g.DrawRectangle($pn, 320, 70, 170, 520); $pn.Dispose()
$fr = @(@('Refinery gas (below 40 C)', 95), @('Petrol (40 to 120 C)', 165), @('Naphtha (120 to 180 C)', 235), @('Kerosene (180 to 250 C)', 305), @('Diesel (250 to 320 C)', 375), @('Lubricating oil (320 to 400 C)', 445), @('Fuel oil (above about 350 C)', 515), @('Bitumen (residue)', 575))
foreach ($f in $fr) { Line $ink 1.5 320 ($f[1] - 12) 490 ($f[1] - 12) $false; Arrow $ink 2 490 $f[1] 540 $f[1]; Txt $f[0] 548 ($f[1] - 11) 20 $ink $true }
Line $ink 1.5 320 ($fr[7][1] - 12) 490 ($fr[7][1] - 12) $false
Arrow $red 4 200 520 316 520; TxtC 'Heated' 150 540 20 $red $true; TxtC 'crude oil' 150 562 20 $red $true; TxtC 'enters' 150 584 20 $red $true
Arrow $blue 4 250 150 250 96; Txt 'Cooler' 190 160 20 $blue $true; Txt 'Smaller molecules' 120 184 18 $ink $false
Arrow $red 4 250 420 250 474; Txt 'Hotter' 190 380 20 $red $true; Txt 'Larger molecules' 110 404 18 $ink $false
Save 'chem-fractionating-column.png'

# reactivity series
Canvas 820 700
TxtC 'Reactivity series of metals' 410 6 26 $ink $true
$ser = 'Potassium (K)', 'Sodium (Na)', 'Calcium (Ca)', 'Magnesium (Mg)', 'Aluminium (Al)', 'Zinc (Zn)', 'Iron (Fe)', 'Lead (Pb)', 'Hydrogen (H) - for comparison', 'Copper (Cu)', 'Silver (Ag)', 'Gold (Au)'
for ($i = 0; $i -lt $ser.Count; $i++) {
  $t = $i / ($ser.Count - 1)
  $c = [Drawing.Color]::FromArgb([int](220 - 40 * $t), [int](38 + 160 * $t), [int](38 + 20 * $t))
  if ($ser[$i] -like 'Hydrogen*') { $c = [Drawing.Color]::FromArgb(203, 213, 225) }
  RectF $c 180 (56 + $i * 50) 340 44
  $pn = PenOf $ink 2; $script:g.DrawRectangle($pn, 180, (56 + $i * 50), 340, 44); $pn.Dispose()
  TxtC $ser[$i] 350 (56 + $i * 50 + 10) 20 $ink $true
}
Arrow $red 4 90 640 90 70; Txt 'More' 50 330 20 $red $true; Txt 'reactive' 40 354 20 $red $true
Txt 'Metals above can displace' 540 200 18 $ink $false; Txt 'metals below from their' 540 224 18 $ink $false; Txt 'compounds' 540 248 18 $ink $false
Save 'chem-reactivity-series.png'

# energy profiles
function EY([double]$t, $rY, $pY, $bump) { $sg = 1 / (1 + [math]::Exp(-($t - 0.44) * 18)); $rY + ($pY - $rY) * $sg - $bump * [math]::Exp(-[math]::Pow(($t - 0.36) / 0.11, 2)) }
function EAxes($ox, $title) {
  Arrow $ink 2.5 $ox 470 ($ox + 340) 470; Arrow $ink 2.5 $ox 470 $ox 70
  TxtC $title ($ox + 170) 40 20 $ink $true
  TxtC 'Progress of reaction' ($ox + 170) 480 16 $ink $false; TxtV 'Energy' ($ox - 16) 270 16 $ink
}
function ECurve($ox, $rY, $pY, $bump, $col) {
  $pts = @(); for ($t = 0; $t -le 1.0001; $t += 0.02) { $pts += ,@(($ox + 20 + 300 * $t), (EY $t $rY $pY $bump)) }
  Pl $col 4 $pts
}
Canvas 1160 540
TxtC 'Energy profile diagrams' 580 4 26 $ink $true
$ex = 40; EAxes $ex 'Exothermic'
Line $grey 1.5 ($ex + 20) 170 ($ex + 330) 170 $true; Line $grey 1.5 ($ex + 20) 300 ($ex + 330) 300 $true
ECurve $ex 170 300 105 $blue
$pk = EY 0.36 170 300 105
Arrow $red 2.5 ($ex + 128) 170 ($ex + 128) ($pk + 4); TxtC 'Ea' ($ex + 100) 125 17 $red $true
Arrow $green 2.5 ($ex + 300) 172 ($ex + 300) 298; TxtC 'ΔH < 0' ($ex + 335) 225 16 $green $true
TxtC 'Reactants' ($ex + 60) 150 15 $ink $true; TxtC 'Products' ($ex + 280) 310 15 $ink $true
$en = 420; EAxes $en 'Endothermic'
Line $grey 1.5 ($en + 20) 330 ($en + 330) 330 $true; Line $grey 1.5 ($en + 20) 210 ($en + 330) 210 $true
ECurve $en 330 210 205 $blue
$pk2 = EY 0.36 330 210 205
Arrow $red 2.5 ($en + 128) 330 ($en + 128) ($pk2 + 4); TxtC 'Ea' ($en + 100) 215 17 $red $true
Arrow $green 2.5 ($en + 300) 328 ($en + 300) 212; TxtC 'ΔH > 0' ($en + 335) 270 16 $green $true
TxtC 'Reactants' ($en + 60) 350 15 $ink $true; TxtC 'Products' ($en + 280) 190 15 $ink $true
$cx = 800; EAxes $cx 'Effect of a catalyst'
Line $grey 1.5 ($cx + 20) 170 ($cx + 330) 170 $true; Line $grey 1.5 ($cx + 20) 300 ($cx + 330) 300 $true
ECurve $cx 170 300 105 $blue
ECurve $cx 170 300 55 $green
TxtC 'without catalyst' ($cx + 110) 74 15 $blue $true; TxtC 'with catalyst (lower Ea)' ($cx + 150) 112 15 $green $true
TxtC 'ΔH is the same' ($cx + 250) 322 15 $ink $true
Save 'chm2-energy-profiles.png'

"drawn 85 figures"
Get-ChildItem $out | Measure-Object | ForEach-Object { "images in folder: $($_.Count)" }