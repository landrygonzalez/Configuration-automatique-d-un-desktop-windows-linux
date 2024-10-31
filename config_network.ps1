<#
.SYNOPSIS
    Reconfiguration automatique de l'interface réseau d'administration.

.DESCRIPTION
    Désactivation de l'ipv6 (nécessaire à l'"anonymat" sur internet).

.PARAMETER 
    Aucun

.NOTES
    Faire évoluer en ajoutant la configuration DHCP ou IP puis lancer un scan réseau avec Test-NetConnection -ComputerName <adresse_ip> -Port <numéro_de_port>

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

# Liste les interfaces réseaux connectées :
$name_interface_all = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } | Select-Object -Property Name
[array]$interface_ipv6_all = @()

###########################
# II. FONCTION PRINCIPALE #
###########################

function main {

    Write-Host "Vous avez" $name_interface_all.Count "interface(s) réseau(x) de connectée(s)."
    
    if ($name_interface_all.Count -gt 1){
        Write-Host "Vous ne devriez avoir qu'une seule interface réseau pour votre accès Internet, sauf dans les cas suivants :`n
        - Vous vous connectez à votre réseau par ondes wifi à certains moments et par câble réseau à d'autres instants.
        - Vous utilisez un VPN, lequel vous créera des interfaces virtuelles pour son fonctionnement.
        - Vous avez installé un hyperviseur pour créer des machines virtuelles, lequel a besoin d'interfaces virtuelles.`n"
        Read-Host "Contactez votre administrateur pour envisager de les désactiver.`nPressez ensuite une touche pour poursuivre l'exécution du script."
    } elseif ($name_interface_all.Count -lt 1) {
        Write-Host "Le script a rencontré une erreur. Contactez le développeur du script."
        Start-Sleep -Seconds 3
        exit 1
    }

    # Pour chaque interface réseau, vérifier si l'IPv6 est présente :
    Foreach ($name_interface in $name_interface_all){
        #Write-Host $nom_interface
        $interface_ipv6 = Get-NetIPInterface -InterfaceAlias $name_interface.Name | Where-Object {$_.AddressFamily -eq "IPv6"} | Select-Object -Property InterfaceAlias
        $interface_ipv6_all += $interface_ipv6.InterfaceAlias
        #Get-NetIPInterface -InterfaceAlias $nom_interface.Name -AddressFamily IPv6
    }

    Write-Host "Aïe, l'IPv6 est activée sur $interface_ipv6_all.`n Voulez-vous désactiver l'IPv6 sur toutes ces interfaces ?"
    Read-Host "Approuvez en appuyant sur une touche."
    
    Foreach ($name_interface in $interface_ipv6_all){
        Disable-NetAdapterBinding -Name $name_interface -ComponentID ms_tcpip6
    }

    [array]$interface_ipv6_all = @()
    Foreach ($name_interface in $name_interface_all){
        #Write-Host $nom_interface
        $interface_ipv6 = Get-NetIPInterface -InterfaceAlias $name_interface.Name | Where-Object {$_.AddressFamily -eq "IPv6"} | Select-Object -Property InterfaceAlias
        $interface_ipv6_all += $interface_ipv6.InterfaceAlias
        #Get-NetIPInterface -InterfaceAlias $nom_interface.Name -AddressFamily IPv6
    }

    Write-Host "L'IPv6 est activée sur $interface_ipv6_all. S'il y a un problème, contactez le développeur du script."
    Start-Sleep -Seconds 5
}

main

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

