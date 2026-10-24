# Creates 45 sample users and one Global security group per department (GG-<Department>).
# Login name rule: first initial + "." + last name (e.g. a.khaled); a number is appended on duplicates.
# Run on a domain controller, in PowerShell as Administrator. Requires the OUs from 01-create-ous.ps1.
Import-Module ActiveDirectory
$base = "DC=globaltrade,DC=local"

# Initial password is NOT stored in this file - you are prompted for it.
$pwd = Read-Host "Initial password for the new users" -AsSecureString

# --- 1) Users list (fictional names) ---
New-Item -ItemType Directory -Path C:\Scripts -Force | Out-Null
@"
FirstName,LastName,Department
Ahmad,Khaled,Finance
Amir,Khaled,Finance
Sara,Nasser,Finance
Basel,Hamdan,Finance
Mona,Rizk,Finance
Karim,Awad,Finance
Hiba,Jaber,Finance
Zaid,Qasem,Finance
Omar,Hassan,HR
Lina,Saleh,HR
Osama,Hassan,HR
Rawan,Taha,HR
Majd,Suleiman,HR
Dalia,Nimr,HR
Yousef,Ali,IT
Ali,Mahmoud,IT
Walid,Sabbagh,IT
Reem,Hijazi,IT
Hadi,Kassab,IT
Lama,Bakri,IT
Ziad,Fakhoury,IT
Nadia,Karam,IT
Nour,Salem,Management
Rami,Odeh,Management
Layla,Barakat,Management
Fadi,Zein,Management
Maya,Darwish,Management
Khaled,Younis,Management
Rana,Shami,Management
Hala,Farah,Sales
Tarek,Mansour,Sales
Fares,Dabbas,Sales
Rola,Mourad,Sales
Bilal,Zahra,Sales
Salma,Idris,Sales
Jad,Habib,Sales
Tala,Wehbe,Sales
Dina,Haddad,CustomerService
Samer,Issa,CustomerService
Mazen,Rifai,CustomerService
Abeer,Hamed,CustomerService
Nabil,Sweid,CustomerService
Yara,Kanaan,CustomerService
Hamza,Obeid,CustomerService
Admin,Helpdesk,Admins
"@ | Set-Content C:\Scripts\users.csv -Encoding UTF8

# --- 2) Department -> OU map ---
$map = @{
  Management      = "OU=Management,OU=HQ,$base"
  Finance         = "OU=Finance,OU=HQ,$base"
  HR              = "OU=HR,OU=HQ,$base"
  IT              = "OU=IT,OU=HQ,$base"
  Sales           = "OU=Sales,OU=Branch,$base"
  CustomerService = "OU=CustomerService,OU=Branch,$base"
  Admins          = "OU=Admins,$base"
}

# --- 3) Groups (created only if missing) ---
foreach ($d in $map.Keys) {
  $g = "GG-$d"
  if (-not (Get-ADGroup -Filter "Name -eq '$g'")) {
    New-ADGroup -Name $g -SamAccountName $g -GroupScope Global -GroupCategory Security `
      -Path $map[$d] -Description "Group for $d"
    Write-Host "Group created: $g"
  }
}

# --- 4) Users ---
Import-Csv C:\Scripts\users.csv | ForEach-Object {
  $first = $_.FirstName.Trim(); $last = $_.LastName.Trim(); $dep = $_.Department.Trim()
  if (-not $map.ContainsKey($dep)) { Write-Warning "Unknown department '$dep' for $first $last"; return }
  if (Get-ADUser -Filter "Name -eq '$first $last'") { Write-Host "Skip (exists): $first $last"; return }

  $root = (("{0}.{1}" -f $first.Substring(0,1), $last) -replace '\s','').ToLower()
  $sam = $root; $i = 2
  while (Get-ADUser -Filter "SamAccountName -eq '$sam'") { $sam = "$root$i"; $i++ }

  New-ADUser -Name "$first $last" -GivenName $first -Surname $last -DisplayName "$first $last" `
    -SamAccountName $sam -UserPrincipalName "$sam@globaltrade.local" -Department $dep `
    -Path $map[$dep] -AccountPassword $pwd -Enabled $true -ChangePasswordAtLogon $true

  Add-ADGroupMember -Identity "GG-$dep" -Members $sam
  Write-Host "Created: $sam ($dep)"
}

# --- 5) Verification ---
Get-ADUser -Filter * -SearchBase $base -Properties Department |
  Where-Object { $_.DistinguishedName -match "OU=(HQ|Branch|Admins)" } |
  Select Name,SamAccountName,Department | Sort Department | Format-Table -AutoSize

Write-Host "`nUsers per group:"
foreach ($d in $map.Keys) { "{0,-16} {1}" -f "GG-$d", (Get-ADGroupMember "GG-$d").Count }
