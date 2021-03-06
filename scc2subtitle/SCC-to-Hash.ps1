<#
.SYNOPSIS
scc2hash ingests an scc-format file and creates a hash
table of the contents, then passes a reference to the hash
back to the calling routine.
The .scc file presents a tabular timeseries of navigation and
sensor data. Originated in AUV Sentry post-processing, in this case
it is produced in this routine by HOV Alvin navigation post-processing.
For Alvin, the time frame should represent a single dive of
typically about eight hours. Nominal record update rate is 1Hz.
Populated fields vary according to the sensors installed on Alvin
during the dive (there is typically a placeholder value such as
-999.99 when a sensor was not used); in any case one can expect
that the .scc table will include date, time, lat, lon, depth, and
heading.
The table is parsed and organized into a hash of .NET objects as
the data structure (cloest I could come to a hash of hashes). The
hash key is each .scc record's unix epoch time, in integer seconds,
as a string. This key is produced by converting each record's date
and time. The navigation and sensor fields are parsed and cast into
a .NET object of name-value pairs. 
Prior to assembling the hash table, reasonable truncation is applied to
the values of some of the sensors. In particular, heading is changed
to be a signed 3 digit integer (so 4 digits total) and depth is truncated
to an integer. I pondered whether to do that here or in the script that
writes the subtitle file. Since the writing script doesn't know what
variables it's writing, I decided to do it here.
.DESCRIPTION
Creates a hash table from the contents of an .scc file.
.PARAMETER
sccfilename. Mandatory
.AUTHOR
Scott McCue WHOI/NDSF smccue@whoi.edu
.HISTORY
Sept2016 Creation as part of an effort to use scc file info in video subtitles.
Each row of the .scc table is parsed and assigned to fields with the following 
names:
Date, Time, Lat, Lon, Depth, Pressure, Heading, Altitude, Magx, Magy, Magz,
Obs, Eh, Dehdt, O2, Temp, Conductivity, SoundSpeed, SVPSoundSpeed, Orp.

Code in the calling routine can pull values for fields of interest using:
<field> = ($hashref[<unixepochsec>] | Select -ExpandProperty "Field")
For example,
$un = "1470489322"
$hdepth = ($sht[$un] | Select -ExpandProperty "Depth") 
      
3Oct2016 SJM Added Try-Catch to deal with the occasional instances of .scc times
that have a seconds value of '60'. Legal 'DateTime' commandlet seconds range
is 0-59.   

10Oct2016 SJM Refomatted depth to integer and heading to three digit integer.
17Oct2016 SJM Reformatted time to integer seconds.
#>

param (
       [Parameter(Position=0, Mandatory=$true)]
       [string]$sccfilename
    )

$sh = @{};
$rh = @{};
$unixEpochStart = new-object DateTime 1970,1,1,0,0,0,([DateTimeKind]::Utc)

Write-Host "SCC-to_Hash.ps1: Starting conversion of file $sccfilename to hash table"

# Ingest the .scc file and populate a hash of hashes table 
Try {
  $sc = Get-Content $sccfilename
}
Catch [ItemNotFoundException] {
  Write-Host "Didnt find $sccfilename" -backgroundcolor "Red" -foregroundcolor "Green"
  return $null
}

foreach ($row in $sc) {  

   if ($row -match "^SCC 20") {
      # Parse each row into variable
      # Once date and time are parsed, use them to create unix time to be used as hash table key.
      $fields = $row.split(" ")
      $date = [string]$fields[1]
      $time = [string]$fields[2]
      # Problems with the .scc file containing times with "60" seconds, e.g.,  2016/08/06 18:33:60.00
      # mean using a try-catch. Note: the error is "Category unspecified", a RunTimeError.
      Try {
          $dt = [DateTime]($date + " " + $time)
      }
      Catch {
          if ($time -match "\d{2}\:\d{2}\:\d{2}") {
             $timestr=$matches[0]
             $h,$m,$sf = $timestr -split ":" 
             $fakesf = [string]([decimal]$sf - 1.0)
             $faketimestr = $h, $m, $fakesf -join ':'
             $fakedt = [DateTime]($date + " " + $faketimestr)
             $dt = $fakedt.AddSeconds(1)
          } else {
               Write-Host "Bad extraction of time code in scc2hash" -backgroundcolor "DarkBlue" -foregroundcolor "Yellow"
          }
      }    
             
             
      $ut = [int]($dt - $unixEpochStart).TotalSeconds 
      $a = $unixEpochStart.addSeconds($ut)
      $time_intsec = $a.toString("HH:mm:ss")
      $uts = [string]$ut
      
      #Write-Host "$time $time_intsec"
      
      $lat = $fields[3]; $lon = $fields[4]; $depth = $fields[5]; $heading = $fields[7]; $alt = $fields[8]; $temp = $fields[16]
      $pressure = $fields[6]; $magx = $fields[9]; $magy = $fields[10]; $magz = $fields[11]; $obs = $fields[12]; $eh = $fields[13]; $dehdt = $fields[14]; $o2 = $fields[15]; $cond = $fields[17];
      $sv = $fields[18]; $svp = $fields[19]; $orp = $fields[20]

      $depthi = [string][int]$depth
      $headingi = "{0:D3}" -f [int]$heading
      
      #Write-Host $depthi $headingi
     
      $rh = (New-Object PSObject -Property @{Date=$date;Time=$time_intsec;Lat=$lat;Lon=$lon;Depth=$depthi;Pressure=$press;Heading=$headingi;Altitude=$alt;Magx=$magx;Magy=$magy;Magz=$magz;Obs=$obs;Eh=$eh;Dehdt=$dehdt;O2=$o2;Temp=$temp;Conductivity=$cond;SoundSpeed=$sv;SVPSoundSpeed=$svp;Orp=$orp})
      $sh[$uts]=@($rh)
    }
}          

Write-Host "SCC-to-Hash.ps1: Finished creation of hash table"
return @($sh)