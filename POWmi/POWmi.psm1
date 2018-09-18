<#	
	===========================================================================
	 Created with: 	SAPIEN Technologies, Inc., PowerShell Studio 2018 v5.5.154
	 Created on:   	9/18/2018 3:18 PM
	 Created by:   	949237a
	 Organization: 	
	 Filename:     	POWmi.psm1
	-------------------------------------------------------------------------
	 Module Name: POWmi
	===========================================================================
#>

$scriptPath = Split-Path $MyInvocation.MyCommand.Path
#region Load Private Functions
try
{
	Get-ChildItem "$scriptPath\Private" -filter *.ps1 | Select-Object -ExpandProperty FullName | ForEach-Object{
		. $_
	}
}
catch
{
	Write-Warning "There was an error loading $($function) and the error is $($psitem.tostring())"
	exit
}

#region Load Public Functions
try
{
	Get-ChildItem "$scriptPath\Public" -filter *.ps1 | Select-Object -ExpandProperty FullName | ForEach-Object{
		. $_
	}
}
catch
{
	Write-Warning "There was an error loading $($function) and the error is $($psitem.tostring())"
	exit
}
