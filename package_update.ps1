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

# Vérification de la compatibilité du système :
$os = Get-WmiObject -Class Win32_OperatingSystem
if ($os.Version -ge "10") {
    Write-Output "`n[INFO] Ce script est compatible avec votre version d'OS (windows 11).`n"
} else {
    Write-Output -ForegroundColor Red "`n[ERREUR] Ce script est incompatible avec votre version d'OS (windows 11).`n"
    Start-Sleep -Seconds 5
    exit 1
}

# Déclaration des variables :
$packages = winget list
$packages_updates = @()

foreach ($package in $packages) {
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
        $packages_updates += $package_object
    }
}

# Affiche la liste des paquets à mettre à jour :
if ($packages_updates.Name -eq $null) {
    Write-Host -ForegroundColor Green "[INFO] Félicitatez-vous ! Vos logiciels gérés par winget sont tous à jour.`n"
    Write-Host -ForegroundColor Yellow "[WARNING] Powershell ne pourra jamais être mis à jour avec ce script. Pensez à le vérifier.`n"
    #exit 0
} else {
    Write-Host -ForegroundColor Yellow "[WARNING] Les logiciels suivants ne sont pas à jour :`n$packages_updates.Name`n"
}

Write-Host "Inscrivez un chiffre selon l'action que vous souhaitez lancer :`n1. Exécuter les mises à jour`n2. Fermer le script`n"
$choice = Read-Host "Saisissez un chiffre " 

# Vérifier le choix de l'utilisateur
switch ($choice) {
    1 { Write-Host "`n[INFO] Les paquets sont en cours de mise à jour`n" ; winget update --all -h --disable-interactivity }
    2 { Write-Host "`n[INFO] Le script se fermera dans 10 secondes.`n" ; Start-Sleep -Seconds 10 ; exit 1 }
    default { Write-Output "Choix non valide" }
}

Write-Host -ForegroundColor Green "`n[INFO] Les paquets ont été mis à jour.`n"

Write-Host "[INFO] Fermeture du script dans 10 secondes."
Start-Sleep -Seconds 10
exit 0

# winget list --upgrade-available
