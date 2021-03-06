<#
.SYNOPSIS
Creates a subtitle file in .srt format to support playback
of time information with proxies of Alvin video.

.DESCRIPTION
A script that creates a subtitle file for the display of
time during playback of proxies of Alvin video. Start and
stop times are determined from creation date, start time code,
and duration information in the 'tcmd' section of a ProRes422/
Quicktime .mov file.

This creates a subtitle file. It must still be merged with the
video stream, using tools like 'mkvmerge' from the mkvtoolnix
suite.

Uses ffprobe from the ffmpeg suite to pull time info from the
.mov file.

File format (see SubRip format):
A file consists of stanzas, each giving the following info...

line 1: subtitle number
line 2: start and stop time (relative to clip timing)
line 3: subtitle text
line 4: blank line

.PARAMETER src_clip
Filename of the ProRes422 clip. Mandatory.
.PARAMETER file_ext
File extention for the subtitle file. Default is .srt, which
denotes the SubRip format.

#
.NOTES
Author Scott McCue NDSF Data Manager, smccue@whoi.edu, x3462
HISTORY
March 2014  Start file, science verification cruise.
#>

param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $src_clip,
    [string] $file_ext = "srt"
    ) 
    
    if (-not (Test-Path $src_clip))
    {
        Write-Host "$src_clip was not found"
        # Exit the script
        return $null
    }
    
    # ffprobe is annoyingly verbose, spewing compilation info out to STDERR. Redirect
    # to out-null.
    # Pull the clip creation date, starting timecode and clip duration from the source video file
    # Extract the tcmd stream info integral to a ProRes file and pull date and time params
    $(c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $src_clip > tcmd.txt) 2>&1 | out-null
    
    $d=select-string -list -path tcmd.txt -pattern "TAG\:creation_time"
    if ($d -match "\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}")
    {
        $cdt = $matches[0]
        $date,$time = $cdt -split ' '
        $yr,$mo,$dy = $date -split '-'
    }
    else
    {
        Write-Host "Couldnt extract creation date" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }

    
    $t=select-string -list -path tcmd.txt -pattern "TAG\:timecode"
    if ($t -match "\d{2}\:\d{2}\:\d{2}\;\d{2}")
    {
        $startstr=$matches[0]
        $h,$m,$sf = $startstr -split ":"
        $s,$f = $sf -split ';'
        $start_timecode = $h, $m, $s -join ':' 
    }
    else
    {
        Write-Host "Bad extraction of time code" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }


    $du=select-string -list -path tcmd.txt -pattern "duration="
    if ($du -match "\d+\.\d+")
    {
        $duration = $matches[0]
    }
    else
    {
        Write-Host "Couldnt extract clip duration" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }
    
    # End time is start + duration. Assemble the constituents.
    $startdatetime = Get-Date -year $yr -month $mo -day $dy -hour $h -minute $m -second $s
    $enddatetime = $startdatetime.AddSeconds($duration)
    $sdatestr = $startdatetime.ToString("yyyyMMddHmmss")
    $edatestr = $enddatetime.ToString("yyyyMMddHmmss")

    #Write-Host $startdatetime
    ($srtname =$diveID, "_", $sdatestr, "-", $edatestr, ".", $file_ext -join "") > $null
    
    if (Test-Path $srtname)
    {
        Del $srtname
    }
 
    $dur_seci = [int]$duration
    Write-Host $duration $dur_seci
    
    $srtstartdatetime = Get-Date -year $yr -month $mo -day $dy -hour 0 -minute 0 -second 0
    for ($i=1; $i -le $dur_seci; $i++)
    {
        $time_inc = 2*$i
        $srt_stime = $srtstartdatetime.AddSeconds($time_inc)
        $srt_sstr = $srt_stime.ToString("HH:mm:ss.ff")
        $srt_etime = $srt_stime.AddMilliseconds(750)
        $srt_estr = $srt_etime.ToString("HH:mm:ss.ff")
        $srt_display = $startdatetime.AddSeconds($time_inc)
        $srt_dispstr = $srt_display.ToString("HH:mm:ss.ff")
        
        Write-Output $i >> $srtname
        Write-Output "$srt_sstr -> $srt_estr" >> $srtname
        Write-Output $srt_dispstr >> $srtname
        Write-Output "" >> $srtname
     }