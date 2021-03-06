 <#
.SYNOPSIS
A script that opens a AppleProres/Quicktime file and retrieves clip duration information.
.DESCRIPTION
Alvin's in-sphere video streams are not synchronized. As a user rotates through camera
selection these discontinuities cause the recorder to close the current outfile and start
a new one. The result, as was discovered during Alvin certification trials, can be a large
collection of small and often unviewable video clips that are bookended by a few real clips.
The short clips are useless and should be moved or purged so that good clips can be properly
treated.
One fork of a QuickTime .MOV file includes timecode and time-related metadata. One field of
the metadata is "duration". This utility takes in the name of a Quicktime file, opens that
file, extracts the duration field, and returns that value back to its caller.
.PARAMETER infilename
Name, without path, of the file from which duration is to be extracted.
.NOTES
Author Scott MCue, WHOI NDSF Data Manager, smccue@whoi.edu, x3462
History
2013Nov13 SJM Creation.
2013Nov17 SJM Tried to add code to deal with uncertainty about the C:\ffmpeg path. This
              forced a kludgey way of assembling the sub-shelled, redirecting ffprobe
              invocation. There were problems with getting the results into tcmd.txt.
              In the end, I left the code and commented it out for possible use (and
              improvement!) later.
              Reason to get fancy with ffmpeg distro path... It might
              be a windows shortcut to another path containing an ffmpeg distro, or it
              might be a distro that has been installed with the usual install name
              shortened (version info is usually included).
#>


   param (
        [Parameter(Position=0, Mandatory=$true)]
        [string] $infilename
    )
    
    if (-not (Test-Path $infilename))
    {
        Write-Host "$infilename was not found"
        # Exit the script
        return $null
    }
    
    ## Try to make finding the path to ffmpeg binaries more reliable.
    ## Two options addressed
    ##    1. ffmpeg distro was installed and lengthy distro/version
    ##       info was removed from name
    ##    2. ffmpeg distro name was retained, and a Windows shortcut was
    ##       used to point to the distro. PREFERRED, allows the install of
    ##       several distros. For this reason, this will be checked first
    ##       and used if it exists.
    ## Make use of CreateShortcut, which, if called on an existing
    ## shortcut will get its properties.
    #
    #if (Test-Path "C:\ffmpeg.lnk")
    #{
    #    $obj = new-object -comobject "WScript.Shell"
    #    $scp = $obj.CreateShortcut("C:\ffmpeg.lnk")
    #    $tp = $scp.TargetPath
    #}
    #elseif (Test-Path "C:\ffmpeg - shortcut.lnk")
    #    $obj = new-object -comobject "WScript.Shell"
    #    $scp = $obj.CreateShortcut("C:\ffmpeg - shortcut.lnk")
    #    $tp = $scp.TargetPath
    #}
    #elseif (( Get-Childitem "c:\ffmpeg") -match "bin")
    #{
    #    $tp = "C:\ffmpeg"
    #}
    #else
    #{
    #    # Exit the script
    #    Write-Host "Get-Clip-Duration:Didn't find the executable path for ffprobe"
    #}
    
    #$ffprobecmd1 = $tp, "bin", "ffprobe.exe" -join "\"
    #$ffprobecmd2 = $ffprobecmd1, "-show_streams:tcmd" -join " "
    #$ffprobecmd = $ffprobecmd2, $infilename, "> tcmd" -join " "
    ##write-host $ffprobecmd
    
    # ffprobe is annoyingly verbose, spewing compilation info out to STDERR. Redirect
    # to out-null.
    # Pull the clip creation date, starting timecode and clip duration from the source video file
    # Extract the tcmd stream info integral to a ProRes file and pull date and time params
    
    $( c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $infilename > tcmd.txt ) 2>&1 | out-null
    
    #$( $ffprobecmd ) 2>&1 | out-null
    
    $du=select-string -list -path tcmd.txt -pattern "duration="
    if ($du -match "\d+\.\d+")
    {
        $duration = $matches[0]
        return $duration
    }
    else
    {
        Write-Host "Couldnt extract clip duration" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }
 
