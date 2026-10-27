# Extracts text (with [IMG] markers) and pictures from a WPS/Word style PDF.
#   powershell -ExecutionPolicy Bypass -File extract.ps1 -Pdf "notes.pdf" -Out "C:\temp\notes"
# Pictures that appear on many pages (the watermark) are skipped.
param([Parameter(Mandatory = $true)][string]$Pdf, [Parameter(Mandatory = $true)][string]$Out, [double]$WatermarkShare = 0.35)
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not ('PdfX' -as [type])) { Add-Type -Path (Join-Path $here 'PdfExtract.cs') -ReferencedAssemblies System.Drawing }
New-Item -ItemType Directory -Force (Join-Path $Out 'img') | Out-Null
[PdfX]::Load([IO.File]::ReadAllBytes($Pdf))
$pages = [PdfX]::PageIds()
$use = [PdfX]::ImageUse($pages)
$skip = New-Object 'System.Collections.Generic.HashSet[int]'
foreach ($k in $use.Keys) { if ($use[$k] -ge [Math]::Max(3, $pages.Count * $WatermarkShare)) { [void]$skip.Add($k) } }
$names = New-Object 'System.Collections.Generic.Dictionary[int,string]'
$manifest = @()
foreach ($k in ($use.Keys | Sort-Object)) {
  if ($skip.Contains($k)) { $manifest += "obj $k : SKIPPED (used on $($use[$k]) pages: watermark)"; continue }
  $r = [PdfX]::SaveImage($k, (Join-Path $Out 'img'), "img_$k")
  if ($r) { $parts = $r.Split('|'); $names[$k] = [IO.Path]::GetFileName($parts[0]) + ' ' + $parts[1]; $manifest += "obj $k : $($names[$k]) (used $($use[$k])x)" }
  else { $manifest += "obj $k : could not decode: " + [PdfX]::ImageInfo($k).Substring(0, 120) }
}
$sb = New-Object Text.StringBuilder
$n = 0
foreach ($p in $pages) {
  $n++
  $used = New-Object 'System.Collections.Generic.List[int]'
  [void]$sb.Append([PdfX]::PageToText($p, $n, $names, $skip, [ref]$used))
}
[IO.File]::WriteAllText((Join-Path $Out 'text.txt'), $sb.ToString(), (New-Object Text.UTF8Encoding($false)))
[IO.File]::WriteAllLines((Join-Path $Out 'images.txt'), $manifest)
"pages: $($pages.Count); images found: $($use.Count); skipped as watermark: $($skip.Count); text chars: $($sb.Length)"
