<#
.SYNOPSIS
SubtitleSccToSrt.ps1
A script that generates subtitle files from information provided by
tabular data in a .scc file, and time information provided by the
metadata fork of a ProRes422 video file.
.DESCRIPTION
Navigation post-processing ("renavigation") creates a file that presents navigation and
sensor data on a 1Hz timeline. The ability to overlay these data during playback of proxies
adds value for the science community. This is done through the subtitling
mechanism, which requires the creation of a text file of strict format (we use the .srt
format) to define the timing and content of the overlain information.
#
This script takes in a hash that represents the content of a .scc file. It also requires the
name of a ProRes422 video clip, which it will probe to determine start time and duration.
A path to an ini file is also needed (a default is defined) so that dive and subtitle text
configurations can be used. The script then loops through the duration of the timeline to
pull scc content and write it in srt-format stanzas to a subtitle file.
#
The subtitle filename denotes diveID, start time, stop time, recorder nickname, and includes "scc"
to indicate its use of external content from the renaviation file.
#
.PARAMETER sccfilename (Mandatory)
Full path to the .scc-format file that resulted from renavigation.
.PARAMETER scchash (Mandatory)
Variable naming the hash reference to the content of the scc file. The hash table
would have already been constructed by the scipt SCC-To_Hash.ps1.
.PARAMETER nnadd (Mandatory)
A string giving the nickname of the recorder that captured the clip. Will be added
to the subtitle filename. Typically "prt" or "std".
.PARAMETER inifile (Optional)
Full path to ini file containing cruiseID and diveID info. Defaults to D:\Alvin.ini.
.PARAMETER srtadd (Optional)
String to be added to subtitle filename to indicate data source. Default = "scc".
.REQUIRES
Import-ini.ps1, ffprobe (.exe from ffmpeg suite)
.AUTHOR
Scott McCue, smccue@whoi.edu
Data Manager, National Deep Submergence Facility
HISTORY
10/2016 Create and test
#>

param (
       [Parameter(Mandatory=$true)]
       [string]$clipfilename,
       [Parameter(Mandatory=$true)]
       [hashtable]$scchash,
       [Parameter(Mandatory=$true)]
       [string]$nnadd,
       [Parameter(Mandatory=$true)]
       [string]$inifile="D:\Alvin.ini",
       [Parameter(Mandatory=$false)]
       [string]$sccadd = "scc"
    )

# Used later in computing unix epoch seconds
$unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)

