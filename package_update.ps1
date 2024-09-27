<#
.SYNOPSIS
    Ce script vérifie les mises à jour des packages installés via winget.

.DESCRIPTION
    Ce script utilise la commande winget pour lister les packages installés, vérifie les mises à jour disponibles,
    et affiche les packages avec des mises à jour disponibles.

.PARAMETER 
    None

.NOTES
    cf. "Affichage des informations de versioning lors de l'exécution du script"

.EXAMPLE
    .\package_update.ps1

.LINK
    https://github.com/landrygonzalez/
#>


#############################
# DECLARATION DES VARIABLES #
#############################

$list_packages = winget list    # Liste des applications installées sur le système, qu'elles soient sourcées par winget ou non
$list_packages_updates = @()    # Défini la variable qui contiendra la liste des applications bénéficiant d'une mise à jour comme un tableau vide
$os_release = (Get-WmiObject -Class Win32_OperatingSystem).Version    # Version du système d'exploitation
$os_release_min = "10.0.22"
$powershell_release = $PSVersionTable.PSVersion.Major     # Version de l'interface powershell qui fait office d'environnement pour le script
$powershell_release_min = "7"
$choco_installed = (Get-Command choco.exe).Name
$choco_version = (choco -v)


#############################
# DECLARATION DES FONCTIONS #
#############################

function choco_install_check {

    Write-Host @"
###################################################################
# CHOCOLATEY - Vérification de l'installation #####################
###################################################################

"@
    Start-Sleep -Seconds 2
    if ($null -ne $choco_installed){
        Write-Host -ForegroundColor Blue "[INFO] Chocolatey est installé en version"$choco_version".`n"
        Start-Sleep -Seconds 2
    } else {
        Write-Host -ForegroundColor Yellow "[WARNING] Chocolatey n'est pas installé.`n"
        Start-Sleep -Seconds 2
        Write-Host -ForegroundColor Magenta @"
[INTERACTION] Que voulez vous faire ? Entrez le chiffre correspondant à votre choix :
    1. Installer Chocolatey (fonctionnalité désactivée le 26/09/2024, développement en cours)
    2. Rester sur Winget
"@
        $choco_install_choice = Read-Host ""
        switch ($choco_install_choice) {
            1 { Write-Host -ForegroundColor Red "[CRITICAL] Choix invalide"; Start-Sleep -Seconds 2; choco_install_check } # { choco_install }
            2 { winget_compatibility }
            default { Write-Host -ForegroundColor Red "[CRITICAL] Choix invalide"; Start-Sleep -Seconds 2; choco_install_check }
        }
    }
}

