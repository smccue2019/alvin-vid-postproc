param (
    [string]$diveID = $(throw "-diveID (AT1234) is required"),
    [string]$filelist = $(throw "-filelist is required")
 #   [string]$vid_date = Get-Date -displayhint date
    ) 

$vids = Dir $filelist
ForEach ($file in $vids)
{
    Write-Host "$file"
    c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $file > tcmd.txt
    Try
    {
        $t=select-string -list -path tcmd.txt -pattern "TAG\:timecode"
        $t -match "\d{2}\:\d{2}\:\d{2}\;\d{2}"
        $startstr=$matches[0]
        $hr,$min,$sec_frame=$startstr -split ':'
        $sec,$frame = $sec_frame -split ';'
        
#        Write-Host "$startstr"
        # Convert xx:xx:xx;xx to a start string
    }
    Catch
    {
        Write-Host "Bad conversion of timecode."
    }

    Try
    {
        $d=select-string -list -path tcmd.txt -pattern "duration="
        $d -match "\d+\.\d+"
        $duration = $matches[0]
#        Write-Host "$duration"
    }
    Catch
    {
        # Bad conversion of duration time
    }
    $startdatetime = Get-Date -hour $hr -minute $min -second $sec 
    $enddatetime = $startdatetime.addSeconds($duration) 
    $sdatestr = $startdatetime -format yyyyMMddHmmss
    $edatestr = $enddatetime -format yyyyMMddHmmss
    Write-Host "$sdatestr"
    Write-Host "$edatestr"
     
    $newname =ALDDDD_$startdatetime.-$enddatetime.mov
    Write-Host $newname
#    rename-item -path $infile -newname $newname
}