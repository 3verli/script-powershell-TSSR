# Autoriser SRV-LAB comme serveur DHCP de la forêt
Add-DhcpServerInDC `
-DnsName 'SRV-LAB.lab.local' `
-IPAddress '10.0.0.10'
# Vérifier la liste des serveurs DHCP autorisés dans AD
Get-DhcpServerInDC
# Redémarrer le service DHCP pour qu'il prenne en compte l'autorisation
Restart-Service DHCPServer