function choco_install {

    Write-Host @"
###################################################################
# CHOCOLATEY - Installation #######################################
###################################################################

"@

    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function winget_compatibility {

    Write-Host @"
###################################################################
# WINGET - Vérification des pré-requis ############################
###################################################################

"@
    Start-Sleep -Seconds 3

    # Vérifie que les versions minimales du système d'exploitation et de l'interprêteur de commandes sont compatibles avec le script.
    if ($os_release_min -gt $os_release) {
        $os_ko = "1"
    } else {
        $os_ko = "0"
    }
    
    if ($powershell_release_min -gt $powershell_release) {
        $powershell_ko = "1"
    } else {
        $powershell_ko = "0"
    }

    if ($os_ko -eq "1" -or $powershell_ko -eq "1"){
        Write-Host -ForegroundColor Red @'
[CRITICAL] Un des prérequis à l'exécution de ce script n'est pas conforme :
    - Le système d'exploitation windows est en version $os_release (doit être en version $os_release_min au minimum).
    - L'interprêteur powershell est en version $powershell_release (doit être en version $powershell_release_min au minimum).

'@
        # Compte à rebours
        for ($i = 9; $i -gt 0; $i--) {
            Write-Host -ForegroundColor Blue "[INFO] Fermeture du script dans $i secondes" -NoNewline
            Start-Sleep -Seconds 1  # Pause d'une seconde
            Write-Host "`r" -NoNewLine  # Retour au début de la ligne
        }
        Start-Sleep -Seconds 1
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
        Write-Host "`n"
        exit 1
    } else {
        Write-Host -ForegroundColor Green @"
[SUCCESS] Tous les prérequis à l'exécution de ce script sont conformes :
    - Le système d'exploitation windows est en version $os_release (doit être en version $os_release_min au minimum).
    - L'interprêteur powershell est en version $powershell_release (doit être en version $powershell_release_min au minimum).

"@
        # Compte à rebours
        for ($i = 5; $i -gt 0; $i--) {
            Write-Host -ForegroundColor Blue "[INFO] Poursuite du script dans $i secondes" -NoNewline
            Start-Sleep -Seconds 1  # Pause d'une seconde
            Write-Host "`r" -NoNewLine  # Retour au début de la ligne
        }
    Write-Host -ForegroundColor Blue "[INFO] Fin du compte à rebours, l'exécution du script se poursuit." -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    }
}

function write_host_exit {
    for ($i = 3; $i -gt 0; $i--) {
        Write-Host -ForegroundColor Blue "[INFO] Le script se fermera dans $i secondes." -NoNewline
        Start-Sleep -Seconds 1  # Pause d'une seconde
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    }
    exit 0
}
            
#Write-Host "Chocolatey n'est pas installé. Le script va donc prioriser winget.`n`nPour l'installer, accédez à l'url suivante :`nhttps://chocolatey.org/install"

function list_package {

#####################
# LISTE LES PAQUETS #
#####################

    # Liste les paquets avec la commande winget.
    foreach ($package in $list_packages) {
        # Segmente une ligne (qui représente les informations d'un paquet) en plusieurs colonnes. Le séparateur est 2 occurences ou plus de caractère espace.
        $columns = $package -split '\s{2,}'
        #Write-Host $columns
        #Start-Sleep -Seconds 2
        # Crée un objet personnalisé pour nommer chaque colonne.
        $package_object = [PSCustomObject]@{
            Name = $columns[0]
            Id = $columns[1]
            Version = $columns[2]
            Available = $columns[3]
            Source = $columns[4]
        }
        #Write-Host $package_object
        # Vérifie si certaines colonnes contiennent des valeurs spécifiques.
        if ($columns.Length -ge 4 -and $columns[3] -ne '' -and $columns[3] -ne "winget" -and $columns[2] -ne "Version") {
        #if ($columns.Length -ge 4 -and $columns.Available -ne '' -and $columns.Available -ne "winget" -and $columns.Version[2] -ne "Version") {
            # Ajoute le paquet à la liste des paquets à mettre à jour.
            $global:list_packages_updates += $package_object.Name
            # Il faudrait mettre ce résultat sous forme de tableau avec un formattage propre, si pas le cas.
        }
    }
    Write-Host "`n"
    Start-Sleep -Seconds 1
}

function install_package {

    Write-Host @"
###################################################################
# WINGET - Installation des paquets ###############################
###################################################################

"@

    Start-Sleep -Seconds 1

    # Affiche la liste des paquets à mettre à jour :
    if ($list_packages_updates.count -eq 0) {
        Write-Host $list_packages_updates.count
        Write-Host -ForegroundColor Green "[SUCCESS] Vos logiciels gérés par winget sont déjà tous à jour, vous n'avez rien à faire.`n"
        # Inutile car on vérifie la version powershell en début : Write-Host -ForegroundColor Yellow "[WARNING] L'application powershell ne pourra jamais être mise à jour avec ce script. Pensez donc à vérifier sa version.`n"
        Start-Sleep -Seconds 1
        Write-Host -ForegroundColor Magenta "[INTERACTION] Appuyez sur une touche pour continuer...`n"
        [void][System.Console]::ReadKey($true)  # Attend que l'utilisateur appuie sur une touche

        # Compte à rebours
        for ($i = 5; $i -gt 0; $i--) {
            Write-Host -ForegroundColor Blue "[INFO] Vous avez appuyé sur une touche, le script se fermera dans $i secondes." -NoNewline
            Start-Sleep -Seconds 1  # Pause d'une seconde
            Write-Host "`r" -NoNewLine  # Retour au début de la ligne
        }
        exit 0
    } else {
        Write-Host -ForegroundColor Yellow "[WARNING] Les applications suivantes ne sont pas à jour :`n"
        $list_packages_updates
        Start-Sleep -Seconds 1
        Write-Host "`nInscrivez le chiffre correspondant à l'action que vous souhaitez exécuter :`n1. Exécuter les mises à jour`n2. Fermer le script`n"
        Start-Sleep -Seconds 1
        $choice = Read-Host "Saisissez un chiffre " 
    }

    # Vérifier le choix de l'utilisateur
    switch ($choice) {
        1 { Write-Host -ForegroundColor Blue "[INFO] Les paquets sont en cours de mise à jour`n" ; winget update --all -h --disable-interactivity }
        2 { write_host_exit }
        default { Write-Host -ForegroundColor Red "[CRITICAL] Choix invalide`n" ; Start-Sleep -Seconds 3 ; install_package }
    }

    Write-Host -ForegroundColor Green "[INFO] Les paquets ont été mis à jour.`n"
}

function packages_non_winget {

    Write-Host @"
###################################################################
# WINGET - Paquets non sourcés par Winget #########################
###################################################################

"@
    
    $list_packages_notWinget = @()
    foreach ($package in $list_packages) {
        # Divise la ligne en colonnes toutes les 2 occurences d'espace au minimum :
        $columns = $package -split '\s{2,}'
        # Crée un objet personnalisé pour nommer les colonnes :
        $package_object = [PSCustomObject]@{
            Name = $columns[0]
            Id = $columns[1]
            Version = $columns[2]
            Available = $columns[3]
            Source = $columns[4]
        }
        if ($package_object.Source -notlike "winget" -and $package_object.Available -notlike "winget" -and $package_object -notlike $null) {
            $list_packages_notWinget += $package_object.Name
        }
    }
    Write-Host -ForegroundColor Yellow "[WARNING] Les logiciels suivants n'ont pas été installés par winget :`n" $list_packages_updates "`n"

    for ($i = 20; $i -gt 0; $i--) {
        Write-Host -ForegroundColor Blue "[INFO] Fermeture du script dans $i secondes" -NoNewline
        Start-Sleep -Seconds 1  # Pause d'une seconde
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    }

}

function timing {

    # Compte à rebours
    for ($i = 3; $i -gt 0; $i--) {
        Write-Host -ForegroundColor Blue "[INFO] Poursuite du script dans $i secondes" -NoNewline
        Start-Sleep -Seconds 1
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    }
    Write-Host -ForegroundColor Blue "[INFO] Fin du compte à rebours, l'exécution du script se poursuit." -NoNewline
    Start-Sleep -Seconds 1
    Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    Write-Host "`n"

}

function main {

    Clear-Host

    Write-Host @'

###################################################################
# SCRIPT - Mise à jour des logiciels (fichier package_update.ps1) #
###################################################################
Nom du script .................................. package_update.ps1
Date de création ....................................... 20/06/2024
Version ....................................................... 1.2
Dernière mise à jour ................................... 26/09/2024
Auteur ............................................ Landry Gonzalez
Contact ................................. landry.gonzalez@gmail.com
###################################################################

'@
    timing
    choco_install_check    # Installe Chocolatey
    winget_compatibility    # Vérifie les prérequis de compatibilité pour winget
    list_package    
    install_package
    packages_non_winget
}

main
exit 0

#Stop-Transcript
#} catch {
#    Write-Output "An error occurred: $_"
#}

# Le script devrait se lancer en mode administrateur.
# Il faudrait indiquer à l'utilisateur la liste des applications dont la source n'est pas winget

#try {
#    Start-Transcript -Path "C:\temp\error_log.txt"
    # Le code que tu soupçonnes de causer l'erreur

<## Vérifier si le script s'exécute en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Si ce n'est pas le cas, relancer le script avec les droits administratifs
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
    exit
}#>
