function Enter-POWmiSession
{
	[CmdletBinding()]
	param
	(
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		$PipeName = (New-Guid).Guid.ToString(),
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = 'localhost',
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential
	)
	
	Import-Module psreadline
	$quitflag = $false
	do
	{
		$input = PSConsoleHostReadLine
		switch ($input)
		{
			{($_ -eq "Quit") -or ($_ -eq "Exit-POWmisession") -or($_ -eq "Exit") }{
				$quitflag = $true
			}
			default
			{
				
			}
		}
	}
	while ($quitFlag -eq $false)
}