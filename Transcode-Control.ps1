<#
.SYNOPSIS
A script that controls the transcoding of original recordings from a Samurai into proxies.
This script invokes 'ffmpeg' to do the transcoding.
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
essence, placing it in a Matroska (mkv) container. Filenames of the mkvs are generated from
capture time of the clip and from the diveID, which must be passed by the invoker.
The collections of files are kept and placed in separate directories/folders.
.PARAMETER inifile
Full path to ini file containing cruiseID and diveID info.
.AUTHOR
Scott McCue, smccue@whoi.edu
Data Manager, National Deep Submergence Facility
HISTORY
9/2013 Create and test
11/10/2013 Added handling of clips that are too short to process of present to science as data.
           Receive clip duration from Build-Clipname, move to Cruft subdir if too short.
03/16/2014 Remove the cleaning of crufty clips, which is now handled by prior invocation
           of Clean-Crufty-Control.ps1. Changed some file handling.
03/21/2014 Add logging of filenames so that we know source (original) and transcoded (proxy)
           filenames. Hardcoded filename is "transcode_log.txt".
           Add generation of time code as a subtitle file (assuming that time code exists)
           using 'tcmd2Subtitle.ps1'.
	   Add a call to 'tcmd2Subtitle.ps1' so that a subtitle file is created along with
           the proxy. Note that the proxy, already in an mkv container, and subtitle must
 	   further be merged into an mkv container.
#>

param (
    [Parameter(Position=0, Mandatory=$false)]
    [string] $inifile = "D:\Alvin.ini"
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
    $recorders = @( "PortRecorder", "StbdRecorder")
    #$recorders = @( "StbdRecorder")

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

            if (Test-Path transcode-log.txt)
            {
                Del transcode_log.txt
            }
            
	    ForEach ($srcfile in $movlist)
	    {
            #Write-Host $srcfile
            #Write-Host $srcfile.Name
    		$outname, $clip_duration = c:\Scripts\Build-Clipname.ps1 -src_clip $srcfile -diveID $diveID -file_ext "mkv"
            
		if ($outname -eq $null)
		{
		   # If we're here then Build-Clipname failed, probably because
           # of problems with timecode. Create an outname that's a simple
		   # extension change from the original filename.
           
           $outbase = [System.IO.Path]::GetFileNameWithoutExtension($srcfile)
           $oul = $outbase.toLower()
           $outname = $oul, "mkv" -join "."
		}

           # Presumably time code is healthy and a subtitle file can be
           # generated.
           

    		#Write-Host $outname $clip_duration
            Write-Host "cd to $srcpath"
            cd $srcpath
            Start-Sleep -seconds 5
              
            # invoke transcoding in another routine here
            c:\Scripts\Transcode-Samurai.ps1 -src_clip $srcfile.Name -new_clip $outname    
            #c:\Scripts\Touch-file.ps1 $outname
            
            if ($outname -match "AL\d{4}_\d{14}-\d{14}.mkv")
            { 
                $srtbase = [System.IO.Path]::GetFileNameWithoutExtension($outname)
                $sul = $srtbase.toLower()
                $srtname = $sul, "srt" -join "."
                
                Write-Host "Using $srcfile to generate a subtitle file from time code information".
                c:\Scripts\tcmd2Subtitle.ps1 -src_clip $srcfile 
            }
     
        	# Move the resulting transcode to its destination directory
            $res1 = $destpath,$outname -join "\"
            
            Move-Item -path $outname $destpath
            Move-Item -path $srtname $destpath
            
            # This is where we log source and proxy names to file.
            Write-Output "Original $srcfile.Name transcoded to $res1"  >> transcode_log.txt
	    }
       }
    }