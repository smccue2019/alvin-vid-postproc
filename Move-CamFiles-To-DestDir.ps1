<#
.SYNOPSIS
Move-CamFiles-To-DestDir changes the path at which original
recordings from Alvins science cameras are located.
.DESCRIPTION
Move-CamFiles-To-DestDir is intended to be called from a
higher level script, but can be called interactively. It
expects arguments denoting paths to clips from one of two
cameras, 'Cam1' or 'Cam2', but had defaults that the script
will  attempt to use of these paths are not passed as arguments.
Results are simple. Original recordings will come off
recorder hard drives into a path under'Cam1' or 'Cam2' that
looks like 'SCENE001\SHOOT001\TAKE001'. This script will go
to this directory, confirm the presence of clips, and move them
to the standard destination.
.PARAMETER camname
Required. This helps name two directories. The first instance is the
top level of the hierarchy under which the recorder hard drive was
dumped, a la 'CamName\SCENE001\SHOOT001\TAKE001'. The second
instance will be added to name the destination directory, a la
'Originals\CamName'.
.PARAMETER srcsubpath
Default available if not passed. The remainder of the path to the
clips off the recorder, under the string passed as 'CameraName'.
Default is 'SCENE001\SHOOT001\TAKE001'. This yields a relative path,
not an absolute path.
.PARAMETER desttoppath 
Default available if not passed. Overrides the relative pathway to
the destination for the clips, a la 
'\<Host>\<RAID>\<CRUISEID>\<DIVEID>\Originals\CameraName\', under
which *.MOV will be placed.
.EXAMPLE
Move-CamFiles-To-DestDir -camname StbdSci [-srcsubpath SCENE001\SHOOT001\TAKE002] 
[-desttoppath \\1B3823\1B3858\AT26-05_Hickey13\AL4679\Video\Originals\] 
#>
  
param (
    [string]$camname = $(throw "Move-CamFiles-To-DestDir: Camera Name required"),
    [string]$inpath = ".\SCENE001\SHOOT001\TAKE001"
    [string]$outpath = ".\OriginalClips\Cam1"
    ) 
    
Move-CamFiles-To-DestDir -CamName $CamName -inpath $inpath -outpath $outpath

# Confirm there are clips in the source directory
# Does source directory exist? If yes, $vidlist = Dir *.MOV, else quit with error.
# Do a Dir *.MOV. Does the resulting list have elements? If yes, continue; else error.

# Confirm the destination path 
# Check to see if everything above "CamName" subdir exists. If yes, continue.
# Was mkdir of dest dir successful? If yes, continue.
#   If no, was it because full path is wrong or because dest dir already exists?
#   Alert caller to either case.
 