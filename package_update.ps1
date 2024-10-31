<#
.SYNOPSIS
    Le script package_update.ps1 vérifie puis installe les mises à jour disponibles des paquets qui ont été installés par winget.

.DESCRIPTION
    None

.PARAMETER 
    None

.NOTES
    None

.EXAMPLE
    & .\package_update.ps1

.LINK
    https://github.com/landrygonzalez/Configuration-automatique-d-un-desktop-windows-linux
#>


### DECLARATION DES VARIABLES GLOBALES ###

$list_packages_to_update = @() # Liste des paquets avec une mise à jour disponible
$os_release = (Get-WmiObject -Class Win32_OperatingSystem).Version # Version de windows
$os_release_min = "10.0.22" # Versions windows minimale (correspond à windows 11)
$powershell_release = $PSVersionTable.PSVersion.Major # Version de powershell
$powershell_release_min = "7" # Version powershell minimale

# Mise à jour des sources winget :
winget source update


### AFFICHAGE DU VERSIONNING ###

function versionning {
    Clear-Host
    Write-Host @"
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

"@
timing_write -time 3
}


### VERIFICATION DE L'INSTALLATION DE CHOCOLATEY ###

function choco_check {

    Write-Host @"
###################################################################
# CHOCOLATEY - Vérification de l'installation #####################
###################################################################

"@
    Start-Sleep -Seconds 1

    $choco_installed = (Get-Command choco.exe).Name
    $choco_version = choco -v

    Start-Sleep -Seconds 1

    if ($null -ne $choco_installed){
        Write-Host -ForegroundColor Blue "[INFO] Chocolatey est installé (version"$choco_version").`n"
        Start-Sleep -Seconds 2
    } else {
        Write-Host -ForegroundColor Yellow "[WARNING] Chocolatey n'est pas installé.`n"
        Start-Sleep -Seconds 2
        Write-Host -ForegroundColor Magenta @"
[INTERACTION] Que voulez vous faire ? Entrez le chiffre correspondant à votre choix :
    1. Installer Chocolatey (fonctionnalité désactivée le 26/09/2024, développement en cours)
    2. Poursuivre avec Winget
"@
        $choice = Read-Host ""
        switch ($choice) {
            # 1 { choco_install } Désactivé car développement en cours.
            2 { winget_prerequisite }
            default { Write-Host -ForegroundColor Red "[CRITICAL] Choix invalide"; Start-Sleep -Seconds 2; choco_check }
        }
    }
}


### INSTALLATION DE CHOCOLATEY (DEVELOPPEMENT A FAIRE DEPUIS LE 29/09/2024) ###

function choco_install {

    Write-Host @"
###################################################################
# CHOCOLATEY - Installation #######################################
###################################################################

"@
    Start-Sleep -Seconds 2
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))

    #Write-Host "Chocolatey n'est pas installé. Le script va donc prioriser winget.`n`nPour l'installer, accédez à l'url suivante :`nhttps://chocolatey.org/install"

}


### VERIFICATION DES PRE-REQUIS ###

function winget_prerequisite {

    Write-Host @"
###################################################################
# WINGET - Vérification des pré-requis ############################
###################################################################

"@
    Start-Sleep -Seconds 2

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
        Start-Sleep -Seconds 2
        exit_error
    } else {
        Write-Host -ForegroundColor Green @"
[SUCCESS] Tous les prérequis à l'exécution de ce script sont conformes :
    - Le système d'exploitation windows est en version $os_release (doit être en version $os_release_min au minimum).
    - L'interprêteur powershell est en version $powershell_release (doit être en version $powershell_release_min au minimum).

"@
        Start-Sleep -Seconds 2
        timing_write -time 3
    }
}


### LISTE LES PAQUETS ###

