<#
.SYNOPSIS
A script that creates a video compressed by h.264 from a
video compressed by ProRes422 and places it into an .mkv
container.
.DESCRIPTION
Alvin recorders compress raw video streams using one of
the Apple ProRes family of codecs. The result is useful for
and end user who will apply non-linear editing. But it is
not as useful for those who wish simply to watch a video
on their handheld or laptop device. The original filesize
is large, the display window is large, and not all playback
software handles the codec.
This utility invokes the well-known utility 'ffmpeg' to make
this conversion. At conversion time the display window is
halved on each side. So, the original was recorded at 1920x1080
pixels. The transcoded result is created at 960x540 pixels.
.PARAMETER src_clip
Filename of the ProRes422 clip. Required, or the shell will get you.
.PARAMETER new_clip
Filename for the converted result. Acquired from Build-Clipname.
Not required- the basename of src_clip will be used.
.PARAMETER resolution
width x height size in pixels. Not required, default is 960x540.
.NOTES
Author Scott McCue NDSF Data Manager, smccue@whoi.edu, x3462
HISTORY
Sept2013 SJM Creation and testing
14Nov2013 SJM Added help section.
#>

param (
    [Parameter(Position=0, Mandatory=$true)]
    [string] $src_clip,
    [Parameter(Position=1, Mandatory=$false)]
    [string] $new_clip,
    [Parameter(Position=2, Mandatory=$false)]
    [string] $resolution = "960x540"
    )

$sourceframerate = 29.97
$timecoderate = $sourceframerate

Write-Host $src_clip

# If a destination clip name wasn't passed, generate a default one based on src clip name
if (-not $new_clip)
{
   # Generate an outfile name from the infile name
    $outbase = [System.IO.Path]::GetFileNameWithoutExtension($src_clip)
    $oul = $outbase.toLower()
    $new_clip = $oul, "mkv" -join "."
}

if ( Test-Path $src_clip)
{
            
Write-Host "Transcoding $src_clip to $new_clip" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"

$lst = Get-Date
       
$(c:\ffmpeg\bin\ffmpeg.exe -threads 0 -probesize 5000000 -i $src_clip -s $resolution -vcodec libx264 -preset fast -r $timecoderate $new_clip) 2>&1 | out-null
#c:\ffmpeg-20130108\bin\ffmpeg.exe -threads 0 -probesize 5000000 -i $src_clip -s $resolution -vcodec libx264 -preset faster -r $timecoderate $new_clip

$elapsed = new-timespan -start $lst
Write-Host "Transcode completed in $elapsed" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
}
else
{
Write-Host "No $src_clip"
}