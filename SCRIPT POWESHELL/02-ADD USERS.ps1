Import-Module ActiveDirectory
$ouBase = 'OU=Nouvy,DC=lab,DC=local'
$ouUsers = "OU=Utilisateurs,$ouBase"
$ouGroups = "OU=Groupes,$ouBase"
# Création des OU (idempotent — l'enchaînement re-lance sans erreur)
foreach ($ou in @($ouBase, $ouUsers, $ouGroups)) {
$exists = Get-ADOrganizationalUnit `
-Filter "DistinguishedName -eq '$ou'" `
-ErrorAction SilentlyContinue
if (-not $exists) {
$parts = $ou -split ',', 2
$name = ($parts[0] -split '=')[1]
$path = $parts[1]
New-ADOrganizationalUnit -Name $name -Path $path
}
}

foreach ($dept in 'RH','IT','Direction') {
$exists = Get-ADGroup -Filter "Name -eq 'GRP-$dept'" `
-ErrorAction SilentlyContinue
if (-not $exists) {
New-ADGroup `
-Name "GRP-$dept" `
-GroupScope Global `
-GroupCategory Security `
-Path $ouGroups
}
}
$users = Import-Csv -Path .\users.csv -Delimiter ';' -Encoding UTF8
foreach ($u in $users) {
if (Get-ADUser -Filter "SamAccountName -eq '$($u.login)'" `
-ErrorAction SilentlyContinue) {
Write-Host "Skip $($u.login) (deja present)" -ForegroundColor Yellow
continue
}
New-ADUser `
-Name "$($u.firstName) $($u.lastName)" `
-GivenName $u.firstName `
-Surname $u.lastName `
-SamAccountName $u.login `
-UserPrincipalName "$($u.login)@lab.local" `
-Department $u.department `
-Title $u.jobTitle `
-Path $ouUsers `
-AccountPassword (ConvertTo-SecureString 'Nouvy!2026' -AsPlainText -Force) `
-ChangePasswordAtLogon $true `
-Enabled $true
Add-ADGroupMember -Identity "GRP-$($u.department)" -Members $u.login
}
# Lister les utilisateurs créés
Get-ADUser -Filter * `
-SearchBase 'OU=Utilisateurs,OU=Nouvy,DC=lab,DC=local' |
Select-Object Name, SamAccountName, Department, Enabled
# Compter les membres de chaque groupe
foreach ($g in 'GRP-RH','GRP-IT','GRP-Direction') {
$count = (Get-ADGroupMember -Identity $g).Count
Write-Host "$g : $count membres"
}