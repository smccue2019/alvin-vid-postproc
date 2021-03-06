<#
.SYNOPSIS
A script that creates a file hierarchy for receiving Alvin video from 
recorder-drive offload and subsequent post-processing.
Usage is Create-Video-Folders, and cruiseID and diveID are expected to
be defined in D:\Alvin.ini. 
.DESCRIPTION
Creates destination directories on WranglerRack/IntelliRAID for the video
from one dive's video clips.
If D:\Alvin.ini does not exist, then usage should be
Create-Video-Folders cruiseID diveID, where cruiseID form is "AT98-76"
and diveID form is "AL1234".
There is some checking for presence and form of arguments, and missing or
miswritten arguments are supposed to lead to entry popups.
    On two RAID systems (mounted at D: and Z:):
     * encapsulating dive folder,
     * folders for original clips and proxy clips, 
     * under these folders for each of two recorders, and
     * a "Cruft" folder that receives clip remnants that result
       from switching between unlocked camera feeds. 
Note that the labels at the bottom of the file hierarchy are for the
recorder label (position) and not a camera label. The ability to switch
between several camera inputs makes recorder location the most stable
identifier. And, because of observer monitoring angles the port cameras
will most often be captured by the starboard recorder, and vice-versa.
.PARAMETER inifile
Location of file, formatted like a classic DOS INI file, containing
cruiseID and diveID information. Not manadatory, default is D:\Alvin.ini.
If this is not passed and D:\Alvin.ini does not exist, then cruiseID and
diveID must be passed.
.PARAMETER cruiseID
Mandatory if inifile is not an argument or D:\Alvin.ini does not exist.
Top level folder, assumed to already be created at the top of both RAID
systems, e.g., D:\AT26-05 and Z:\AT26-05. Top folder creation can be done
by using Windows Explorer in administrator mode, which is invoked by
right-clicking the app icon and choosing "run as administrator".
.PARAMETER diveID
Mandatory if inifile is not an argument or D:\Alvin.ini does not exist.
Alvin dive number with "AL" prefix, e.g., "AL1234". If only a number is
provided, "AL" will be prepended.
.NOTES
Author Scott McCue, NDSF Data Manager smccue@whoi.edu x3462
History
6Nov2013 SJM Creation
9Nov2013 SJM Add extra check that cruiseID starts with
            "AT", and create popup to get correction if needed.
11Nov2013 SJM Add in generation of subdirectories to receive
              too-short clips resulting from switching between
              unsynchronized signals.
12Nov2103 SJM Add directories to receive unconcatenated and
              concatenated proxy clips.
13Nov2013 SJM Add 'Cruft' directories to receive too-short clips 
17Nov2013 SJM Changed location of cruft directories. Having them
              under the OriginalVideo tree exposes them to the
              Axle MAM, clutters the MAM interface, and wastes resources.
              Instead, locate them in a side tree starting at same level
              as OriginalVideo with name OriginalVideoCruft.
	          Changed mis-named variable, from root=cruise to root=dive.
18Nov2013 SJM Reversed input parameters order to better match other
              scripts, with cruise first and dive second.    
