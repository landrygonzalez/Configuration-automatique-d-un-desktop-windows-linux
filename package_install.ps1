# Lire le contenu du fichier chocolatey.txt
$content_chocolatey = Get-Content -File chocolatey.txt

# Exécuter les commandes du fichier.
. $content_chocolatey

# Si chocolatey n'est pas installé, effectuer l'installation :
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

# Afficher les paquets pas à jour : 
$package_to_update = choco outdated

# Sépare la ligne en lignes individuelles :
$lines = $package_to_update -split "`n"

<#
# Filtre les lignes pertinentes (celles contenant les informations sur les paquets)
# Ignore les premières lignes d'entête
$package_info_lines = $lines | Where-Object { $_ -match '^\S+\s+\S+\s+\S+' }

# Initialiser un tableau pour stocker les informations des paquets
$packages = @()

# Parcourt chaque ligne d'information sur les paquets
foreach ($line in $package_info_lines) {
    # Utilise une expression régulière pour extraire les informations du paquet
    if ($line -match '^(?<name>\S+)\s+(?<current_version>\S+)\s+(?<available_version>\S+)\s*(?<pinned>\S*)$') {
        $package = [PSCustomObject]@{
            Name             = $matches['name']
            CurrentVersion   = $matches['current_version']
            AvailableVersion = $matches['available_version']
            Pinned           = $matches['pinned']
        }
        $packages += $package
    }
}

# Affiche les informations des paquets non à jour
$packages | Format-Table -AutoSize

# Si vous souhaitez retourner les objets pour un usage ultérieur, vous pouvez décommenter la ligne suivante
# return $packages #>

# Si paquet à mettre à jour alors : 
# Si choco pas à jour, mettre à jour Chocolatey :
choco upgrade chocolatey
choco upgrade all -y
