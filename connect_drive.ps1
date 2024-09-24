# Définissez le chemin du fichier de configuration :
$config_file = "list_drive.txt"

# Vérifiez si le fichier de configuration existe :
if (-Not (Test-Path $config_file)) {
    Write-Host "Le fichier de configuration $config_file est introuvable."
    Start-sleep -Seconds 5
    exit 1
}

<#
# Fonction pour vérifier si une lettre de lecteur est déjà utilisée
function letter_usage {
    param (
        [string]$drive_letter
    )
    $drives = Get-PSDrive -PSProvider FileSystem
    return $drives.Name -contains $drive_letter
}
#>

# Lisez le contenu du fichier de configuration :
$content_config = Get-Content $config_file

# Vérifiez si le fichier de configuration est vide :
if ($content_config.Count -eq 0) {
    Write-Host "Le fichier de configuration network_drives.txt est vide."
    Start-sleep -Seconds 5
    exit 1
}

# Lisez le fichier de configuration ligne par ligne
$content_config | ForEach-Object {
    # Divisez chaque ligne en lettre de lecteur et chemin réseau
    $parts = $_ -split ":"
    $drive_letter = $parts[0].Trim()
    $path_network = $parts[1].Trim()

    # Montez le lecteur réseau
    Write-Host "Montage du lecteur $drive_letter vers $path_network"
    New-PSDrive -Name $drive_letter -PSProvider FileSystem -Root $path_network -Persist
}

# Fin du script
Write-Host "Tous les lecteurs réseau ont été montés : "
Get-PSDrive

# https://www.it-connect.fr/chapitres/creer-un-lecteur-reseau-en-powershell/
