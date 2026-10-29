# Copies pictures extracted from a lesson-note PDF into ng_content\img, removing the small AI-generator
# "sparkle" mark in the bottom-right corner (it sits on a flat background, so a block copied from just
# to its left covers it) and shrinking wide pictures. Usage: dot-source, then call Prep.
Add-Type -AssemblyName System.Drawing
$script:imgOut = Join-Path $PSScriptRoot 'img'

function Prep([string]$src, [string]$name, [switch]$Sparkle, [switch]$Wipe, [int]$MaxW = 1000) {
  $b = [Drawing.Bitmap]::FromFile($src)
  $bmp = New-Object Drawing.Bitmap($b.Width, $b.Height, [Drawing.Imaging.PixelFormat]::Format24bppRgb)
  $g = [Drawing.Graphics]::FromImage($bmp); $g.DrawImage($b, 0, 0, $b.Width, $b.Height); $g.Dispose(); $b.Dispose()
  $W = $bmp.Width; $H = $bmp.Height
  if ($Sparkle) {
    # background colour just left of the corner, then the bounding box of clearly lighter pixels
    $bg = $bmp.GetPixel($W - 150, $H - 60); $bgL = ($bg.R + $bg.G + $bg.B) / 3
    $minx = $W; $maxx = 0; $miny = $H; $maxy = 0
    for ($y = $H - 85; $y -lt $H; $y++) { for ($x = $W - 85; $x -lt $W; $x++) {
      $c = $bmp.GetPixel($x, $y); $l = ($c.R + $c.G + $c.B) / 3
      if ([Math]::Abs($l - $bgL) -gt 18) { if ($x -lt $minx) { $minx = $x }; if ($x -gt $maxx) { $maxx = $x }; if ($y -lt $miny) { $miny = $y }; if ($y -gt $maxy) { $maxy = $y } } } }
    if ($maxx -gt $minx) {
      $pad = 6; $x0 = [Math]::Max(0, $minx - $pad); $y0 = [Math]::Max(0, $miny - $pad); $x1 = [Math]::Min($W - 1, $maxx + $pad); $y1 = [Math]::Min($H - 1, $maxy + $pad)
      $bw = $x1 - $x0 + 1; $bh = $y1 - $y0 + 1; $sx = $x0 - $bw - 4
      if ($sx -ge 0) { for ($yy = 0; $yy -lt $bh; $yy++) { for ($xx = 0; $xx -lt $bw; $xx++) { $bmp.SetPixel($x0 + $xx, $y0 + $yy, $bmp.GetPixel($sx + $xx, $y0 + $yy)) } } }
      Write-Host "  $name : sparkle box ${bw}x${bh} at $x0,$y0"
    } else { Write-Host "  $name : no sparkle found" }
  }
  if ($Wipe) {
    # faint mark the scan misses: paint the corner with the background colour sampled just to its left
    $bgc = $bmp.GetPixel($W - 150, $H - 12); $wb = New-Object Drawing.SolidBrush($bgc)
    $g3 = [Drawing.Graphics]::FromImage($bmp); $g3.FillRectangle($wb, $W - 60, $H - 60, 60, 60); $g3.Dispose()
  }
  $outBmp = $bmp
  if ($W -gt $MaxW) { $nh = [int]($H * $MaxW / $W); $r = New-Object Drawing.Bitmap($MaxW, $nh); $g2 = [Drawing.Graphics]::FromImage($r); $g2.InterpolationMode = 'HighQualityBicubic'; $g2.DrawImage($bmp, 0, 0, $MaxW, $nh); $g2.Dispose(); $outBmp = $r }
  $enc = [Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object { $_.MimeType -eq 'image/jpeg' }
  $ep = New-Object Drawing.Imaging.EncoderParameters(1); $ep.Param[0] = New-Object Drawing.Imaging.EncoderParameter([Drawing.Imaging.Encoder]::Quality, [long]88)
  $outBmp.Save((Join-Path $script:imgOut ($name + '.jpg')), $enc, $ep)
  if ($outBmp -ne $bmp) { $outBmp.Dispose() }; $bmp.Dispose()
}

