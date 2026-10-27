# Makes labelled contact sheets of the extracted pictures so they can be reviewed quickly.
#   powershell -ExecutionPolicy Bypass -File sheets.ps1 -Dir C:\temp\notes\img -Out C:\temp\notes\sheets [-PerSheet 4]
param([Parameter(Mandatory = $true)][string]$Dir, [Parameter(Mandatory = $true)][string]$Out, [int]$PerSheet = 4)
Add-Type -AssemblyName System.Drawing
New-Item -ItemType Directory -Force $Out | Out-Null
$files = Get-ChildItem $Dir -File | Where-Object { $_.Extension -in '.jpg', '.png' } | Sort-Object { [int](($_.BaseName -replace '\D', '')) }
$cols = 2; $cw = 640; $ch = 480
$rows = [Math]::Ceiling($PerSheet / $cols)
$n = 0; $sheet = 0
for ($i = 0; $i -lt $files.Count; $i += $PerSheet) {
  $sheet++
  $bmp = New-Object Drawing.Bitmap ($cols * $cw), ($rows * $ch)
  $g = [Drawing.Graphics]::FromImage($bmp); $g.Clear([Drawing.Color]::White); $g.InterpolationMode = 'HighQualityBicubic'
  for ($k = 0; $k -lt $PerSheet -and ($i + $k) -lt $files.Count; $k++) {
    $f = $files[$i + $k]; $im = [Drawing.Image]::FromFile($f.FullName)
    $x = ($k % $cols) * $cw; $y = [Math]::Floor($k / $cols) * $ch
    $scale = [Math]::Min(($cw - 20) / $im.Width, ($ch - 50) / $im.Height); if ($scale -gt 1.5) { $scale = 1.5 }
    $w = [int]($im.Width * $scale); $h = [int]($im.Height * $scale)
    $g.DrawImage($im, $x + 10, $y + 34, $w, $h)
    $g.DrawRectangle([Drawing.Pens]::LightGray, $x + 2, $y + 2, $cw - 4, $ch - 4)
    $font = [Drawing.Font]::new('Segoe UI', [single]13, [Drawing.FontStyle]::Bold)
    $g.DrawString($f.BaseName + '  ' + $im.Width + 'x' + $im.Height, $font, [Drawing.Brushes]::DarkRed, $x + 8, $y + 8)
    $im.Dispose()
  }
  $bmp.Save((Join-Path $Out ("sheet{0:D2}.jpg" -f $sheet)), [Drawing.Imaging.ImageFormat]::Jpeg); $g.Dispose(); $bmp.Dispose()
}
"$sheet sheets"
