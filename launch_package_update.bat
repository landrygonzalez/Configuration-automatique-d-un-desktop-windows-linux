<#
$arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`""
#Start-Process PowerShell -ArgumentList $arguments -Verb RunAs

# Définir le chemin du fichier
$filePath = "C:\Program Files\PowerShell\7\pwsh.exe"

if (Test-Path $filePath) {
    Start-Process -FilePath "pwsh.exe" -ArgumentList "-ExecutionPolicy Bypass -File ${HOME}\Downloads\package_update.ps1" -Verb RunAs
} else {
    Write-Host "Powershell version 7 n'existe pas."
}
#>

@echo off
set "filePath=C:\Program Files\PowerShell\7\pwsh.exe"

if exist "%filePath%" (
    start "" "%filePath%" -ExecutionPolicy Bypass -File "%USERPROFILE%\Downloads\package_update.ps1"
) else (
    echo PowerShell version 7 n'existe pas. Le script va se fermer.
)
timeout 10
