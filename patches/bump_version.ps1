# Sets the app version in all four places (Sg in app.js, dist\version.json, ?v= in dist\index.html and dist\careers\index.html).
#   powershell -ExecutionPolicy Bypass -File bump_version.ps1 -Version 2026.10.27.2
param([Parameter(Mandatory = $true)][string]$Version)
if ($Version -notmatch '^\d{4}\.\d{1,2}\.\d{1,2}\.\d+$') { throw 'version looks like 2026.10.27.2' }
$dist = Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'dist'
$enc = [Text.Encoding]::GetEncoding(28591)
$js = Join-Path $dist 'assets\app.js'
$d = $enc.GetString([IO.File]::ReadAllBytes($js))
$m = [regex]::Matches($d, 'Sg="\d{4}\.\d{1,2}\.\d{1,2}\.\d+"')
if ($m.Count -ne 1) { throw "expected one Sg=... in app.js, found $($m.Count)" }
$d = $d.Replace($m[0].Value, "Sg=`"$Version`"")
[IO.File]::WriteAllBytes($js, $enc.GetBytes($d))
[IO.File]::WriteAllText((Join-Path $dist 'version.json'), "{`"version`":`"$Version`"}", (New-Object Text.UTF8Encoding($false)))
foreach ($h in @('index.html', 'careers\index.html')) {
  $f = Join-Path $dist $h
  $t = [IO.File]::ReadAllText($f, [Text.Encoding]::UTF8)
  $t2 = [regex]::Replace($t, '\?v=\d{4}\.\d{1,2}\.\d{1,2}\.\d+', "?v=$Version")
  if ($t2 -eq $t -and $t -notmatch [regex]::Escape("?v=$Version")) { throw "no ?v= found in $h" }
  [IO.File]::WriteAllText($f, $t2, (New-Object Text.UTF8Encoding($false)))
}
"version set to $Version"
