<#
.SYNOPSIS
Get-Clip-Start-Stop-Duration pulls metadata from the metadata
fork of a ProRes422 video clip file (.MOV), generates further
inforation (like clip end time) and returns these to the calling
script.
.DESCRIPTION
Developed for use with Analyze-Clips-Length for forensics during
Alvin Science verification cruise.
Requires the executable 'ffprobe' from the ffmpeg suite of tools.
Expects it at path c:\ffmpeg\bin.
.PARAMETER
infilename
Mandatory. 
.AUTHOR
Scott McCue WHOI/NDSF smccue@whoi.edu
.HISTORY March 2014 Creation and exercise during science Verification Cruise
        1Aug2014 Clean up a bit for use as operational code.
#>

   param (
        [Parameter(Position=0, Mandatory=$true)]
        [string] $infilename
    )
    
    if (-not (Test-Path $infilename))
    {
        Write-Host "Get-Clip-Start-Stop-Duration: $infilename was not found"
        # Exit the script
        return $null
    }
    

    # ffprobe is annoyingly verbose, spewing compilation info out to STDERR. Redirect
    # to out-null.
    # Pull the clip creation date, starting timecode and clip duration from the source video file
    # Extract the tcmd stream info integral to a ProRes file and pull date and time params
    
    # $( c:\ffmpeg-20130108\bin\ffprobe.exe -show_streams:tcmd $infilename > tcmd.txt ) 2>&1 | out-null
    $( c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $infilename > tcmd.txt ) 2>&1 | out-null
    #$( $ffprobecmd ) 2>&1 | out-null

    $d=select-string -list -path tcmd.txt -pattern "TAG\:creation_time"
    #Write-Host $d
    if ($d -match "\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}")
    {
        $cdt = $matches[0]
        $date,$time = $cdt -split ' '
        $yr,$mo,$dy = $date -split '-'
        #Write-Host $yr,$mo,$dy
    }
    else
    {
        "Get-Clip-Start-Stop-Duration: Couldnt extract creation date"
        return $false
    }
    
    $t=select-string -list -path tcmd.txt -pattern "TAG\:timecode"
    #Write-Host $t
    if ($t -match "\d{2}\:\d{2}\:\d{2}\;\d{2}")
    {
        $startstr=$matches[0]
        $h,$m,$sf = $startstr -split ":"
        $s,$f = $sf -split ';'
        $start_timecode = $h, $m, $s -join ':' 
        Write-Host $start_timecode
    }
    else
    {
        Write-Host "Get-Clip-Start-Stop-Duration: Bad extraction of time code"
        return $false
    }
        
    $du=select-string -list -path tcmd.txt -pattern "duration="
    #Write-Host $du
    if ($du -match "\d+\.\d+")
    {
        $duration = $matches[0]
        #Write-Host $yr $mo $dy $h $m $s
        $startdatetime = Get-Date -year $yr -month $mo -day $dy -hour $h -minute $m -second $s
        $enddatetime = $startdatetime.AddSeconds($duration)
        $sdatestr = $startdatetime.ToString("yyyyMMddHHmmss")
        $edatestr = $enddatetime.ToString("yyyyMMddHHmmss")
        return $sdatestr, $edatestr, $duration
    }
    else
    {
        Write-Host "Get-Clip-Start-Stop-Duration: Couldnt extract clip duration" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
        return $null
    }
 