param([switch]$Native,[int]$Frames=6,[int]$Stress=1,
 [string]$ModelSimBin='C:\modeltech64_2020.4\win64')
$ErrorActionPreference='Stop'
if($Frames -lt 3){throw 'Frames must be at least 3 to cover rejection and recovery.'}
$root=Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Test-Package.ps1') -SourceOnly
$vsim=Join-Path $ModelSimBin 'vsim.exe'
if(-not(Test-Path -LiteralPath $vsim)){throw 'Specify the installed ModelSim bin directory with -ModelSimBin.'}
$stamp=Get-Date -Format 'yyyyMMdd_HHmmss'
$nativeValue=if($Native){1}else{0}
$run=Join-Path $root "build\sim_native${nativeValue}_frames${Frames}_$stamp"
New-Item -ItemType Directory -Force -Path $run | Out-Null
$work=(Join-Path $run 'work').Replace('\','/')
$sources=Get-Content -LiteralPath (Join-Path $root 'sim\sources.json') -Raw | ConvertFrom-Json
$sourceArgs=($sources | ForEach-Object { '{'+(Join-Path $root $_).Replace('\','/')+'}' }) -join ' '
$bench=(Join-Path $root 'sim\tb_continuous_stream_system.sv').Replace('\','/')
$script=Join-Path $run 'run.do'
$body=@('onerror {quit -code 2 -force}',"vlib {$work}","vmap review_work {$work}",
 "vlog -sv -work review_work $sourceArgs {$bench}",
 "vsim -voptargs=+acc -gFULLHD=$nativeValue -gFRAMES=$Frames -gSTRESS=$Stress -gBAD_FRAME=2 -gINLINE=1 -gOVERLAP=1 -gPREFETCH=1 -gLATE_CAPTURE=0 review_work.tb_continuous_stream_system",
 'onfinish stop','onbreak {resume}','run -all',
 'set pass_bit [examine -value -radix binary -noshowbase sim:/tb_continuous_stream_system/test_passed]',
 'if {[llength $pass_bit]!=1 || [lindex $pass_bit 0] ne "1"} {quit -code 3 -force}',
 'puts "REVIEW_VERIFIED_PASS_BIT=1"','quit -code 0 -force')
$body | Set-Content -LiteralPath $script -Encoding ascii
$log=Join-Path $run 'simulation.log'
Push-Location (Join-Path $root 'sim')
try{& $vsim -c -do $script *> $log;$toolExit=$LASTEXITCODE}finally{Pop-Location}
$text=Get-Content -LiteralPath $log -Raw
if($toolExit -ne 0 -or $text -notmatch 'REVIEW_VERIFIED_PASS_BIT=1' -or $text -match '\*\* (Error|Fatal):'){throw "Simulation failed: $log"}
Write-Output "SIMULATION_PASS native=$nativeValue frames=$Frames log=$log"