function list_package_system {

    # Création du fichier dans $HOME et ajout à l'intérieur de la liste des paquets du système. 
    $date = Get-Date -Format "yyyyMMddHHmmss"
    $file_list_package = "$HOME\winget_list_package_system_${date}.txt"
    winget list > $file_list_package # "winget list" liste les applications installées sur le système (qu'elles aient été installées par winget ou un autre gestionnaire de paquets)
    #Start-Sleep -Seconds 5

    $list_packages = Get-Content -Path $file_list_package
    $global:list_packages_object = @()

    # Vérifie si le fichier ne contient pas de paquets à mettre à jour car la colonne Disponible rallonge chaque ligne et implique donc un traitement différent du fichier.
    if ($list_packages -notmatch 'Disponible\sSource') {

        # Itère sur chacune des lignes du fichier.
        foreach ($line in $list_packages) {

            $length = $line.length

            # Conditionne le flux seulement si la ligne ne contient pas les regex suivantes.
            if ($line -notmatch '^[-]+$' -and $line -notmatch '^\s*-\s*$|^\s*$' -and $line -notmatch '^\s*\\\s*$' -and $line -notmatch '^Nom\s+ID\s+Version') {
                
                if ($length -gt 50) {

                    $columns1 = $line.Substring(0,42)
                    $columns2 = $line.Substring(42,42)
                    $columns3 = $line.Substring(84,18)

                    # Récupère la longueur de la ligne (cette longueur commence au premier caractère et termine au dernier (en comptant les espaces au milieu))
                    if ($line -like "winget"<#$length -le 117#>) {

                        $package_object = [PSCustomObject]@{
                            Name = $columns1
                            Id = $columns2
                            Version = $columns3
                            Disponible = $null
                            Source = $null # Si la longueur est de maximum 112, cela signifie que la source n'existe pas. Il faut donc mettre la colonne Source à $null, afin qu'elle existe, mais qu'elle reste vide.
                        }

                        $list_packages_object += $package_object

                    } 
                    else {

                        $columns4 = $line.Substring(102,6)

                        $package_object = [PSCustomObject]@{
                            Name = $columns1
                            Id = $columns2
                            Version = $columns3
                            Disponible = $null
                            Source = $columns4
                        }

                        $list_packages_object += $package_object
                    }
                }
            }
        }
    } 

    # Si le fichier contient la colonne "Disponible".
    else {

        # Itère sur chacune des lignes du fichier.
        foreach ($line in $list_packages) {

            # Récupère la longueur de la ligne (cette longueur commence au premier caractère et termine au dernier (en comptant les espaces au milieu))
            $length = $line.length

            # Conditionne le flux seulement si la ligne ne contient pas les regex suivantes.
            if ($line -notmatch '^[-]+$' -and $line -notmatch '^\s*-\s*$|^\s*$' -and $line -notmatch '^\s*\\\s*$' -and $line -notmatch '^Nom\s+') {

                if ($length -gt 80) {

                    $columns1 = $line.Substring(0,42)
                    $columns2 = $line.Substring(42,42)
                    $columns3 = $line.Substring(84,18) # La colonne version peut s'arrêter avant la plage désignée
                    $columns4 = $line.Substring(102,11)

                    if ($line -like "winget") {

                        $columns5 = $line.Substring(119,6)
                        
                        $package_object = [PSCustomObject]@{
                            Name = $columns1
                            Id = $columns2
                            Version = $columns3
                            Disponible = $columns4
                            Source = $columns5
                        }

                        $list_packages_object += $package_object

                    }
                    <#elseif ($length -gt 117) {

                        

                        $package_object = [PSCustomObject]@{
                            Name = $columns1
                            Id = $columns2
                            Version = $columns3
                            Disponible = $columns4
                            Source = $columns5
                        }

                        $list_packages_object += $package_object
                    }#>
                }
            }
        }
    }

    $global:list_packages_to_update = @()
    $list_packages_to_update = $list_packages_object | Where-Object { $null -ne $_.Disponible } | Select-Object Name,Disponible | Format-Table

    <#  foreach ($object in $list_packages_to_update) {
        $global:list_packages_updates += $object
        Segmente une ligne (qui représente les informations d'un paquet) en plusieurs colonnes. Le séparateur est 2 occurences ou plus de caractère espace.
        $columns = $package -split '\s{2,}'
        $columns = $package -split '\s{2,}'
        Write-Host $columns
        Start-Sleep -Seconds 2
        Crée un objet personnalisé pour nommer chaque colonne.
    }
    Write-Host $package_object
    Vérifie si certaines colonnes contiennent des valeurs spécifiques.
    if ($columns.Length -ge 4 -and $columns[3] -ne '' ) {

    if ($object.Disponible -like "winget" -and $columns.Version[2] -ne "Version") {}
    if ($columns.Length -ge 4 -and $columns[3] -ne '' ) {}

    if ($object.Disponible -like "winget" -and $columns.Version[2] -ne "Version") {
        Ajoute le paquet à la liste des paquets à mettre à jour.
        
        $global:list_packages_updates += $package_object.Name
        
        $global:list_packages_updates += $package_object.Name
        Il faudrait mettre ce résultat sous forme de tableau avec un formattage propre, si pas le cas.
    }
    #>
    Start-Sleep -Seconds 1
}


### MISE A JOUR DES PAQUETS ###

