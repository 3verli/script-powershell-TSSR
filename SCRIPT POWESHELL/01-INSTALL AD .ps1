# Instalation du  rôle AD DS et les  outils de gestion
Install-WindowsFeature -Name AD-Domain-Services `
-IncludeManagementTools `
-Verbose
# password DSRM (Directory Services Restore Mode)
$dsrmPwd = Read-Host -AsSecureString 'Mot de passe DSRM'
# Promotion du serveur en DC de la nouvelle forêt lab.local
Install-ADDSForest `
-DomainName 'lab.local' `
-DomainNetbiosName 'LAB' `
-SafeModeAdministratorPassword $dsrmPwd `
-InstallDns `
-NoRebootOnCompletion:$false `
-ForceI
