
Try
{
    $infile = Argument[0]
}

Try
{
    c:\ff]mpeg\bin\ffprobe.exe -show_streams:tcmd -Argument[0] > tcmd.txt
}
#Catch [FileDiesntExist],[Execuatble Missing]
{
    #Alert and quit
}

Try
{
$t=select-string -list -path tcmd.txt -pattern "TAG\:timecode"
$t -match "\d{2}\:\d{2}\:\d{2}\;\d{2}"
$startstr=$matches[0]
# Convert xx:xx:xx;xx to a start string
}
Catch
{
    # Bad conversion of timecode.
}

Try
{
    $d=select-string -list -path tcmd.txt -pattern "duration"
    $d -match "\d+\.\d+"
    $duration = $matches[0]
}
Catch
{
    # Bad conversion of duration time
}
$newname =ALDDDD_$startstring-$endstring.mov
rename-item -path $infile -newname $newname