function update_package_auto {

    Write-Host @"
###################################################################
# WINGET - Mise à jour automatique de tous les paquets ############
###################################################################

"@

    winget upgrade --all --include-unknown --disable-interactivity

    <#
    Start-Sleep -Seconds 1

    # Affiche la liste des paquets à mettre à jour :
    if ($list_packages_to_update.count -eq 0) {

        #Write-Host $list_packages_updates.count
        Write-Host -ForegroundColor Green "[SUCCESS] Vos logiciels gérés par winget sont déjà tous à jour, vous n'avez rien à faire.`n"
        # Inutile car on vérifie la version powershell en début : Write-Host -ForegroundColor Yellow "[WARNING] L'application powershell ne pourra jamais être mise à jour avec ce script. Pensez donc à vérifier sa version.`n"
        Start-Sleep -Seconds 1
        exit_no_error

    } else {

        Write-Host -ForegroundColor Yellow "[WARNING] Les applications suivantes ne sont pas à jour :`n"
        $list_packages_to_update
        $list_packages_to_update
        Start-Sleep -Seconds 1

        Write-Host "`nQuelle action souhaitez vous exécuter ?`n1. Exécuter les mises à jour`n2. Fermer le script`n"
        Start-Sleep -Seconds 1

        $choice = Read-Host "Inscrivez le chiffre correspondant et appuyez sur Entrée : " 
        Write-Host "`n"
        switch ($choice) {
            1 { Write-Host -ForegroundColor Blue "[INFO] Les paquets sont en cours de mise à jour`n" ; winget update --all -h --disable-interactivity }
            2 { exit_no_error }
            default { Write-Host -ForegroundColor Red "[CRITICAL] Choix invalide`n" ; Start-Sleep -Seconds 3 ; update_package_auto }
        }
    }

    Write-Host -ForegroundColor Green "[INFO] Les paquets ont été mis à jour.`n"#>
}


### WINGET - MISE A JOUR MANUELLE DES PAQUETS ###

function update_package_manual {

    Write-Host @"
###################################################################
# WINGET - Mise à jour manuelle des paquets #######################
###################################################################

"@

    for ($i = 2; $i -ge 0; $i--) {
        Write-Host -ForegroundColor Blue "[INFO] Les paquets sont en cours de mise à jour`n" -NoNewline
        Start-Sleep -Seconds 1  # Pause d'une seconde
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    }

    foreach ($object in $list_packages_to_update) {
        winget update $object --disable-interactivity
    }

}


### WINGET - PAQUETS NON SOURCES PAR WINGET ###

function packages_non_winget {

    Write-Host @"
###################################################################
# WINGET - Paquets non sourcés par Winget #########################
###################################################################

"@
    
    $global:list_packages_notWinget = @()
    foreach ($package in $list_packages) {
        # Divise la ligne en colonnes toutes les 2 occurences d'espace au minimum :
        $columns = $package -split '\.{,47}' #'\s{2,}'
        # Crée un objet personnalisé pour nommer les colonnes :
        $package_object = [PSCustomObject]@{
            Name = $columns[0]
            Id = $columns[1]
            Version = $columns[2]
            Available = $columns[3]
            Source = $columns[4]
        }
        #Write-Host $package_object
        # Teste si la propriété Source de l'objet n'est pas winget, et si Available n'a pas pris la valeur winget par erreur, et si le nom n'est pas vide.
        if ($package_object.Source -notlike "winget" -and $package_object.Available -notlike "winget" -and $package_object.Version -notlike "winget" -and $package_object.Name -notlike $null) {
            $list_packages_notWinget += $package_object.Name
            #Write-Host $package_object.Name
        }
    }
    #Write-Host $list_packages_notWinget
    Write-Host -ForegroundColor Yellow "[WARNING] Les logiciels suivants n'ont pas été installés par winget :`n`n"
    $list_packages_notWinget

    for ($i = 9; $i -gt 0; $i--) {
        Write-Host -ForegroundColor Blue "[INFO] Fermeture du script dans $i secondes" -NoNewline
        Start-Sleep -Seconds 1  # Pause d'une seconde
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
    }
}


### COMPTE A REBOURS AVANT REPRISE DU SCRIPT ###

