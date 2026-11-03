param([switch]$SourceOnly)
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
$manifest=Get-Content -LiteralPath (Join-Path $root 'project\source_manifest.json') -Raw -Encoding utf8 | ConvertFrom-Json
$rootPrefix=[IO.Path]::GetFullPath($root)+[IO.Path]::DirectorySeparatorChar
foreach($entry in $manifest.entries){
 $target=[IO.Path]::GetFullPath((Join-Path $root $entry.path))
 if(-not $target.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe path in manifest.'}
 if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $entry.sha256){throw "Source checksum mismatch: $($entry.path)"}
}
$bit=Join-Path $root 'bitstream\video_correct_ddr_top.sbit'
if((Get-FileHash -LiteralPath $bit -Algorithm SHA256).Hash.ToLowerInvariant() -ne $manifest.bitstream_sha256){throw 'Bitstream checksum mismatch.'}
if(-not $SourceOnly){
 $package=Get-Content -LiteralPath (Join-Path $root 'PACKAGE_MANIFEST.json') -Raw -Encoding utf8 | ConvertFrom-Json
 foreach($item in $package.files.PSObject.Properties){
  $target=[IO.Path]::GetFullPath((Join-Path $root $item.Name))
  if(-not $target.StartsWith($rootPrefix,[StringComparison]::OrdinalIgnoreCase)){throw 'Unsafe package path.'}
  if((Get-FileHash -LiteralPath $target -Algorithm SHA256).Hash.ToLowerInvariant() -ne $item.Value){throw "Package checksum mismatch: $($item.Name)"}
 }
}
Write-Output "PACKAGE_CHECK_PASS production_inputs=$($manifest.entries.Count) tested_bitstream=3e3475d3"
