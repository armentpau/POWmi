function Invoke-POWmi
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
	
	$scriptBlockPreEncoded = [scriptblock]{
		function ConvertTo-PDBase64StringFromObject
		{
			[CmdletBinding()]
			param
			(
				[Parameter(Mandatory = $true,
						   ValueFromPipeline = $true,
						   Position = 0)]
				[ValidateNotNullOrEmpty()]
				[object]$object
			)
			
			return [System.Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes([management.automation.psserializer]::Serialize($object)))
		}
		$namedPipe = new-object System.IO.Pipes.NamedPipeServerStream "<pipename>", "Out"
		$namedPipe.WaitForConnection()
		$streamWriter = New-Object System.IO.StreamWriter $namedPipe
		$streamWriter.AutoFlush = $true
		$pdTempResultPreConversion = (<scriptBlock>)
		$results = ConvertTo-PDBase64StringFromObject -object $pdTempResultPreConversion
		$streamWriter.WriteLine("$($results)")
		$streamWriter.dispose()
		$namedPipe.dispose()
	}
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<pipename>", $PipeName
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<scriptBlock>", $ScriptBlock
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<output>", $ScriptBlockOutputVariable
	$byteCommand = [System.Text.encoding]::Unicode.GetBytes($scriptBlockPreEncoded)
	$encodedScriptBlock = [convert]::ToBase64string($byteCommand)
	
	$holderData = Invoke-wmimethod -computername "$($ComputerName)" -class win32_process -name create -argumentlist "powershell.exe -encodedcommand $($encodedScriptBlock)" -credential $credential
	
	$namedPipe = New-Object System.IO.Pipes.NamedPipeClientStream $ComputerName, "$($PipeName)", "In"
	
	$namedPipe.connect()
	$streamReader = New-Object System.IO.StreamReader $namedPipe
	while ($null -ne ($data = $streamReader.ReadLine()))
	{
		$tempData = $data
	}
	$streamReader.dispose()
	$namedPipe.dispose()
	ConvertFrom-Base64ToObject -inputString $tempData
}