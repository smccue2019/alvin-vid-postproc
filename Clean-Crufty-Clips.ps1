<#
.SYNOPSIS
A script that moves video clips that are too short to be useful into a
subdirectory, i.e., sweeps the dust under the rug.
.DESCRIPTION
Alvin's in-sphere video streams are not synchronized. As a user rotates through camera
selection these discontinuities cause the recorder to close the current outfile and start
a new one. The result, as was discovered during Alvin certification trials, can be a large
collection of small and often unviewable video clips that are bookended by a few real clips.
The short clips are useless and should be moved or purged so that good clips can be properly
treated.
This script calls a script (Get-Clip-Duration.ps1) that determines a clip's time length. A
comparison is made to "min_duration" seconds. Short duration files are moved to a subdirectory
called 'Cruft'. Longer duration files are left where they are.
.PARAMETER sourcepath
Directory containing the original clips from the sphere, where we presumably need to clean.
Entering "." should be OK. If a value is not given on the command line then a querying popup
will ask for you to type in the path. If not using '.', use full path.
.PARAMETER destpath
Full path into which the too-short clips are to be placed. Mandatory, is expected to be
<cruiseID>\<diveID>\OriginalVideoCruft\[Port|Stbd]Recorder. Will put GUI file selectors on
the to-do list.
.PARAMETER min_duration
Time in seconds against which clip length is compared. Pass as a floating number.
Not mandatory, default = 8.0 seconds.
.NOTES
Author: Scott MCue, WHOI NDSF Data Manager, smccue@whoi.edu, x3462
History
2013Nov13 SJM Creation, pulling some code from scripts I wrote earlier.
2013Nov17 SJM Added some pedantic commands to clean tcmd.txt and the
              clip_duration variable after each file. Used in debugging,
              retained in code, but commented out.
2013Nov17 SJM Must change the original plan of storing "crufty" files in a subdirectory
              under the directory being cleaned. The problem with this is that
              the Axle MAM system will find these useless clips and will transcode
              proxies the best that it can. This will lead to wasted CPU cycles,
              wasted filespace, wasted XML files, you get the picture. Worst,
              the MAM interface will be badly cluttered. So, the crufty files
              have to be moved to a level at least as high as the folder that will
              be defined as that dive's MAM catalog (<cruiseID>\<diveID>\OriginalVideo)
              For now choose (<cruiseID>\<diveID>\OriginalVideoCruft). This will
              require major simultaneous changes to Create-Video-Folders.
              The destpath parameter is changed to mandatory.
#>


param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $sourcepath,
    [Parameter(Position=1, Mandatory=$true)]
    [string] $destpath,
    [Parameter(Position=2, Mandatory=$false)]
    [float] $min_duration = 8.0
) 

#Write-Host "Source entered as $sourcepath"

if (-not (Test-Path $destpath))
{
    Write-Host "Making directory $destpath"
    New-Item $destpath -type Directory
}
    
$str = $sourcepath, "*.MOV" -join "\"
$movlist = Dir  $str

ForEach ($clipfile in $movlist)
{   
   
    
    #Write-Host $clipfile
    [double]$clip_duration = Get-Clip-Duration -infilename $clipfile
    Write-Host "$clipfile length is $clip_duration seconds"
    
    # If the clip is too short in duration, place it in a cruft directory.
    if ( $clip_duration -lt $min_duration )
    { 
        #diff = $min_duration - $clip_duration
        Write-Host "$clipfile duration is less than minimum and is being moved"
        Move-Item $clipfile $destpath
    }
    else
    {
        Write-Host "$clipfile duration exceeds minimum, leaving it where it is"
    }
}