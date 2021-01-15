<#
.SYNOPSIS
Build-ClipName uses metadata embedded within a ProRes422 file to
fabricate a more descriptive name that is based on capture time.
The clip must have embedded timecode and a properly set capture
date.
.DESCRIPTION
Build-ClipName is used to generate a string based on information
embedded within a video clip, presumably a ProRes422 clip that was
recorded by an Atomos Samurai recorder. The required information
consists of clip creation date, start time code, clip duration,
and dive identity. The latter must be passed as an argument.
.PARAMETER clipname
Required. The name of the clip for which a new name is to be built.
The usual form is '0000.MOV'.  
.PARAMETER diveID
Required. Alvin dive number. Either a string of 4 numerical digits,
e.g., '4651' or 4 digits preceded by 'AL', e.g. 'AL4651' will be
accepted. The former will be morphed into the latter.
#>
param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $clipname,
    [Parameter(Position=1, Mandatory=$true)]
    [string] $diveID)
     # end param
    
    if (Test-Path $clipname)
    {
        Write-Host "Building new clip name for $clipname"  
    }
    else
    {
        Write-Host "$clipname was not found"
        # Exit the script
        return $false
    }
    
    # Now that we know that the source file exists...

    # If diveID is only a number, prepend "AL"
    if ($diveID -match "AL\d{4}")
    {
        Write-Host "$diveID is in proper form."
    }
    elseif ($diveID -match "\d{4}")
    {       
        $diveID = "AL", $diveID -join ""
        Write-Host "DiveID rewritten as $diveID"
    }
    else
    {
        Write-Host "DiveID is in incorrect format, $diveID"
        return $false
    }
    
    # ffprobe is annoyingly verbose, spewing compilation info out to STDERR. Redirect
    # to out-null.
    # Pull the clip creation date, starting timecode and clip duration from the source video file
    $(c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $clipname > tcmd.txt) 2>&1 | out-null
    
    $d=select-string -list -path tcmd.txt -pattern "TAG\:creation_time"
    if ($d -match "\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}")
    {
        $cdt = $matches[0]
        $date,$time = $cdt -split ' '
        $yr,$mo,$dy = $date -split '-'
    }
    else
    {
        "Couldnt extract creation date"
        return $false
    }

    
    $t=select-string -list -path tcmd.txt -pattern "TAG\:timecode"
    if ($t -match "\d{2}\:\d{2}\:\d{2}\;\d{2}")
    {
        $startstr=$matches[0]
        $s,$f = $sf -split ';'
        $start_timecode = $h, $m, $s -join ':' 
    }
    else
    {
        Write-Host "Bad extraction of time code"
        return False
    }


    $du=select-string -list -path tcmd.txt -pattern "duration="
    if ($du -match "\d+\.\d+")
    {
        $duration = $matches[0]
    }
    else
    {
        Write-Host "Couldnt extract clip duration"
        return False
    }
    
    # End time is start + duration. Assemble the constituents.
    $startdatetime = Get-Date -year $yr -month $mo -day $dy -hour $h -minute $m -second $s
    $enddatetime = $startdatetime.AddSeconds($duration)
    $sdatestr = $startdatetime.ToString("yyyyMMddHmmss")
    $edatestr = $enddatetime.ToString("yyyyMMddHmmss")
     
    $newname =$diveID, "_", $sdatestr, "-", $edatestr, ".mov" -join ""
    
    # Create csv line that will be appended to log
    $record = $clipname,$cdt,$startstr,$duration,$sdatestr,$edatestr,$newname -join ','
    Add-Content -path "rename_log.txt" -value $record
