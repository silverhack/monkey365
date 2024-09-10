Function Remove-TabAndNewLine {
    [CmdletBinding()]
    [OutputType([System.String])]
	Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="Compliance Object")]
        [AllowNull()]
        [Object]$InputObject
    )
    Process{
        try{
            ($InputObject -replace "[`r`n`t]+", '').TrimEnd([System.Environment]::NewLine.ToCharArray());
        }
        Catch{
            Write-Error $_
        }
    }
}