<#
.SYNOPSIS
A script that controls the concatenation of a few smaller clips into a single
larger clip.
.DESCRIPTION
Each Alvin dive will produce several hours of high definition recordings. At the
time of recording the video is split into clips of a few minutes duration due to
filesize limitations of the FAT32 filesystem. Two cameras recording several hours
each will yield several dozen clips. To minimize the book-keeping required for so
many clips, this script stitches several of them together.
The general method is to create a list of small sized clips and to iterate through
them, merging groups of size defined by the user. The resulting larger clip is to be
placed in a nearby subdirectory.
.REQUIRES
Concat-Proxies.ps1
.PARAMETER sourcepath
Directory containing the clips
.PARAMETER groupsize
How many files to concatanate into the larger file
.PARAMETER vidtype
The file format for incoming and outgoing video files. 
#>
   param (
        [Parameter(Position=0, Mandatory=$true)]
        [string] $sourcepath,
        [int] $groupsize = 5,
        [string] $vidtype = "mkv"
    )
 
$filetype = "test*", $vidtype -join '.'
$fullfilelist = Dir $filetype | sort-dir

$cntr=0
$totalcntr=10
~/bin/Touch-File.ps1 vidgroup.txt

ForEach ($vidfile in $fullfilelist)
{
    # Write-Host $vidfile
    $totalcntr++
    $str = "file", $vidfile.Name, $totalcntr, $cntr -join ' '
    Add-Content -path "vidgroup.txt" -value $str
    $cntr++
    if ($cntr -eq 5)
    {
        $cntr = 0
        $nn = "group",$totalcntr,"mp4" -join "."
        Rename-Item "vidgroup.txt" $nn
    }
}