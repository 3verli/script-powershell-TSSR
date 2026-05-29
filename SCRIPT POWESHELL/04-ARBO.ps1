# ===============================
# VARIABLES
# ===============================
$root = 'C:\Partages'
$departments = 'RH','IT','Direction'

# ===============================
# VERIFICATION ADMIN
# ===============================
If (-NOT ([Security.Principal.WindowsPrincipal] `
[Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
[Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Host "Relancer en ADMINISTRATEUR !" -ForegroundColor Red
    break
}

# ===============================
# CREATION DOSSIER RACINE
# ===============================
if (-not (Test-Path $root)) {
    try {
        New-Item -Path $root -ItemType Directory -Force | Out-Null
        Write-Host "Créé : $root" -ForegroundColor Green
    }
    catch {
        Write-Host "Erreur création $root" -ForegroundColor Red
        break
    }
}

# ===============================
# CREATION SOUS DOSSIERS
# ===============================
foreach ($dept in $departments) {
    $path = Join-Path $root $dept

    if (-not (Test-Path $path)) {
        New-Item -Path $path -ItemType Directory -Force | Out-Null
        Write-Host "Créé : $path" -ForegroundColor Green
    }
}

# ===============================
# VERIFICATION DOSSIERS
# ===============================
Write-Host "`nDossiers créés :" -ForegroundColor Cyan
Get-ChildItem $root -Directory | Select-Object Name, FullName

# ===============================
# CREATION PARTAGES SMB
# ===============================
foreach ($dept in $departments) {

    $shareName = "$dept`$"
    $path = Join-Path $root $dept

    # Supprimer si déjà existant
    if (Get-SmbShare -Name $shareName -ErrorAction SilentlyContinue) {
        Remove-SmbShare -Name $shareName -Force
    }

    New-SmbShare `
        -Name $shareName `
        -Path $path `
        -FullAccess "LAB\GRP-$dept" `
        -Description "Partage du service $dept"

    Write-Host "Partage créé : $shareName" -ForegroundColor Yellow
}

# ===============================
# LISTE DES PARTAGES
# ===============================
Write-Host "`nPartages créés :" -ForegroundColor Cyan
Get-SmbShare | Where-Object Name -like '*$' |
Select-Object Name, Path

# ===============================
# FONCTION ACL NTFS
# ===============================
function Set-NouvyNtfsAcl {
    param(
        [Parameter(Mandatory)] [string] $Path,
        [Parameter(Mandatory)] [string] $Identity
    )

    if (-not (Test-Path $Path)) {
        Write-Host "Dossier introuvable : $Path" -ForegroundColor Red
        return
    }

    $acl = Get-Acl -Path $Path

    # Désactiver héritage
    $acl.SetAccessRuleProtection($true, $false)

    # Supprimer anciens droits
    $acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }

    # Règles
    $rule1 = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'BUILTIN\Administrateurs', 'FullControl',
        'ContainerInherit,ObjectInherit', 'None', 'Allow'
    )

    $rule2 = New-Object System.Security.AccessControl.FileSystemAccessRule(
        'NT AUTHORITY\SYSTEM', 'FullControl',
        'ContainerInherit,ObjectInherit', 'None', 'Allow'
    )

    $rule3 = New-Object System.Security.AccessControl.FileSystemAccessRule(
        $Identity, 'Modify',
        'ContainerInherit,ObjectInherit', 'None', 'Allow'
    )

    # Ajouter
    $acl.AddAccessRule($rule1)
    $acl.AddAccessRule($rule2)
    $acl.AddAccessRule($rule3)

    # Appliquer
    Set-Acl -Path $Path -AclObject $acl

    Write-Host "ACL appliquées : $Path" -ForegroundColor Green
}

# ===============================
# APPLICATION DES ACL
# ===============================
foreach ($dept in $departments) {
    $path = Join-Path $root $dept
    Set-NouvyNtfsAcl -Path $path -Identity "LAB\GRP-$dept"
}

# ===============================
# VERIFICATION ACL
# ===============================
Write-Host "`nVérification ACL RH :" -ForegroundColor Cyan
(Get-Acl "$root\RH").Access |
Select-Object IdentityReference, FileSystemRights, AccessControlType
