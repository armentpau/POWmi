function Invoke-POWmi
{
	[CmdletBinding(DefaultParameterSetName = 'Credential')]
	param
	(
		[ValidateNotNullOrEmpty()]
		[Alias('Name')]
		$PipeName = ([guid]::NewGuid()).Guid.ToString(),
		[Parameter(Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ScriptBlock,
		[Parameter(Mandatory = $false)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName = 'localhost',
		[Parameter(ParameterSetName = 'Credential',
				 Mandatory = $true)]
		[ValidateNotNullOrEmpty()]
		[pscredential]$Credential,
		[ValidateRange(1000, 900000)]
		[int32]$Timeout = 120000,
		[Parameter(ParameterSetName = 'ByPassCreds')]
		[switch]$BypassCreds
	)
	
	$scriptBlockPreEncoded = [scriptblock]{
		#region support functions
		function ConvertTo-CliXml
		{
			param (
				[Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
				[ValidateNotNullOrEmpty()]
				[PSObject[]]$InputObject
			)
			return [management.automation.psserializer]::Serialize($InputObject)
		}
		
		function ConvertTo-Base64StringFromObject
		{
			[CmdletBinding()]
			param
			(
				[Parameter(Mandatory = $true,
						 ValueFromPipeline = $true,
						 Position = 0)]
				[ValidateNotNullOrEmpty()]
				[object]$inputobject
			)
			
			$holdingXml = ConvertTo-CliXml -InputObject $inputobject
			$preConversion_bytes = [System.Text.Encoding]::UTF8.GetBytes($holdingXml)
			$preconversion_64 = [System.Convert]::ToBase64String($preConversion_bytes)
			$memoryStream = New-Object System.IO.MemoryStream
			$compressionStream = New-Object System.IO.Compression.GZipStream($memoryStream, [System.io.compression.compressionmode]::Compress)
			$streamWriter = New-Object System.IO.streamwriter($compressionStream)
			$streamWriter.write($preconversion_64)
			$streamWriter.close()
			$compressedData = [System.convert]::ToBase64String($memoryStream.ToArray())
			return $compressedData
		}
		#endregion
		
		$namedPipe = new-object System.IO.Pipes.NamedPipeServerStream "<pipename>", "Out"
		$namedPipe.WaitForConnection()
		$streamWriter = New-Object System.IO.StreamWriter $namedPipe
		$streamWriter.AutoFlush = $true
		$TempResultPreConversion = &{ <scriptBlock> }
		$results = ConvertTo-Base64StringFromObject -inputObject $TempResultPreConversion
		$streamWriter.WriteLine("$($results)")
		$streamWriter.dispose()
		$namedPipe.dispose()
		
	}
	
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<pipename>", $PipeName
	$scriptBlockPreEncoded = $scriptBlockPreEncoded -replace "<scriptBlock>", $ScriptBlock
	$byteCommand = [System.Text.encoding]::UTF8.GetBytes($scriptBlockPreEncoded)
	$encodedScriptBlock = [convert]::ToBase64string($byteCommand)
	
	if ($($env:computername) -eq $ComputerName -or $BypassCreds)
	{
		$holderData = Invoke-wmimethod -computername "$($ComputerName)" -class win32_process -name create -argumentlist "powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string('$($encodedScriptBlock)')))))"
	}
	else
	{
		$holderData = Invoke-wmimethod -computername "$($ComputerName)" -class win32_process -name create -argumentlist "powershell.exe (invoke-command ([scriptblock]::Create([system.text.encoding]::UTF8.GetString([System.convert]::FromBase64string(`"$($encodedScriptBlock))`"))))" -Credential $Credential
	}
	
	$namedPipe = New-Object System.IO.Pipes.NamedPipeClientStream $ComputerName, "$($PipeName)", "In"
	$namedPipe.connect($timeout)
	$streamReader = New-Object System.IO.StreamReader $namedPipe
	
	while ($null -ne ($data = $streamReader.ReadLine()))
	{
		$tempData = $data
	}
	
	$streamReader.dispose()
	$namedPipe.dispose()
	
	ConvertFrom-Base64ToObject -inputString $tempData
}
#https://github.com/threatexpress/invoke-pipeshell/blob/master/Invoke-PipeShell.ps1