# Import the ini file to obtain dive, cruise, and subtitle setup. Defaults
# to looking for D:\Alvin.ini if not passed as an argument to this script. 
if ( Test-Path $inifile) {
    Write-Host "SubtititleSccControl: using ini file passed to me as argument: $inifile"
    $h = c:\Scripts\Import-ini.ps1 -IniFile:$inifile
    $cruiseID = $h.CRUISE.cruiseID
    $diveID = $h.DIVE.diveID
    $srt1 = $h.SUBTITLE.srt_param1
    $srt2 = $h.SUBTITLE.srt_param2
    $srt3 = $h.SUBTITLE.srt_param3
    $srt4 = $h.SUBTITLE.srt_param4
    $srt5 = $h.SUBTITLE.srt_param5
    $srt6 = $h.SUBTITLE.srt_param6
    $srt1pf = $h.SUBTITLE.srt_param1_prefix
    $srt2pf = $h.SUBTITLE.srt_param2_prefix
    $srt3pf = $h.SUBTITLE.srt_param3_prefix
    $srt4pf = $h.SUBTITLE.srt_param4_prefix
    $srt5pf = $h.SUBTITLE.srt_param5_prefix
    $srt6pf = $h.SUBTITLE.srt_param6_prefix
    $srt1sf = $h.SUBTITLE.srt_param1_suffix
    $srt2sf = $h.SUBTITLE.srt_param2_suffix
    $srt3sf = $h.SUBTITLE.srt_param3_suffix
    $srt4sf = $h.SUBTITLE.srt_param4_suffix
    $srt5sf = $h.SUBTITLE.srt_param5_suffix
    $srt6sf = $h.SUBTITLE.srt_param6_suffix
}
elseif (Test-Path D:\Alvin.ini)
{
    Write-Host "SubtititleSccControl: using default Alvin.ini file under D:"
    $h = c:\Scripts\Import-ini.ps1 -IniFile:"D:\Alvin.ini"
    $cruiseID = $h.CRUISE.cruiseID
    $diveID = $h.DIVE.diveID
    $srt1 = $h.SUBTITLE.srt_param1
    $srt2 = $h.SUBTITLE.srt_param2
    $srt3 = $h.SUBTITLE.srt_param3
    $srt4 = $h.SUBTITLE.srt_param4
    $srt5 = $h.SUBTITLE.srt_param5
    $srt6 = $h.SUBTITLE.srt_param6    
    $srt1pf = $h.SUBTITLE.srt_param1_prefix
    $srt2pf = $h.SUBTITLE.srt_param2_prefix
    $srt3pf = $h.SUBTITLE.srt_param3_prefix
    $srt4pf = $h.SUBTITLE.srt_param4_prefix
    $srt5pf = $h.SUBTITLE.srt_param5_prefix
    $srt6pf = $h.SUBTITLE.srt_param6_prefix      
    $srt1sf = $h.SUBTITLE.srt_param1_suffix
    $srt2sf = $h.SUBTITLE.srt_param2_suffix
    $srt3sf = $h.SUBTITLE.srt_param3_suffix
    $srt4sf = $h.SUBTITLE.srt_param4_suffix
    $srt5sf = $h.SUBTITLE.srt_param5_suffix
    $srt6sf = $h.SUBTITLE.srt_param6_suffix
}
else
{
    Write-Host "Quitting: Must specify an ini file. Default=D:\Alvin.ini"
    return 1
}


# Now examine the metadata fork of the ProRes422 video clip and get its timecode info. 
if (-not (Test-Path $clipfilename)) {
   Write-Host "$clipfilename was not found"
   # Exit the script
   return $null
}

# ffprobe is an independent program from the ffmpeg suite.    
$(c:\ffmpeg\bin\ffprobe.exe -show_streams:tcmd $clipfilename > tcmd.txt) 2>&1 | out-null
    
$d=select-string -list -path tcmd.txt -pattern "TAG\:creation_time"
if ($d -match "\d{4}\-\d{2}\-\d{2}\s\d{2}\:\d{2}\:\d{2}") {
   $cdt = $matches[0]
   $date,$time = $cdt -split ' '
   $yr,$mo,$dy = $date -split '-'
}
else {
   Write-Host "scc2subtitle: Couldnt extract creation date from tcmd" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
   return $null
}
   
$t=select-string -list -path tcmd.txt -pattern "TAG\:timecode"
if ($t -match "\d{2}\:\d{2}\:\d{2}\;\d{2}") {
   $startstr=$matches[0]
   $h,$m,$sf = $startstr -split ":"
   $s,$f = $sf -split ';'
   $start_timecode = $h, $m, $s -join ':' 
} elseif ($t -match "\d{2}\:\d{2}\:\d{2}\:\d{2}") {           
   $startstr=$matches[0]
   $h,$m,$s,$f = $startstr -split ":"
   $start_timecode = $h, $m, $s -join ':' 
} else {
   Write-Host "Bad extraction of time code" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
   return $null
}

$du=select-string -list -path tcmd.txt -pattern "duration="
if ($du -match "\d+\.\d+") {
   $duration = [decimal]$matches[0]
} else {
   Write-Host "Couldnt extract clip duration" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
   return $null
}

