#############################################################################
# Scriptname:	Get-SettingsIni.ps1
# Author:		(C) Gerry Bammert
# Version:		1.05
# Date:			May 20 2009
# ###########################################################################
#				
# Description:	- This Script reads the contents of an .ini file.
# 				- Blank lines and lines beginning with '[' or ';' are
# 				  ignored.
#				- The function Get-Settings() returns the result in
# 				  $hashtable as a hash table.
#				  --> $hashtable = (Get-Content $path | Get-Settings)
# Usage:        - To get an item from the hashtable use the Item method.
#				  --> Write-Host $hashtable.Item("ThanksTo")
#				- Restrictions: The hash table contains all the key and value
#				  pairs. Do not use the same key twice in the same ini file!
#
#               - function Get-ScriptPath() gets the path of the running script.
#
# Sample inifile  MyProg.ini:
#
# [Global]
# HomePath="C:\Programme\Myprog"
# Start="C:\Programme\Myprog\myprog.exe"
# DataPath="%USERPROFILE%\Eigene Dateien"
# AppPath="%USERPROFILE%\Anwendungsdaten\Myprog"
# 
# [Resolution]
# vga=640x480
# svga=800x600
# xga=1024x768
# win7=15240x10480
# 
# [Features]
# Windows7supported=True
# VerboseLogging="oh nooo!"
# 
# [PowerShell]
# ThanksTo=Thanks to Jeffrey Snover :)
#
#############################################################################


# ***************************************************************************
# ************ Functions ****************************************************
# ***************************************************************************


# Each line of the .ini File will be processed through the pipe.
# The splitted lines fill a hastable. Empty lines and lines beginning with
# '[' or ';' are ignored. $ht returns the results as a hashtable.
function Get-Settings()
{
	BEGIN
	{
		$ht = @{}
	}
	PROCESS
	{
		$key = [regex]::split($_,'=')
		if(($key[0].CompareTo("") -ne 0) `
		-and ($key[0].StartsWith("[") -ne $True) `
		-and ($key[0].StartsWith(";") -ne $True))
		{
			$ht.Add($key[0], $key[1])
		}
	}
	END
	{
		return $ht
	}
}

# Gets the path of the running script.
function Get-ScriptPath ([System.String]$Script = "", `
[System.Management.Automation.InvocationInfo]$MyInv = $myInvocation)
{
	$spath = $MyInv.get_MyCommand().Definition
	$spath = Split-Path $spath -parent
	$spath = Join-Path $spath $Script
	return $spath
}


# ***************************************************************************
# ************ Main-Program *************************************************
# ***************************************************************************

$path = Get-ScriptPath
# $path sets the path of this running script. You may change the path as you need. 
$path = ($path + "MyProg.ini")

$hashtable = (Get-Content $path | Get-Settings)

# To get an item from the hashtable use the Item method.
Write-Host $hashtable.Item("ThanksTo")

