<#
.SYNOPSIS
Log-Clips-Start-Stop-Duration creates a text file that reports
metadata for a collection of Alvin dive recordings. For most
effective usage, apply this script to the clips copied from
recorder hard drives, before applying cruft cleaning.
Clips are in ProRes422 format. This script calls another script
(Get-Clip-Start-Stop-Duration.ps1) that extracts metadata info
from the timecode fork and returns start time, stop time, and
duration. That information is then concatenated to a log file.
Processes an entire dive at once, i.e., both recorders. 
.DESCRIPTION
Creates a text file listing time metadata for the clips from 
Alvin video recorders.
.PARAMETER
inifile. Not mandatory, default = d:\Alvin.ini
logfile. Not mandatory,
default = [d:,z:]\<cruiseID>\<diveID>\OriginalVideo\video_time_log.txt
.AUTHOR
Scott McCue WHOI/NDSF smccue@whoi.edu
.HISTORY
1Aug2014 Creation during airplane flight in response to feedback from
recent science party.
3Oct2014 Cleaned up some errors in logic.
#>

param (
    [Parameter(Position=0, Mandatory=$false)]
    [string] $inifile = "D:\Alvin.ini",
    [Parameter(Position=1, Mandatory=$false)]
    [string] $logfilename = "video_time_log.txt"
    )
    
    
    if ( Test-Path $inifile)
    {
        $h = c:\Scripts\Import-ini.ps1 -IniFile:$inifile
        $cruiseID = $h.CRUISE.cruiseID
        $diveID = $h.DIVE.diveID
    }
    elseif (Test-Path D:\Alvin.ini)
    {
        $h = c:\Scripts\Import-ini.ps1 -IniFile:"D:\Alvin.ini"
        $cruiseID = $h.CRUISE.cruiseID
        $diveID = $h.DIVE.diveID
    }
    else
    {
        Write-Host "Quitting: Must define cruiseID and diveID"
        return 1
    }
    
    #    $mountpts = @( "D:", "Z:")
    $mountpts = @( "D:" )
    $recorders = @( "PortRecorder", "StbdRecorder")
    
    $logfilepath = $mp, $cruiseID, $diveID, $logfilename -join "\"
    
    if (Test-Path $logfilepath)
    {
       Del $logfilepath
    }
    
    Write-Output "ClipFile Start_Timecode Duration Calculated_Stop_Time" >> $logfilepath

    ForEach ($mp in $mountpts)
    {
        ForEach ($r in $recorders)
        {
            $clipsroot = $mp, $cruiseID, $diveID, "OriginalVideo", $r -join "\"
            
            $str = $clipsroot, "*.MOV" -join "\"
            $movlist = Dir  $str
            
            ForEach ($clipfile in $movlist)
            {   
                $sdatestr, $edatestr, $clip_duration = c:\Scripts\Get-Clip-Start-Stop-Duration.ps1 -infilename $clipfile
                $str = $clipfile.Name, $sdatestr, $clip_duration, $edatestr -join " "
                Write-Output $str  >> $logfilepath
            }
         }
      }