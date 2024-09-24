rem $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`""
rem #Start-Process PowerShell -ArgumentList $arguments -Verb RunAs

rem # Définir le chemin du fichier
rem $filePath = "C:\Program Files\PowerShell\7\pwsh.exe"
 
rem if (Test-Path $filePath) {
rem    Start-Process -FilePath "pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File ${HOME}\Downloads\package_update.ps1" -Verb RunAs
rem } else {
rem    Write-Host "Powershell version 7 n'existe pas."
rem }
rem #>

@echo off
set "filePath=C:\Program Files\PowerShell\7\pwsh.exe"

if exist "%filePath%" (
    start "" "%filePath%" -ExecutionPolicy Bypass -File "%USERPROFILE%\Downloads\package_update.ps1"
) else (
    echo PowerShell version 7 n'existe pas. Le script va se fermer.
)
timeout 10
