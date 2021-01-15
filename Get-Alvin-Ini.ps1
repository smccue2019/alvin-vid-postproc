
param (
    [Parameter(Position=0, Mandatory=$false)]
    [string] $ini_filename = "C:\Users\scotty\bin\Alvin.ini"
    )

$h = Import-ini -IniFile:$ini_filename
$cruiseID = $h.CRUISE.cruiseID
$diveID = $h.DIVE.diveID


Write-Host $cruiseID
Write-Host $diveID
