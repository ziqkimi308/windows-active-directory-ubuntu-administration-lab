Import-Module ActiveDirectory

New-Item -Path "C:\Reports" -ItemType Directory -Force

$report = Get-ADUser -Filter * -Properties LastLogonDate, Department |
    Select-Object Name, SamAccountName, Department, LastLogonDate, Enabled

$report | Format-Table -AutoSize
$report | Export-Csv "C:\Reports\user-audit.csv" -NoTypeInformation

Write-Host "Audit complete. Report saved to C:\Reports\user-audit.csv"