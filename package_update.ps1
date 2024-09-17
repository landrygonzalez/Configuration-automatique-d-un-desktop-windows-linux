<#
.SYNOPSIS
    Ce script vérifie les mises à jour des packages installés via winget.

.DESCRIPTION
    Ce script utilise la commande winget pour lister les packages installés, vérifie les mises à jour disponibles,
    et affiche les packages avec des mises à jour disponibles.

.PARAMETER None

.NOTES
    Auteur : Landry Gonzalez
    Version : 1.0
    Date de création : 20/06/2024
    Dernière mise à jour : 20/06/2024
    Contact : landry.gonzalez@gmail.com

.EXAMPLE
    .\package_update.ps1

.LINK
    https://github.com/landrygonzalez/

#>

# Le script devrait se lancer en mode administrateur.
# Il faudrait indiquer à l'utilisateur la liste des applications dont la source n'est pas winget

# Nettoyage de l'invite de commande de l'interprêteur :
clear

# Affichage des informations de versioning lors de l'exécution du script :
Write-Host "---------------------------------------"
Write-Host "Nom du script : package_update.ps1"
Write-Host "Version : 1.0"
Write-Host "Auteur : Landry Gonzalez"
Write-Host "Date de création: 20/06/2024"
Write-Host "Dernière mise à jour : 20/06/2024"
Write-Host "Contact : landry.gonzalez@gmail.com"
Write-Host "---------------------------------------"

# Déclaration des variables :
$list_packages = winget list
$list_packages_updates = @()
$os_release = Get-WmiObject -Class Win32_OperatingSystem
$powershell_release = $PSVersionTable.PSVersion.Major

# Vérification de la compatibilité du système (version 10 = windows 11) :
if ($os_release.Version -ge "10") {
    Write-Output "`n[INFO] Ce script est compatible avec votre version d'OS (windows 11).`n"
} else {
    Write-Output -ForegroundColor Red "`n[ERREUR] Ce script est incompatible avec votre version d'OS (doit être windows 11) et va donc s'arrêter.`n"
    Start-Sleep -Seconds 10
    exit 1
}

# Vérification de la compatibilité de l'interface powershell (version majeure 7 minimum) :
if ($powershell_release -ge “7”) {
    Write-Output "`n[INFO] Cette interface powershell est compatible avec le script (version 7 ou supérieure).`n"
} else {
    Write-Output -ForegroundColor Red "`n[ERREUR] Ce script est incompatible avec votre interface powershell (doit être en version 7 minimum) et va donc s'arrêter.`n"
    Start-Sleep -Seconds 10
    exit 1
}

# Liste les paquets avec winget :
#$list_packages_updates = $null
foreach ($package in $list_packages) {
    #echo $package
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
    # Vérifie si la colonne "Available" contient une valeur :
    if ($columns.Length -ge 4 -and $columns[3] -ne '' -and $columns[3] -ne "winget" -and $columns[2] -ne "Version") {
        # Ajoute le package à la liste des packages à mettre à jour :
        $list_packages_updates += $package_object
    }
}

# Affiche la liste des paquets à mettre à jour :
if ($list_packages_updates.Name -eq $null) {
    Write-Host -ForegroundColor Green "[INFO] Félicitatez-vous ! Vos logiciels gérés par winget sont tous à jour.`n"
    # Inutile car on vérifie la version powershell en début : Write-Host -ForegroundColor Yellow "[WARNING] L'application powershell ne pourra jamais être mise à jour avec ce script. Pensez donc à vérifier sa version.`n"
    Write-Host "[INFO] Fermeture du script dans 10 secondes."
    Start-Sleep -Seconds 10
    exit 0
} else {
    Write-Host -ForegroundColor Yellow "[WARNING] Les logiciels suivants ne sont pas à jour :`n" $list_packages_updates.Name "`n"
}
# Il faudrait mettre ce résultat sous forme de tableau

Write-Host "Inscrivez un chiffre selon l'action que vous souhaitez lancer :`n1. Exécuter les mises à jour`n2. Fermer le script`n"
$choice = Read-Host "Saisissez un chiffre " 

# Vérifier le choix de l'utilisateur
switch ($choice) {
    1 { Write-Host "`n[INFO] Les paquets sont en cours de mise à jour`n" ; winget update --all -h --disable-interactivity }
    2 { Write-Host "`n[INFO] Le script se fermera dans 10 secondes.`n" ; Start-Sleep -Seconds 10 ; exit 1 }
    default { Write-Output "Choix non valide" }
}

Write-Host -ForegroundColor Green "`n[INFO] Les paquets ont été mis à jour.`n"

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
    # Vérifie si la colonne "Available" contient une valeur :
    if ($package_object.Source -notlike "winget" -and $package_object.Available -notlike "winget" -and $package_object -notlike $null) {
        # Ajoute le package à la liste des packages à mettre à jour :
        $list_packages_notWinget += $package_object.Name
        #echo $package_object && Start-Sleep 1
        #echo $list_packages_notWinget && Start-Sleep 1
    }
    Write-Host -ForegroundColor Yellow "[WARNING] Les logiciels suivants n'ont pas été installés par winget :`n" $list_packages_updates.Name "`n"
}

Write-Host "[INFO] Fermeture du script dans 10 secondes."
Start-Sleep -Seconds 10
exit 0

# winget list --upgrade-available
