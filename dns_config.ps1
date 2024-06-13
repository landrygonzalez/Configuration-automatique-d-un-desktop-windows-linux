# Déclaration des variables.
$dns_primaire = "9.9.9.9"
$dns_secondaire = "149.112.112.112"
# Les DNS ci-dessus sont ceux de Quad9 : https://quad9.net/fr/service/service-addresses-and-features

# Récupérer les index des interfaces UP.
$interfaces_up = Get-NetAdapter -Name * | Where-Object Status -match "Up"

# Récupération des index des interfaces UP.
$index_interfaces_up = $interfaces_up.ifIndex

# Demande à l’utilisateur d’Inscrire le numéro d’index de l’interface UP à modifier.
foreach ($i in $interfaces_up){
    Write-host $i.ifIndex "-" $i.Name
}

$interface_selectionnee = Read-host "Saisissez maintenant le numéro de l’interface active dont vous voulez configurer les DNS "
Set-DnsClientServerAddress -InterfaceIndex $interface_selectionnee -ServerAddresses ($dns_primaire,$dns_secondaire)

Write-host "Les paramètres DNS IPv4 pour l'interface sélectionnée sont définis comme suit : "
Get-DnsClientServerAddress -InterfaceIndex $interface_selectionnee | Where-Object AddressFamily -Contains "2" | Select-Object InterfaceAlias,ServerAddresses

Read-Host -Prompt "Press Enter to continue..."
