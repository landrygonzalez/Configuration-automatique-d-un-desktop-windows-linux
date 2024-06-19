$packages = winget list
$packages_updates = @()
$packages = $packages # | Select-Object -Skip 1
    # -Skip 1 retire la 1ère ligne

foreach ($package in $packages) {
    # Diviser la ligne en colonnes
    $columns = $package -split '\s{2,}' # Split by two or more spaces
    # Créer un objet personnalisé pour représenter le package
    $package_object = [PSCustomObject]@{
        Name       = $columns[0]
        Id         = $columns[1]
        Version    = $columns[2]
        Available  = $columns[3]
        Source     = $columns[4]
    }

    # Vérifier si la colonne "Disponible" contient une valeur
    if ($columns.Length -ge 4 -and $columns[3] -ne '' -and $columns[3] -ne "winget" -and $columns[2] -ne "Version") {
        # Ajouter le package à la liste des packages avec mises à jour disponibles
        $packages_updates += $package_object
    }
}

Write-Host "Les logiciels suivants vont être mis à jour : "
$packages_updates.Name

$choice = Read-Host "Faites votre choix (1. Poursuivre ; 2. Arrêter le script) "

# Vérifier le choix de l'utilisateur
switch ($choice) {
    1 { Write-Output "Poursuite du process" }
    2 { Write-Output "Arrêt du process" }
    default { Write-Output "Choix non valide" }
}

if ($choice -eq "1") {
    winget update --all -h
} else {
    exit 1
}

<#
$packages = winget list
$packages_updates = @()
$packages = $packages | Select-Object -Skip 1
    # -Skip 1 retire la 1ère ligne

foreach ($package in $packages) {
    # Diviser la ligne en colonnes
    $columns = $package -split '\s{2,}' # Split by two or more spaces

    # Vérifier si la colonne "Disponible" contient une valeur
    if ($columns.Length -ge 4 -and $columns[3] -ne '' -and $columns[3] -ne "winget") {
        # Ajouter le package à la liste des packages avec mises à jour disponibles
        $packagesWithUpdates += $package
    }
}

$var = $packagesWithUpdates | ForEach-Object { Write-Output $_.Nom }

echo $var 
#>
