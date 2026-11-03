$ErrorActionPreference='Stop'
$root=$PSScriptRoot
$manifest=Get-Content (Join-Path $root 'MANIFEST_SHA256.json') -Raw | ConvertFrom-Json
foreach($entry in $manifest.files){
  $path=Join-Path $root $entry.path
  if(-not (Test-Path -LiteralPath $path -PathType Leaf)){throw "Missing file: $($entry.path)"}
  if((Get-Item -LiteralPath $path).Length -ne $entry.bytes){throw "Size mismatch: $($entry.path)"}
  if((Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $entry.sha256){throw "Hash mismatch: $($entry.path)"}
}
Write-Output "PASS: $($manifest.files.Count) files verified. No build or programming was started."
