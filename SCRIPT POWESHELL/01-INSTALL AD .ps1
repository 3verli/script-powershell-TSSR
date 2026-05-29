# Installer le rôle AD DS + outils de gestion
Install-WindowsFeature -Name AD-Domain-Services `
-IncludeManagementTools `
-Verbose
# Mot de passe DSRM (Directory Services Restore Mode)
$dsrmPwd = Read-Host -AsSecureString 'Mot de passe DSRM'
# Promouvoir le serveur en DC de la nouvelle forêt lab.local
Install-ADDSForest `
-DomainName 'lab.local' `
-DomainNetbiosName 'LAB' `
-SafeModeAdministratorPassword $dsrmPwd `
-InstallDns `
-NoRebootOnCompletion:$false `
-ForceI