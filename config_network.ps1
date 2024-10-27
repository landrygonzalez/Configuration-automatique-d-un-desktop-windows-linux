<#
.SYNOPSIS
    Reconfiguration automatique de l'interface réseau d'administration.

.DESCRIPTION
    Désactivation de l'ipv6 (nécessaire à l'"anonymat" sur internet).

.PARAMETER 
    Aucun

.NOTES
    

.EXECUTION
    .\config_network.ps1

.REPOSITORY
    https://github.com/landrygonzalez/Configuration-automatique-d-un-desktop-windows-linux/
#>


################################
# I. DECLARATION DES VARIABLES #
################################

#variable_nom_1 = valeur
#commande # Commentaire unitaire
# Commentaire de chapitre :
<#
commande1
commande2
commande3
#>

$nom_interface_toutes = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -Property Name # Liste toutes les interfaces réseaux qui sont up.

# Pour chaque interface réseau up, vérifier si l'IPv6 est présente :
Foreach ($nom_interface in $nom_interface_toutes){
    #Write-Host $nom_interface
    Get-NetIPInterface -InterfaceAlias $nom_interface.Name | Where-Object {$_.AddressFamily -eq "IPv6"}
    #Get-NetIPInterface -InterfaceAlias $nom_interface.Name -AddressFamily IPv6
}
Disable-NetAdapterBinding -Name "Wi-Fi" -ComponentID ms_tcpip6


#################################
# II. DECLARATION DES FONCTIONS #
#################################

<#
function nom_fonction {

    Write-Host @"
###################################################################
# TITRE FONCTION - Description #######################################
###################################################################
“@
    Inscrire ici la fonction

}
#>


############################
# III. FONCTION PRINCIPALE #
############################

function main {
    Clear-Host
    # Fonction1
    # Fonction2
}

main
exit 0

<#
Stop-Transcript
} catch {
    Write-Output "An error occurred: $_"
}
#>

<#
try {
    Start-Transcript -Path "C:\temp\error_log.txt"
    Le code que tu soupçonnes de causer l'erreur
#>
      
<# 
Vérifier si le script s'exécute en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Si ce n'est pas le cas, relancer le script avec les droits administratifs
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
    exit
}
#>

