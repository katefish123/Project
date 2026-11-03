param([string]$PdsBin='C:\pango\PDS_2022.2-SP6.4\bin')
$ErrorActionPreference='Stop'
$root=Split-Path -Parent $PSScriptRoot
& (Join-Path $PSScriptRoot 'Test-Package.ps1') -SourceOnly
$tool=Join-Path $PdsBin 'cdt_cfg_shell.exe'
if(-not(Test-Path -LiteralPath $tool)){throw 'Specify the installed PDS bin directory.'}
$run=Join-Path $root ('build\program_'+(Get-Date -Format 'yyyyMMdd_HHmmss'))
New-Item -ItemType Directory -Force -Path $run | Out-Null
if(-not(Get-NetTCPConnection -LocalPort 65420 -State Listen -ErrorAction SilentlyContinue)){
 Start-Process -FilePath (Join-Path $PdsBin 'cdt_js.exe') -ArgumentList @('-port','65420','-work_dir',('"'+$run+'"')) -WorkingDirectory $run -WindowStyle Hidden | Out-Null
 Start-Sleep -Seconds 2
}
$log=Join-Path $run 'program.log'
& $tool -file (Join-Path $PSScriptRoot 'Program-V4S.tcl') *> $log
$exitCode=$LASTEXITCODE;$text=Get-Content -LiteralPath $log -Raw
if($exitCode -ne 0 -or $text -notmatch 'COMMAND\[Program\] execute successfully' -or $text -match 'execute fail|exec failed|Can not open file|Fail to compare'){throw "Programming failed: $log"}
$verifyPassed=$text -match 'COMMAND\[Verify\] execute successfully'
[ordered]@{candidate='C V4S';sha256='3e3475d30e6fa2488a57a084aa236353077b91d80969b7d1c412c89c064d1b50';program_passed=$true;verify_passed=$verifyPassed;flash_modified=$false;log=$log} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $run 'receipt.json') -Encoding utf8
Write-Output "PROGRAM_PASS verify_passed=$verifyPassed CRAM_only=True log=$log"
