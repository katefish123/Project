param([ValidateSet('Import','Compile','Full')][string]$Stage='Import',
 [string]$PdsBin='C:\pango\PDS_2022.2-SP6.4\bin')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Test-Package.ps1') -SourceOnly
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$run=Join-Path $root "build\pds_${Stage}_$stamp"
New-Item -ItemType Directory -Force -Path $run | Out-Null
$projectDir=Join-Path $root 'project'
$original=Get-Content -LiteralPath (Join-Path $projectDir 'V4S_Review.pds') -Raw -Encoding utf8
$resolved=[regex]::Replace($original,'\(_file "([^"]+)"',{
 param($match)
 $absolute=[IO.Path]::GetFullPath((Join-Path $projectDir $match.Groups[1].Value)).Replace('\','/')
 '(_file "'+$absolute+'"'
})
$project=Join-Path $run 'V4S_Review.pds'
[IO.File]::WriteAllText($project,$resolved,[Text.UTF8Encoding]::new($false))
if($Stage -eq 'Import'){
 Write-Output "PROJECT_READY: $project"
 return
}
$tool=Join-Path $PdsBin 'pds_shell.exe'
if(-not(Test-Path -LiteralPath $tool)){throw 'Specify -PdsBin for PDS 2022.2-SP6.4.'}
$log=Join-Path $run 'pds.log'
if($Stage -eq 'Compile'){
 & $tool -project $project -work_dir $run -project_name V4S_Review -run compile *> $log
}else{
 $manifest=Get-Content -LiteralPath (Join-Path $projectDir 'source_manifest.json') -Raw -Encoding utf8 | ConvertFrom-Json
 $body=@('set_arch -family Logos2 -device PG2L100H -speedgrade -6 -package FBG676')
 foreach($entry in $manifest.entries){
  $path=(Join-Path $root $entry.path).Replace('\','/')
  $command=if($entry.path -like '*.fdc'){'add_constraint'}else{'add_design'}
  $body+=$command+' {'+$path+'}'
 }
 $body+=@('compile -top_module video_correct_ddr_top','synthesize -ads','dev_map',
  'pnr -gplace_seed 17 -groute_seed 17 -optimize_multi_corner_timing -slack_prior_in_global_router TRUE',
  'report_timing','gen_bit_stream')
 $tcl=Join-Path $run 'build_resolved.tcl'
 $body | Set-Content -LiteralPath $tcl -Encoding ascii
 & $tool -file $tcl -work_dir $run -project_name V4S_Review *> $log
}
$toolExit=$LASTEXITCODE
$text=Get-Content -LiteralPath $log -Raw
Write-Output "PDS log: $log"
if($toolExit -ne 0 -or $text -match '(?m)^E:' -or $text -notmatch 'Process "Compile" done\.|Executing : compile .*successfully\.|Executing : compile successfully\.'){
 throw 'PDS compile failed; inspect the log. Exit code alone is insufficient.'
}
if($Stage -eq 'Full'){
 if($text -notmatch 'Executing : gen_bit_stream successfully\.') {throw 'New bitstream was not generated.'}
 $timing=Join-Path $run 'report_timing\video_correct_ddr_top.rtr'
 if(-not(Test-Path -LiteralPath $timing) -or (Get-Content -LiteralPath $timing -Raw) -notmatch 'Design Summary : All Constraints Met\.'){
  throw 'New implementation has not passed final timing.'
 }
 Write-Output 'NEW_BUILD_TIMING_PASS; hardware acceptance is still required. Supplied bitstream remains unchanged.'
}else{Write-Output 'PDS_COMPILE_PASS'}
