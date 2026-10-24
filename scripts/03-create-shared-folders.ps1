# One shared folder per department, following least privilege:
#   NTFS  : department group = Modify; Administrators and SYSTEM = Full control; inheritance removed.
#   Share : department group = Change; Administrators = Full.
# The effective permission is the more restrictive of the two layers.
$deps = "Management","Finance","HR","IT","Sales","CustomerService"

foreach ($d in $deps) {
  $path = "C:\Shares\$d"
  New-Item -ItemType Directory -Path $path -Force | Out-Null

  icacls $path /inheritance:r | Out-Null
  icacls $path /grant "SYSTEM:(OI)(CI)F" "BUILTIN\Administrators:(OI)(CI)F" "GLOBALTRADE\GG-${d}:(OI)(CI)M" | Out-Null

  if (Get-SmbShare -Name "Share_$d" -ErrorAction SilentlyContinue) { Remove-SmbShare -Name "Share_$d" -Force }
  New-SmbShare -Name "Share_$d" -Path $path -FullAccess "BUILTIN\Administrators" -ChangeAccess "GLOBALTRADE\GG-$d" | Out-Null
}

Get-SmbShare Share_* | Select Name,Path
