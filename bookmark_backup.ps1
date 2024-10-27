<#
.SYNOPSIS
    Description rapide

.DESCRIPTION
    Description complète

.PARAMETER 
    Liste des paramètres

.NOTES
    cf. "Affichage des informations de versioning lors de l'exécution du script"

.EXECUTION
    .\script.ps1

.REPOSITORY
    Url dépôt Github
#>


##############################
# DECLARATION DES VARIABLES #
##############################

$current_user_name = $env:USERNAME # Affiche le nom d'utilisateur actuel

# Définir les chemins d'accès aux fichiers de signets :
$chromeBookmarksPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
$firefoxBookmarksPath = "$env:LOCALAPPDATA\Roaming\Mozilla\Firefox\Profiles"
$edgeBookmarksPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"

#######
# VERIFICATION LES FICHIERS DE MARQUES PAGES #
#######

# [Chrome] Vérifier si le fichier de marques pages existe :
if (Test-Path $chromeBookmarksPath) {
    # Sauvegarder les signets Chrome
    Write-Host "Sauvegarde des signets Chrome..."
    Copy-Item -Path $chromeBookmarksPath -Destination "C:\Users\$current_user_name\Documents\ChromeBookmarks.html" -Force
} else {
    Write-Warning "Fichier de signets Chrome introuvable : $chromeBookmarksPath"
}

# [Firefox] Vérifier si le fichier de marques pages existe
if (Test-Path $firefoxBookmarksPath) {
    # Sauvegarder les signets Firefox
    Write-Host "Sauvegarde des signets Firefox..."
    Copy-Item -Path $firefoxBookmarksPath -Filter "Bookmarks" -Destination "C:\Users\$current_user_name\Documents\FirefoxBookmarks.html" -Force
} else {
    Write-Warning "Fichier de signets Firefox introuvable : $firefoxBookmarksPath"
}

# Vérifier si le fichier de signets Edge existe
if (Test-Path $edgeBookmarksPath) {
    # Sauvegarder les signets Edge
    Write-Host "Sauvegarde des signets Edge..."
    Copy-Item -Path $edgeBookmarksPath -Destination "C:\Users\$current_user_name\Documents\EdgeBookmarks.html" -Force
} else {
    Write-Warning "Fichier de signets Edge introuvable : $edgeBookmarksPath"
}

# Fin du script
Write-Host "Sauvegarde des signets terminée."
