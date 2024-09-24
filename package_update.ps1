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
$os_release = Get-WmiObject -Class Win32_OperatingSystem    # Version du système d'exploitation
$powershell_release = $PSVersionTable.PSVersion.Major     # Version de l'interface powershell qui fait office d'environnement pour le script


####################################
# VERIFICATION DE LA COMPATIBILITE #
####################################
# Winget ne peut fonctionner que sur certains systèmes d'exploitation et interfaces powershell.

# Vérifie que le système d'exploitation est compatible.
if ($os_release.Version -ge "10") {
    Write-Output -ForegroundColor Green "`n[INFO] Ce système d'exploitation (version windows 11) est compatible avec ce script.`n"
    # Vérifie que l'interface powershell est compatible.
    if ($powershell_release -ge “7”) {
        Write-Output -ForegroundColor Green "`n[INFO] Cette interface powershell (version égale ou supérieure à 7) est compatible avec ce script.`n"
    } else {
        Write-Output -ForegroundColor Red "`n[ERREUR] Cette interface powershell (version inférieure à 7) est incompatible avec ce script.`nCe dernier va donc se fermer dans 10 secondes."
        Start-Sleep -Seconds 10
        exit 1
    }
} else {
    Write-Output -ForegroundColor Red "`n[ERREUR] Ce système d'exploitation (version autre que windows 11) est incompatible avec ce script.`nCe dernier va donc se fermer dans 10 secondes."
    Start-Sleep -Seconds 10
    exit 1
}


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
    Write-Host -ForegroundColor Green "[INFO] Félicitatez-vous ! Vos logiciels gérés par winget sont tous à jour.`n"
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
exit 0
