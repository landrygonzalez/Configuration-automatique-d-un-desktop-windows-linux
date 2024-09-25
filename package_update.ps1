<#
.SYNOPSIS
    Ce script vérifie les mises à jour des packages installés via winget.

.DESCRIPTION
    Ce script utilise la commande winget pour lister les packages installés, vérifie les mises à jour disponibles,
    et affiche les packages avec des mises à jour disponibles.

.PARAMETER None

.NOTES
    cf. "Affichage des informations de versioning lors de l'exécution du script"

.EXAMPLE
    .\package_update.ps1

.LINK
    https://github.com/landrygonzalez/

#>

# Le script devrait se lancer en mode administrateur.
# Il faudrait indiquer à l'utilisateur la liste des applications dont la source n'est pas winget

# Nettoie l'invite de commande de l'interprêteur afin de repartir à zéro:
Clear-Host

#try {
#    Start-Transcript -Path "C:\temp\error_log.txt"
    # Le code que tu soupçonnes de causer l'erreur

###############################
# INFORMATIONS DE VERSIONNING #
###############################

Write-Host "####################################"
Write-Host "Nom du script : package_update.ps1"
Write-Host "Version : 1.1"
Write-Host "Auteur : Landry Gonzalez"
Write-Host "Date de création: 20/06/2024"
Write-Host "Dernière mise à jour : 17/09/2024"
Write-Host "Contact : landry.gonzalez@gmail.com"
Write-Host "####################################"

<## Vérifier si le script s'exécute en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Si ce n'est pas le cas, relancer le script avec les droits administratifs
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
    exit
}#>

#############################
# DECLARATION DES VARIABLES #
#############################

$list_packages = winget list    # Liste des applications installées sur le système, qu'elles soient sourcées par winget ou non
$list_packages_updates = @()    # Défini la variable qui contiendra la liste des applications bénéficiant d'une mise à jour comme un tableau vide
$os_release = (Get-WmiObject -Class Win32_OperatingSystem).Version    # Version du système d'exploitation
$os_release_min = "10"
$powershell_release = $PSVersionTable.PSVersion.Major     # Version de l'interface powershell qui fait office d'environnement pour le script
$powershell_release_min = "7"
$choco_installed = (Get-Command choco.exe).Name
$choco_version = (choco -v)

function choco_install_check {
    # Vérifie si chocolatey est installé. 
    if ($choco_installed -ne $null){
        Write-Host "Chocolatey est installé en version "$choco_version".`n`n"
    } else {
        Write-Host "Chocolatey n'est pas installé.`n`n"
        Write-Host "Que voulez vous faire ? Inscrivez le chiffre correspondant à votre choix :`n1. Installer Chocolatey`n2. Ne pas installer Chocolatey et utiliser winget`n`n"
        $choco_install_choice = Read-Host ""
        switch ($choco_install_choice) {
            1 { choco_install }
            2 { winget_compatibility }
            default { Write-Output "Choix non valide" }
        }
    }
}

function choco_install {
    ##############################
    # INSTALLATION DE CHOCOLATEY #
    ##############################
    Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
}

function winget_compatibility {
    ################################################
    # VERIFICATION DE LA COMPATIBILITE POUR WINGET #
    ################################################

    # Vérifie que les versions minimales du système d'exploitation et de l'interprêteur de commandes sont compatibles avec le script.
    if ($os_release -ge $os_release_min) {
        $os_ko = "1"
    }
    if ($powershell_release -ge $powershell_release_min) {
        $powershell_ko = "1"
    }

    if ($os_ko -eq "1" -or $powershell_ko -eq "1"){
        Write-Host -ForegroundColor Red "[CRITICAL] Un des prérequis à l'exécution de ce script n'est pas conforme :`n`tLe système d'exploitation windows est en version $os_release, et il devrait être en version $os_release_min au minimum.`n`tL'interprêteur powershell est en version $powershell_release, et il devrait être en version $powershell_release_min au minimum.`n`n"
        Write-Host -ForegroundColor Red "Fermeture du script ..."
        Start-Sleep -Seconds 20
        exit 1
    } else {
        Write-Host -ForegroundColor Green "`n[INFO] Tous les prérequis à l'exécution de ce script sont conformes :`n`tLe système d'exploitation windows est en version $os_release, et il devrait être en version $os_release_min au minimum.`n`tL'interprêteur powershell est en version $powershell_release, et il devrait être en version $powershell_release_min au minimum.`n`n"
        Start-Sleep -Seconds 20
    }
}
            
#Write-Host "Chocolatey n'est pas installé. Le script va donc prioriser winget.`n`nPour l'installer, accédez à l'url suivante :`nhttps://chocolatey.org/install"


##############################
# VERIFICATION DES PREREQUIS #
##############################
choco_install_check
# Ou lancer chocolatey
winget_compatibility


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
        $list_packages_updates += $package_object.Name
        # Il faudrait mettre ce résultat sous forme de tableau avec un formattage propre, si pas le cas.
    }
}


##################################
# INTERACTION AVEC L'UTILISATEUR #
##################################

# Affiche la liste des paquets à mettre à jour :
if ($list_packages_updates.count -eq 0) {
    Write-Host -ForegroundColor Green "`n[INFO] Vos logiciels gérés par winget sont tous à jour, vous n'avez rien à faire.`n"
    # Inutile car on vérifie la version powershell en début : Write-Host -ForegroundColor Yellow "[WARNING] L'application powershell ne pourra jamais être mise à jour avec ce script. Pensez donc à vérifier sa version.`n"
    Write-Host "[INFO] Fermeture du script dans 10 secondes."
    Start-Sleep -Seconds 10
    exit 0
} else {
    Write-Host -ForegroundColor Yellow "[WARNING] Les applications suivantes ne sont pas à jour :`n" $list_packages_updates "`n"
    Write-Host "Inscrivez le chiffre correspondant à l'action que vous souhaitez exécuter :`n1. Exécuter les mises à jour`n2. Fermer le script`n"
    Write-host $list_packages_updates
    $choice = Read-Host "Saisissez un chiffre " 
}


############################
# INSTALLATION DES PAQUETS #
############################

# Vérifier le choix de l'utilisateur
switch ($choice) {
    1 { Write-Host "`n[INFO] Les paquets sont en cours de mise à jour`n" ; winget update --all -h --disable-interactivity }
    2 { Write-Host "`n[INFO] Le script se fermera dans 10 secondes.`n" ; Start-Sleep -Seconds 10 ; exit 0 }
    default { Write-Output "Choix non valide" }
}

Write-Host -ForegroundColor Green "`n[INFO] Les paquets ont été mis à jour.`n"


#################################
# PAQUET NON SOURCES PAR WINGET #
#################################

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

Write-Host "[INFO] Fermeture du script dans 10 secondes."
Start-Sleep -Seconds 10

#Stop-Transcript
#} catch {
#    Write-Output "An error occurred: $_"
#}

exit 0