#requires -version 2

<#
.SYNOPSIS
	Imports ini file.

.DESCRIPTION
	Parse content of ini file into section nested hash table.
	'#' and ';' can be used as line comment.
	Quoted values and expressions between $() redirected to Invoke-Expression.(executed as powershell command.)

.INPUTS
	You can pipe a filename as string input to this script.

.OUTPUTS
	[System.Collections.Hashtable]

.EXAMPLE
	$iniObj = Import-Ini -iniFile:test.ini

.EXAMPLE
	$ini = "test.ini" | Import-Ini

.EXAMPLE
	Get-Content .\test.ini
	[SectionA]
	Key1=A1
	; commentA1
	Key2=A2

	[SectionB]
	Key1=B1
	Key2="B 2"
	Key3=$(Get-Date)
	
	PS C:\> $ini = .\Import-ini.ps1 .\test.ini
	PS C:\> $ini
	Name                           Value
	----                           -----
	SectionA                       {Key2, Key1}
	SectionB                       {Key3, Key2, Key1}
	PS C:\> $ini.SectionB.Key3
	Saturday, January 14, 2012 11:33:06 PM

.LINK
	http://povvershell.blogspot.com/

.NOTES
	mailto :	karaszmiklos@gmail.com
	version:	2012-01-14
	base idea:	http://www.vistax64.com/powershell/79160-powershell-ini-files.html
#>

[CmdletBinding()]
param (
	# Name of the iniFile to be parsed.
	[Parameter(Mandatory=$true,ValueFromPipeline=$true)]
	[ValidateScript({ Test-Path -PathType:Leaf -Path:$_ })]
	[string] $IniFile
)

begin
{
	Write-Verbose "$($MyInvocation.Line)"
	$iniObj = @{}
}

process
{
	switch -regex -File $IniFile {
		"^\[(.+)\]$" {
			$section = $matches[1]
			$iniObj[$section] = @{}
		}
		"(?<key>^[^\#\;\=]*)[=?](?<value>.+)" {
			$key	= $matches.key.Trim()
			$value	= $matches.value.Trim()
			if ( ($value -like '$(*)') -or ($value -like '"*"') ) {
				$value = Invoke-Expression $value
			} 
			if ( $section ) {
				$iniObj[$section][$key] = $value
			} else {
				$iniObj[$key] = $value
			}
		}
	}
}

end
{
	return $iniObj
}
