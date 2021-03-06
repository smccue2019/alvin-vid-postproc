<#
.SYNOPSIS
A high level script to invoke Clean-Crufty-Clips.ps1 on
several directories at standard locations. 
.DESCRIPTION
'Clean-Crufty-Clips.ps1' is invoked on a directory. This
can be done by hand, but a complete job means invoking four
times: D: and Z:, PortRecorder and StbdRecorder. This script
automates those four invocations. Naturally, the directory
tree must be the standard configuration, such as is created by '
Create-Video-Folders.ps1'. The directory names are built
from cruiseID and diveID.
.PARAMETER inifile
Full path to ini file containing cruiseID and diveID info.
Default - D:\Alvin.ini
.NOTES
Author Scott McCue, smccue@whoi.edu, x3462
History
2013Nov18  SJM Create
#>

param (
    [Parameter(Position=0, Mandatory=$false)]
    [string] $inifile = "D:\Alvin.ini"
    )
    
    
    if ( Test-Path $inifile)
    {
        $h = Import-ini -IniFile:$inifile
        $cruiseID = $h.CRUISE.cruiseID
        $diveID = $h.DIVE.diveID
    }
    elseif (Test-Path D:\Alvin.ini)
    {
        $h = Import-ini -IniFile:"D:\Alvin.ini"
        $cruiseID = $h.CRUISE.cruiseID
        $diveID = $h.DIVE.diveID
    }
    else
    {
        Write-Host "Quitting: Must define cruiseID and diveID"
        return 1
    }
    
    
    # If diveID is only a number, prepend "AL"
    if ($diveID -match "AL\d{4}")
    {
        #Write-Host "$diveID is $diveID."
    }
    elseif ($diveID -match "\d{4}")
    {      
        $diveID = "AL", $diveID -join ""
        #Write-Host "DiveID rewritten as $diveID"
    }
    else
    {
        Write-Host "DiveID is in incorrect format, $diveID" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }
    
#    $mountpts = @( "D:", "Z:")
    $mountpts = @( "D:" )
    $recorders = @( "PortRecorder", "StbdRecorder")
    
    ForEach ($mp in $mountpts)
    {
        ForEach ($r in $recorders)
        {
            $cleanpath = $mp, $cruiseID, $diveID, "OriginalVideo", $r -join "\"
            $cruftpath = $mp, $cruiseID, $diveID, "OriginalVideoCruft", $r -join "\"
            
            Write-Host "Pausing for 10 seconds for you to read feedback, cancel execution, etc"
            Write-Host "Invoking Clean-Crufty-Clips.ps1 -sourcepath $cleanpath -destpath $cruftpath"
            Start-Sleep -seconds 10
            Clean-Crufty-Clips.ps1 -sourcepath $cleanpath -destpath $cruftpath
            
        }
     }