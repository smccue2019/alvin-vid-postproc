<#
.SYNOPSIS
A script that controls the transcoding of original recordings from a Samurai into proxies.
This is an alternative to the Transcode-Control/Transcode-Samurai pairing that is the primary
choice for transcoding. 
.DESCRIPTION
As of autumn 2013 Alvin will record video from cameras under science control using an
Atomos Samurai commercial recorder. This model produces recordings encoded by an intermediate
compression-decompression algorithm. This class of codec supports post-processing using a
non-linear editor (NLE) because it maintains frame by frame integrity and carries time code.
The price of this integrity is higher file volumes and storage demands.
Many Alvin clients will not edit video and just want to have a convenient visual dive record.
This can be accomplished by generating alternative video products, based on alternative codecs
that prioritize the reduction of filesize at the expense of other things, like frame by frame
integrity.
The Samurai makes original recordings using the Apple ProRes422 family of codecs, placing the
ProRes422 "essence" into a .MOV container. This script transcodes from ProRes422 to an h.264
essence, placing it in an mp4 container. Filenames of the mp4s are generated from
capture time of the clip and from the diveID, which is pulled from an Alvin.ini config file.
The collections of files are kept and placed in separate directories/folders.
.PARAMETER inifile
Full path to ini file containing cruiseID and diveID info.
.AUTHOR
Scott McCue, smccue@whoi.edu
Data Manager, National Deep Submergence Facility
HISTORY

03/18/2014 SJM	Start with Transcode-Control.ps1 and modify to invoke Handbrake-CLI rather
		than Transcode-Samurai.ps1. Minimal config, setting image size to 960x540
		and transcoder output bit rate to 6000.
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
        Write-Host "Quitting: Must define cruiseID and diveID using ini file"
        return 1
    }

    # If diveID is only a number, prepend "AL"
    if ($diveID -match "AL\d{4}")
    {
        Write-Host "$diveID is $diveID."
    }
    elseif ($diveID -match "\d{4}")
    {      
        $diveID = "AL", $diveID -join ""
        Write-Host "DiveID rewritten as $diveID"
    }
    else
    {
        Write-Host "DiveID is in incorrect format, $diveID" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }
    
    #$mountpts = @( "D:", "Z:")
    $mountpts = @( "D:" )
    #$recorders = @( "PortRecorder", "StbdRecorder")
    $recorders = @( "PortRecorder")

    ForEach ($mp in $mountpts)
    {
        ForEach ($r in $recorders)
        {
            $srcpath = $mp, $cruiseID, $diveID, "OriginalVideo", $r -join "\"
	        $destpath = $mp, $cruiseID, $diveID, "ProxyVideo", $r, "DirectProxies" -join "\"
	    

	    # Get the list of the original clips that are transcode sources.
	    # Keep in mind that 'Dir' results in a list of objects, no filenames. 
            $str = $srcpath, "*.MOV" -join "\"
            $movlist = Dir  $str


	    ForEach ($srcfile in $movlist)
	    {
            #Write-Host $srcfile
            #Write-Host $srcfile.Name
    		$outname, $clip_duration = c:\Scripts\Build-Clipname.ps1 -src_clip $srcfile -diveID $diveID -file_ext "mp4"

		if ($outname -eq $null)
		{
		   # If we're here then Build-Clipname failed, probably because
           # of problems with timecode. Create an outname that's a simple
		   # extension change from the original filename.

		   $outnameroot = $srcfile.Name.TrimEnd(".MOV")
           #$outname = $outnameroot, "mkv" -join "."
           $outname = $outnameroot, "mp4" -join "."
		}

    		#Write-Host $outname $clip_duration
            
            cd $srcpath
              
          	#c:\Scripts\Transcode-Samurai.ps1 -src_clip $srcfile.Name -new_clip $outname
             C:\HandBrake-0.9.9-x86_64-Win_CLI\HandBrakeCLI.exe -b 6000 --width 960 --height 540 -i $srcfile.Name -o $outname   
     
        	# Move the resulting transcode to its destination directory
        	$res = $srcpath,$outname -join "\"
        	Move-Item -path $res $destpath
	    }
       }
    }