#>


   param (
        [Parameter(Position=0, Mandatory=$false)]
        [string] $inifile = "D:\Alvin.ini",
        [Parameter(Position=1, Mandatory=$false)]
        [string] $cruiseID,
        [Parameter(Position=2, Mandatory=$false)]
        [string] $diveID
    ) 
    
    if ( Test-Path variable:\inifile)
    {
        $h = Import-ini -IniFile:$inifile
        $cruiseID = $h.CRUISE.cruiseID
        $diveID = $h.DIVE.diveID
    }
    elseif ( Test-Path D:\Alvin.ini )
    {
        $h = Import-ini -IniFile:"D:\Alvin.ini"
        $cruiseID = $h.CRUISE.cruiseID
        $diveID = $h.DIVE.diveID
    }
    elseif ( (Test-Path variable:\cruiseID) -and (Test-Path variable:\diveID) )
    {
        Write-Host "Using passed arguments $cruiseID and $diveID"
    }
    else
    {
        Write-Host "Quitting: undefined cruiseID and diveID"
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
    
    # Two birds, one stone... Determine if cruise_dir was passed on command line and
    # also that it starts with an Atlantis prefix- "AT". Otherwise, query via dialog.
    
    if ($cruiseID -cmatch "^AT")
    {
        #Write-Host "$cruiseID deemed acceptable"
    }
    else
    {
        Write-Host "cruiseID $cruiseID doesnt match expected form- begin with 'AT'"
    } 
    
        
    # Make the new dive direcotories under the cruise dir
    $topD = "D:", $cruiseID -join "\"
    $topZ = "Z:", $cruiseID -join "\"
    #Write-Host $topD
    #Write-Host $topZ
    New-Item -path $topD -name $diveID -type directory
    New-Item -path $topZ -name $diveID -type directory
   
    # Next make the folders for video type, original or proxy.
    # These aren't for proxies generated by a media asset mgmt
    # system, but are for proxies generated for direct viewing
    # with a video player on laptop or tablet. 
    $diveD = $topD, $diveID -join "\"
    $diveZ = $topZ, $diveID -join "\"
    #Write-Host $diveD
    #Write-Host $diveZ
    New-Item -path $diveD -name "OriginalVideo" -type directory
    New-Item -path $diveD -name "ProxyVideo" -type directory
    New-Item -path $diveZ -name "OriginalVideo" -type directory
    New-Item -path $diveZ -name "ProxyVideo" -type directory
    
    # Next make the folders in which crappy clips are "swept
    # under the rug". This filetree will be populated by running
    # the Clean-Crufty-Clips PowerShell script. I'm placing them
    # at the same level as the OriginalVideo directories so that
    # they aren't included in the Media Asset management system
    # catalogs, which will be defined as path
    # <cruiseID>\<diveID>\OriginalVideo. Cruft paths will be
    # <cruiseID>\<diveID>\OriginalVideoCruft\[Port|Stbd]Recorder.
    
    New-Item -path $diveD -name "OriginalVideoCruft" -type directory
    New-Item -path $diveZ -name "OriginalVideoCruft" -type directory  

    # Add the folders for the respective recorders
    $origD = $diveD, "OriginalVideo" -join "\"
    $proxyD = $diveD, "ProxyVideo" -join "\"
    $cruftD = $diveD, "OriginalVideoCruft" -join "\"
    $origZ = $diveZ, "OriginalVideo" -join "\"
    $proxyZ = $diveZ, "ProxyVideo" -join "\"
    $cruftZ = $diveZ, "OriginalVideoCruft" -join "\"
    #Write-Host $origD
    #Write-Host $proxyD
    #Write-Host $origZ
    #Write-Host $proxyD
    New-Item -path $origD -name "PortRecorder" -type directory
    New-Item -path $proxyD -name "PortRecorder" -type directory
    New-Item -path $cruftD -name "PortRecorder" -type directory
    New-Item -path $origD -name "StbdRecorder" -type directory
    New-Item -path $proxyD -name "StbdRecorder" -type directory
    New-Item -path $cruftD -name "StbdRecorder" -type directory
    New-Item -path $origZ -name "PortRecorder" -type directory
    New-Item -path $proxyZ -name "PortRecorder" -type directory
    New-Item -path $cruftZ -name "PortRecorder" -type directory
    New-Item -path $origZ -name "StbdRecorder" -type directory
    New-Item -path $proxyZ -name "StbdRecorder" -type directory
    New-Item -path $cruftZ -name "StbdRecorder" -type directory
    
    # Make subdirectories for proxies. One will contain the direct
    # results of transcoding from the original recordings, called DirectProxies.
    # The other will contain proxies that correspond to several clips
    # concatenated to increase content duration and reduce clip count.
    $proxyPortD = $proxyD, "PortRecorder" -join "\"
    $proxyStbdD = $proxyD, "StbdRecorder" -join "\"
    $proxyPortZ = $proxyZ, "PortRecorder" -join "\"
    $ProxyStbdZ = $proxyZ, "StbdRecorder" -join "\"
    #Write-Host $proxyPortD
    #Write-Host $proxyStbdD
    #Write-Host $proxyPortZ
    #Write-Host $proxyStbdZ
    New-Item -path $proxyPortD -name "DirectProxies" -type directory
    New-Item -path $proxyStbdD -name "DirectProxies" -type directory
    New-Item -path $proxyPortZ -name "DirectProxies" -type directory
    New-Item -path $proxyStbdZ -name "DirectProxies" -type directory
    New-Item -path $proxyPortD -name "ConcatProxies" -type directory
    New-Item -path $proxyStbdD -name "ConcatProxies" -type directory
    New-Item -path $proxyPortZ -name "ConcatProxies" -type directory
    New-Item -path $proxyStbdZ -name "ConcatProxies" -type directory
        