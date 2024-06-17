# Définition des variables :
$currentUserName = $env:USERNAME # Obtenir le nom d'utilisateur actuel
# Définir les chemins d'accès aux fichiers de signets :
$chromeBookmarksPath = "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Bookmarks"
$firefoxBookmarksPath = "$env:LOCALAPPDATA\Roaming\Mozilla\Firefox\Profiles"
$edgeBookmarksPath = "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Bookmarks"

# Vérifier si le fichier de signets Chrome existe
if (Test-Path $chromeBookmarksPath) {
    # Sauvegarder les signets Chrome
    Write-Host "Sauvegarde des signets Chrome..."
    Copy-Item -Path $chromeBookmarksPath -Destination "C:\Users\$currentUserName\Documents\ChromeBookmarks.html" -Force
} else {
    Write-Warning "Fichier de signets Chrome introuvable : $chromeBookmarksPath"
}

# Vérifier si le fichier de signets Firefox existe
if (Test-Path $firefoxBookmarksPath) {
    # Sauvegarder les signets Firefox
    Write-Host "Sauvegarde des signets Firefox..."
    Copy-Item -Path $firefoxBookmarksPath -Filter "Bookmarks" -Destination "C:\Users\$currentUserName\Documents\FirefoxBookmarks.html" -Force
} else {
    Write-Warning "Fichier de signets Firefox introuvable : $firefoxBookmarksPath"
}

# Fin du script
Write-Host "Sauvegarde des signets terminée."
