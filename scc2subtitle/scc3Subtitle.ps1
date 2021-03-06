
$unixEpochStart = new-object DateTime 1970,1,1,0,0,0,(DateTimeKind]::Utc)
$csv = import-csv "AL4835_20160808_1845.scc"

foreach ($row in $csv)
{
   $date = $row.("yyyy/mm/dd")
   $time = $row.("hh:nn:ssss")
   
   $dt = $date + " " + $time
   
   $dtu = [int]($dt - $unixEpochStart).TotalSeconds
   
}