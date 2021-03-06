$mov_list = Dir *.MOV

$targetvidsize="960x540"

$sourceframerate = 29.97
$timecoderate = $sourceframerate

ForEach ($movfile in $mov_list)
{
    $lst = Get-Date
    # Generate an outfile name from the infile name
    $outbase = [System.IO.Path]::GetFileNameWithoutExtension($movfile)
    $oul = $outbase.toLower()
    $ou = $oul, "mkv"
    $outfile = $ou -join "." 
    # Write-Host $movfile $outfile
    
    # Pull the starting timecode from the source video file
    $($a,$b,$h,$m,$sf = c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $movfile.Name | select-string -list -pattern "TAG\:timecode" | %{$_ -split '='} | %{$_ -split ':'}) 2>&1 | out-null
    $s,$f = $sf -split ';'
    $start_timecode = $h, $m, $s -join ':'
        
    Write-Host "Transcoding $movfile to $outfile, with start timecode of $start_timecode" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
       
    # This one is targeted at iPad
    $(c:\ffmpeg\bin\ffmpeg.exe -loglevel error -threads 0 -probesize 5000000 -i $movfile.Name -s $targetvidsize -vcodec libx264 -preset faster -r $timecoderate $outfile) 2>&1 | out-null
    $elapsed = new-timespan -start $lst
    Write-Host "Transcode completed in $elapsed"
}