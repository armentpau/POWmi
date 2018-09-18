function Enter-POWmiSession
{
	[CmdletBinding()]
	param
	(
		$ComputerName,
		[pscredential]$Credential
	)
	
	Import-Module psreadline
	$quitflag = $false
	do
	{
		$input = PSConsoleHostReadLine
		switch ($input)
		{
			"Quit"{
				$quitflag = $true
			}
			default
			{
				Invoke-Expression $input
			}
		}
	}
	while ($quitFlag -eq $false)
}