<#
.SYNOPSIS
A script that invokes ffmpeg to concatenate videos.
.DESCRIPTION
Sequentially merges video clips into a single longer clip. The names
of the clips are passed in via a text file, which lists the files to
be merged. The files must be listed in order of concatenation. The
format of the list is:
file name1.mp4
file name2.mp4
file name3.mp4
where name should be of form "AL1234_20130805005250-20130805005932.mp4"
.PARAMETER outfilename
.PARAMETER concatlist
.PARAMETER outformat
.PARAMETER logfile
A text file of format as described above.
#>

    param (
        [Parameter(Position=0, Mandatory=$true)]
        [string] $outfilename
        [Parameter(Position=1, Mandatory=$true)]
        [string] $concatlist,
        [Parameter(Position=3, Mandatory=$false)]
        [string] $outformat = "mkv",
        [Parameter(Position=4, Mandatory=$false)]
        [string] $logfile
    )
    
    # If a logfile name wasn't passed as an argument,
    # generate one based on the date
    if (-not $logfile)
    {
        $dts = Get-Date -format "yyyyMMddHmmss"
        $logfile = "concat_log", $dts -join "_"
    }
    
    # Read concatlist into an array and pull out filenames,
    # then write a line giving sources and out to a logfile
    $fl = @()
    $fc = Get-Content $concatlist  
    ForEach ($line in $fc)
    {
        $f, $filename = $line -split " "
        $fl += $filename
    }
    $cs = $fl -join " "
    $lm = $cs, "==>", $outfilename -join " "
    Add-Content -path $logfile -value $lm
    
    # The meat of the script
    # stderr sent to out-null to cut down on ffmpeg verbosity
    $(c:\ffmpeg\bin\ffmpeg.exe -f concat -i $concatlist -c copy $outfilename) 2>&1 | out-null
    
    
    
    