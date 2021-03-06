<#
.SYNOPSIS
Analyze-Clips-Length is a forensic tool for looking at the
relationship between metadata from video clips and metadata
from the filesystem holding the video clip files.
.DESCRIPTION
A video clip includes metadata about its start time and duration.
Info about a files creation datetime and last modification datetime
can be pulled from the filesystem. This script does both of these
things and co-registers that information, along with filename and
filesize.

To use: ========================
- Run in Powershell
- Apply to the original recorder drive, not to the duplicates when
the recorder drives are offloaded onto the 1Beyond system. The former
have recorder/clipfile creation and mod time, the latter only have
duplication times.
- cd to the mount point of the drive  (E:, F:, etc) before running.
================================

This not an operational tool, so it is left somewhat barebones. The
output filename is defined by hand edit at the top of this script.
There are no parameters. If you wish to change this, be my guest.

Requires Get-Clip-Start-Stop-Duration.ps1
 
AUTHOR
Scott McCue WHOI/NDSF smccue@whoi.edu
HISTORY
3/2014 SJM Created and exercised as we work to fix video issues
during science verification trials.
#>


$outfile = "c:\Users\scotty\SwitchingEval2_Port.txt"

if (Test-Path $outfile)
{
    Del $outfile
}

Write-Output $outfile "Filename Dur(secs) Dur Start (TC), End (TC) Filecreate FileLastWrite Size" >> $outfile

$movlist = Dir .\*.MOV


ForEach ($srcfile in $movlist)
{
    $sds, $eds, $dur_secs = Get-Clip-Start-Stop-Duration.ps1($srcfile)
    $dur_seci = [int]$dur_secs
    Write-Host $sds $eds, $dur_secs, $dur_seci
    #Write-Host "dur_seci= $dur_seci"
    $dur_ts = New-Timespan -seconds $dur_seci
    $dur_str = '{0:00}:{1:00}:{2:00}' -f $dur_ts.Hours,$dur_ts.Minutes,$dur_ts.Seconds
    $file = Get-Item($srcfile)
    $filesize = $file.length
    $filename = $file.name
    $filecreate = $file.CreationTime
    $filemod = $file.LastWriteTime
    
    

    Write-Host $filename
    $s = $filename,$dur_secs,$dur_str,$sds, $eds, $filecreate, $filemod, $filesize -join " "
    Write-Output $s >> $outfile
}