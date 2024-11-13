# Monkey365 - the PowerShell Cloud Security Tool for Azure and Microsoft 365 (copyright 2022) by Juan Garrido
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

Function Invoke-MonkeyOutput{
    <#
        .SYNOPSIS
        Export data to CSV or JSON file
        .DESCRIPTION
        Export data to CSV or JSON file
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyOutput
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$True, HelpMessage="Finding")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Product Name")]
        [String]$ProductName,

        [parameter(Mandatory=$false, HelpMessage="Product Version")]
        [String]$ProductVersion,

        [parameter(Mandatory=$false, HelpMessage="Product Vendor Name")]
        [String]$ProductVendorName,

        [parameter(Mandatory=$True, HelpMessage="Tenant Id")]
        [String]$TenantId,

        [parameter(Mandatory=$false, HelpMessage="Tenant Name")]
        [String]$TenantName,

        [parameter(Mandatory=$false, HelpMessage="Subscription Id")]
        [String]$SubscriptionId,

        [parameter(Mandatory=$false, HelpMessage="Subscription Name")]
        [String]$SubscriptionName,

        [parameter(Mandatory=$True, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraId","Microsoft365")]
        [String]$Provider,

        [parameter(Mandatory=$false, HelpMessage="Finding object")]
        [ValidateSet("Security","Vulnerability","Compliance","Detection","Incident")]
        [String]$FindingType,

        [parameter(Mandatory= $false, HelpMessage= "Export data to CSV,JSON, CLIXML and CONSOLE")]
        [ValidateSet("CSV","JSON","CLIXML")]
        [String]$ExportTo = "JSON",

        [Parameter(Mandatory= $True, HelpMessage = 'Please specify folder to export results')]
        [System.IO.DirectoryInfo]$OutDir,

        [parameter(Mandatory=$false, HelpMessage="Skip findings with level good")]
        [Switch]$SkipGood
    )
    Begin{
        $allObjects = [System.Collections.Generic.List[System.Object]]::new()
    }
    Process{
        Try{
            If($PSBoundParameters.ContainsKey('SkipGood') -and $PSBoundParameters['SkipGood'].IsPresent){
                $InputObject = @($InputObject).Where({$_.level -ne 'good'})
            }
            ForEach($finding in @($InputObject)){
                Switch($ExportTo.ToLower()){
                    'json'{
                        #Get Metadata
                        $Metadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "ConvertTo-OCSFObject")
                        #Set new dict
                        $newPsboundParams = [ordered]@{}
                        $param = $Metadata.Parameters.Keys
                        foreach($p in $param.GetEnumerator()){
                            If($PSBoundParameters.ContainsKey($p)){
                                If($p -eq "InputObject"){
                                    $newPsboundParams.Add("InputObject",$finding)
                                }
                                Else{
                                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                                }
                            }
                        }
                        #ConvertTo-AzureOCSFObject @newPsboundParams
                        $newObj = ConvertTo-OCSFObject @newPsboundParams
                        If($newObj){
                            If ($newObj -is [System.Collections.IEnumerable] -and $newObj -isnot [string]){
                                [void]$allObjects.AddRange($newObj);
                            }
                            ElseIf ($newObj.GetType() -eq [System.Management.Automation.PSCustomObject] -or $newObj.GetType() -eq [System.Management.Automation.PSObject]) {
                                [void]$allObjects.Add($newObj);
                            }
                        }
                    }
                    { @("csv", "clixml") -contains $_ }{
                        #Get Metadata
                        $Metadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "ConvertTo-GenericPsObject")
                        #Set new dict
                        $newPsboundParams = [ordered]@{}
                        $param = $Metadata.Parameters.Keys
                        foreach($p in $param.GetEnumerator()){
                            If($PSBoundParameters.ContainsKey($p)){
                                If($p -eq "InputObject"){
                                    $newPsboundParams.Add("InputObject",$finding)
                                }
                                Else{
                                    $newPsboundParams.Add($p,$PSBoundParameters[$p])
                                }
                            }
                        }
                        $newObj = ConvertTo-GenericPsObject @newPsboundParams
                        If($newObj){
                            If ($newObj -is [System.Collections.IEnumerable] -and $newObj -isnot [string]){
                                [void]$allObjects.AddRange($newObj);
                            }
                            ElseIf ($newObj.GetType() -eq [System.Management.Automation.PSCustomObject] -or $newObj.GetType() -eq [System.Management.Automation.PSObject]) {
                                [void]$allObjects.Add($newObj);
                            }
                        }
                    }
                }
            }
        }
        Catch{
            Write-Error $_
        }
    }
    End{
        If($null -ne $allObjects -and $allObjects.Count -gt 0){
            Switch($ExportTo.ToLower()){
                'json'{
                    $jsonFile = ("{0}/monkey365{1}{2}.json" -f $OutDir, $PSBoundParameters['TenantId'].Replace('-',''), ([System.DateTime]::UtcNow).ToString("yyyyMMddHHmmss"))
                    $convertedObjects = $allObjects | Convert-ObjectToCamelCaseObject -psName "MonkeyFindingObject" | ConvertTo-Json -Depth 100 | Format-Json
                    If($convertedObjects){
                        $convertedObjects | Out-File -FilePath $jsonFile
                    }

                }
                'csv'{
                    $csvFile = ("{0}/monkey365{1}{2}.csv" -f $OutDir, $PSBoundParameters['TenantId'].Replace('-',''), ([System.DateTime]::UtcNow).ToString("yyyyMMddHHmmss"))
                    $allObjects | Export-Csv -NoTypeInformation -Path $csvFile
                }
                'clixml'{
                    $xmlFile = ("{0}/monkey365{1}{2}.xml" -f $OutDir, $PSBoundParameters['TenantId'].Replace('-',''), ([System.DateTime]::UtcNow).ToString("yyyyMMddHHmmss"))
                    $allObjects | Export-DataToCliXml -Path $xmlFile
                }
            }
        }
    }
}
