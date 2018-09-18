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