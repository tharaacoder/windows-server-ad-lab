# Creates the OU structure: one top-level OU per site, then one OU per department.
# (The same structure was first built manually in ADUC; this script reproduces it.)
Import-Module ActiveDirectory
$base = "DC=globaltrade,DC=local"

foreach ($site in "HQ","Branch","Admins") {
    New-ADOrganizationalUnit -Name $site -Path $base
}
foreach ($dep in "Management","Finance","HR","IT","Servers") {
    New-ADOrganizationalUnit -Name $dep -Path "OU=HQ,$base"
}
foreach ($dep in "Sales","CustomerService") {
    New-ADOrganizationalUnit -Name $dep -Path "OU=Branch,$base"
}
