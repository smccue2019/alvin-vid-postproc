<#
A script to rename subtitle files.
Renames barebones subititles to add "_bb" at the end of the basename.
Renames scc-containing files so that basename matches the proxy video basename.
smccue@whoi.edu
#>

$bblist=Dir AL????_??????????????-??????????????.srt
$scclist=Dir AL????_??????????????-??????????????_scc_???.srt

if ($bblist.count -eq 0) {
   Write-Host "No barebones subititle files found. Quitting"
   return $null
}

if ($scclist.count -eq 0) {
   Write-Host "No scc-based subititle files found. Quitting"
   return $null
}

# First rename the basebones files 
ForEach ($bbfile in $bblist) {
  $bbfilebase = $bbfile.Basename
  $bbfilepath = $bbfile.DirectoryName
  $newname = $bbfilepath + "\" + $bbfilebase + "_bb.srt"
  Write-Host "$bbfile renamed to $newname"
  Rename-Item $bbfile $newname
}

# Now the scc-based files. Expected form is AL<dive#>_<starttime>-<stoptime>_scc_<rec>.srt.
# dive# is 4 digits, time is 14 digits, rec is 3 characters.
ForEach ($sccfile in $scclist) {
  $sccfilebase = $sccfile.Basename
  $sccfilepath = $sccfile.DirectoryName
  $newbase = $sccfilebase.substring(0, $sccfilebase.length-8)
  $newname = $sccfilepath + "\" + $newbase + ".srt"
  Write-Host "Rename $sccfile to $newname"
  Rename-Item $sccfile $newname
}