function timing_write {

    param (
        [int]$time
    )

    # Compte à rebours
    while ($time -gt 0) {
        Write-Host -ForegroundColor Blue "[INFO] Mise en attente de $time secondes." -NoNewline
        Start-Sleep -Seconds 1
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne
        $time--  # Décrémente la variable $time
    }
    Write-Host -ForegroundColor Blue "[INFO] L'exécution du script se poursuit.`n"
    Start-Sleep -Seconds 1

            <# Compte à rebours
            for ($i = 5; $i -gt 0; $i--) {
                Write-Host -ForegroundColor Blue "[INFO] Poursuite du script dans $i secondes" -NoNewline
                Start-Sleep -Seconds 1  # Pause d'une seconde
                Write-Host "`r" -NoNewLine  # Retour au début de la ligne
            }
        Write-Host -ForegroundColor Blue "[INFO] Fin du compte à rebours, l'exécution du script se poursuit." -NoNewline
        Start-Sleep -Seconds 1
        Write-Host "`r" -NoNewLine  # Retour au début de la ligne #>

}

function exit_no_error {
    
    Write-Host @" 
Merci beaucoup d'avoir utilisé ce script. 
    
Contactez-moi pour toute demande ou incident : 
    - Par mail : landry.gonzalez@gmail.com
    - Sur Github : https://github.com/landrygonzalez
    - Sur Linkedin : https://www.linkedin.com/in/landry-gonzalez-6895801a/

"@

    Write-Host "`r" -NoNewLine

    Write-Host -ForegroundColor Magenta "[INTERACTION] Appuyez sur une touche pour continuer...`n"
    [void][System.Console]::ReadKey($true)  # Attend que l'utilisateur appuie sur une touche

    ascii_art_landry
    Start-Sleep -Seconds 3
    exit 0
}

function exit_error {
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
    
}


### AFFICHAGE DE L'ASCII ART ###

function ascii_art_landry {
    
    Write-Host @'

    
$$\                                $$\                            $$$$$$\                                         $$\                     
$$ |                               $$ |                          $$  __$$\                                        $$ |                    
$$ |      $$$$$$\  $$$$$$$\   $$$$$$$ | $$$$$$\  $$\   $$\       $$ /  \__| $$$$$$\  $$$$$$$\  $$$$$$$$\ $$$$$$\  $$ | $$$$$$\  $$$$$$$$\ 
$$ |      \____$$\ $$  __$$\ $$  __$$ |$$  __$$\ $$ |  $$ |      $$ |$$$$\ $$  __$$\ $$  __$$\ \____$$  |\____$$\ $$ |$$  __$$\ \____$$  |
$$ |      $$$$$$$ |$$ |  $$ |$$ /  $$ |$$ |  \__|$$ |  $$ |      $$ |\_$$ |$$ /  $$ |$$ |  $$ |  $$$$ _/ $$$$$$$ |$$ |$$$$$$$$ |  $$$$ _/ 
$$ |     $$  __$$ |$$ |  $$ |$$ |  $$ |$$ |      $$ |  $$ |      $$ |  $$ |$$ |  $$ |$$ |  $$ | $$  _/  $$  __$$ |$$ |$$   ____| $$  _/   
$$$$$$$$\\$$$$$$$ |$$ |  $$ |\$$$$$$$ |$$ |      \$$$$$$$ |      \$$$$$$  |\$$$$$$  |$$ |  $$ |$$$$$$$$\\$$$$$$$ |$$ |\$$$$$$$\ $$$$$$$$\ 
\________|\_______|\__|  \__| \_______|\__|       \____$$ |       \______/  \______/ \__|  \__|\________|\_______|\__| \_______|\________|
                                                 $$\   $$ |                                                                               
                                                 \$$$$$$  |                                                                               
                                                  \______/                                                                                

'@
}

function main {

    versionning
    #choco_install_check    # Installe Chocolatey
    winget_prerequisite    # Vérifie les prérequis de compatibilité pour winget
    #list_package_system    
    update_package_auto
    #packages_non_winget
    #exit_no_error
    Start-Sleep -Seconds 10
    exit 0
}

main

#Stop-Transcript
#} catch {
#    Write-Output "An error occurred: $_"
#}

# Le script devrait se lancer en mode administrateur.

#try {
#    Start-Transcript -Path "C:\temp\error_log.txt"
    # Le code que tu soupçonnes de causer l'erreur

# Il faudrait indiquer à l'utilisateur la liste des applications dont la source n'est pas winget

<## Vérifier si le script s'exécute en tant qu'administrateur
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    # Si ce n'est pas le cas, relancer le script avec les droits administratifs
    $arguments = "-NoProfile -ExecutionPolicy Bypass -File `"" + $MyInvocation.MyCommand.Definition + "`""
    Start-Process PowerShell -ArgumentList $arguments -Verb RunAs
    exit
}#>
