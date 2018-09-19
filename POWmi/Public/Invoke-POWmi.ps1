function ConvertFrom-Base64ToObject
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory = $true,
				   Position = 0)]
		[ValidateNotNullOrEmpty()]
		[Alias('string')]
		[string]$inputString
	)
	
	return [management.automation.psserializer]::Deserialize([System.Text.Encoding]::UTF8.GetString([System.Convert]::FromBase64String($inputString)))
}
$scriptblock = {
	Get-ChildItem c:\
}
$computername = "cli1"
$credential = Get-Credential
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
		#$pipeSecurity = New-Object System.IO.Pipes.PipeSecurity
		#$accessRule = New-Object System.IO.Pipes.PipeAccessRule("Anonymous", "ReadWrite", "Allow")
		#$pipeSecurity.AddAccessRule($accessRule)
		$namedPipe = new-object System.IO.Pipes.NamedPipeServerStream "<pipename>", "Out"
		#,100,"Byte","Asynchronous",1024,1024,$pipeSecurity
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
	
	#$expression = "Invoke-wmimethod -computername '$($ComputerName)' -class win32_process -name create -argumentlist 'powershell.exe -encodedcommand $encodedScriptBlock'"
	Invoke-wmimethod -computername "$($ComputerName)" -class win32_process -name create -argumentlist "powershell.exe -encodedcommand $($encodedScriptBlock)" -credential $credential | Out-Null
	#Invoke-Expression $expression | Out-Null
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
Invoke-POWmi -Credential $credential -ScriptBlock $scriptblock -ComputerName $computername