$durationflr = [Math]::Floor($duration)
$durationfull = [double]$durationflr
$startdatetime = Get-Date -year $yr -month $mo -day $dy -hour $h -minute $m -second $s
$enddatetime = $startdatetime.AddSeconds($durationfull)
$unixstartclip = [int]($startdatetime - $unixEpochStart).TotalSeconds
$unixendclip = [int]($unixstartseconds) + $durationflr
$sdatestr = $startdatetime.ToString("yyyyMMddHmmss")
$edatestr = $enddatetime.ToString("yyyyMMddHmmss")
    
$srtname = $diveID, "_", $sdatestr, "-", $edatestr, "_", $srtadd, "_", $nnadd, ".srt" -join ""

# If a subtitle file of the same name already exists, delete and overwrite it.
if (Test-Path $srtname) {
  Del $srtname
}

#$(get-location).Path
 
$srtstartdatetime = Get-Date -year $yr -month $mo -day $dy -hour 0 -minute 0 -second 0

$dur_seci = [int]$durationflr
#$dur_seci = 1
for ($i=1; $i -le $dur_seci; $i++) {

    $time_inc = [double](2.0*$i)
    $unixsecinloop = [int]($unixstartclip + $time_inc)   
    $un = [string]$unixsecinloop          # Use this as hash index to find coincident data
    

    $srt_stime = $srtstartdatetime.AddSeconds($time_inc)
    $srt_sstr = $srt_stime.ToString("HH:mm:ss,fff")
    $srt_etime = $srt_stime.AddMilliseconds(1500.0)
    $srt_estr = $srt_etime.ToString("HH:mm:ss,fff")
    $srt_display = $startdatetime.AddSeconds($time_inc)
    $srt_dispstr = $srt_display.ToString("yyyy/MM/dd HH:mm:ss")
    
    # $srt?, $srt?pf, and $srt?sf are tsrings defined in Alvin.ini.
    # $scchash is a hash of hashes, with each unix time key pointing at a hash object containing 
    # sensor measurements id'ed by sensor in a name-value pair.
    # $srt? defines the name for pulling a value out of the hash object for this unix time.
    # So, if $srt1 is 'Depth' then then $srtp1 is assigned the value for depth for time $un 
    $srtp1 = ($scchash[$un] | Select -ExpandProperty $srt1)
    $srtp2 = ($scchash[$un] | Select -ExpandProperty $srt2)
    $srtp3 = ($scchash[$un] | Select -ExpandProperty $srt3)
    $srtp4 = ($scchash[$un] | Select -ExpandProperty $srt4)
    $srtp5 = ($scchash[$un] | Select -ExpandProperty $srt5)
    $srtp6 = ($scchash[$un] | Select -ExpandProperty $srt6)
    
    # Concatenate prefix, value, and suffix strings into one.
    $srtstr1 = $srt1pf + $srtp1 + $srt1sf
    $srtstr2 = $srt2pf + $srtp2 + $srt2sf
    $srtstr3 = $srt3pf + $srtp3 + $srt3sf
    $srtstr4 = $srt4pf + $srtp4 + $srt4sf
    $srtstr5 = $srt5pf + $srtp5 + $srt5sf
    $srtstr6 = $srt6pf + $srtp6 + $srt6sf
                    
    # Write a new subtitle stanza out to the file defined by $srtname
    # .srt format is four lines
    # line 1 = stanza count, an integer starting at 1.
    # line 2 = display start and stop time for content in line 3, relative to clip start time.
    # line 3 = text to overlay on displayed clip.
    # line 4 = empty line
    Write-Output $i >> $srtname
    Write-Output "$srt_sstr --> $srt_estr" >> $srtname
    Write-Output "$srtstr1 $srtstr2 $srtstr3 $srtstr4 $srtstr5 $srtstr6" >> $srtname
#   Write-Output "$srtstr1 $srtstr2 $srtstr3 $srtstr4 $srtstr5" >> $srtname
    Write-Output "" >> $srtname
}

$srtinfo = Get-ChildItem $srtname | Select -Expandproperty Fullname
return $srtinfo