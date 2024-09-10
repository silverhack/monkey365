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

Function ConvertTo-OCSFObject{
    <#
        .SYNOPSIS
        Convert data from Azure findings to OCSF output
        .DESCRIPTION
        Convert data from Azure findings to OCSF output
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-AzureOCSFObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Finding")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Product Name")]
        [String]$ProductName,

        [parameter(Mandatory=$false, HelpMessage="Product Version")]
        [String]$ProductVersion,

        [parameter(Mandatory=$false, HelpMessage="Product Vendor Name")]
        [String]$ProductVendorName,

        [parameter(Mandatory=$false, HelpMessage="Tenant Id")]
        [String]$TenantId,

        [parameter(Mandatory=$false, HelpMessage="Tenant Name")]
        [String]$TenantName,

        [parameter(Mandatory=$false, HelpMessage="Subscription Id")]
        [String]$SubscriptionId,

        [parameter(Mandatory=$false, HelpMessage="Subscription Name")]
        [String]$SubscriptionName,

        [parameter(Mandatory=$True, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraId","Microsoft365")]
        [String]$Provider = "Azure",

        [parameter(Mandatory=$false, HelpMessage="Finding object")]
        [ValidateSet("Security","Vulnerability","Compliance","Detection","Incident")]
        [String]$FindingType,

        [parameter(Mandatory=$false, HelpMessage="Skip findings with level good")]
        [Switch]$SkipGood
    )
    Begin{
        #Get Metadata
        $Metadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-OcsfDetectionFindingObject")
        #Set new dict
        $newPsboundParams = [ordered]@{}
        $param = $Metadata.Parameters.Keys
        foreach($p in $param.GetEnumerator()){
            If($p -eq "InputObject"){continue}
            If($PSBoundParameters.ContainsKey($p)){
                $newPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
    }
    Process{
        Try{
            Foreach($finding in @($InputObject)){
                If($finding.statusCode.Trim().ToLower() -eq 'pass' -or $finding.output.text.onlyStatus){
                    $newFinding = $finding | Get-OcsfDetectionFindingObject @newPsboundParams
                    If($null -ne $newFinding){
                        $newFinding.StatusDetail = $finding.output.text.status.defaultMessage
                        #$newFinding | Convert-ObjectToCamelCaseObject -psName "MonkeyFindingObject" | ConvertTo-Json -Depth 100 | Format-Json
                        $newFinding
                    }
                }
                Else{
                    Foreach($obj in @($finding.output.text.out)){
                        $newFinding = $finding | Get-OcsfDetectionFindingObject @newPsboundParams
                        If($null -ne $newFinding){
                            #Get Status detail
                            $status = $finding.output.text.status
                            $newFinding.StatusDetail = Get-FindingLegend -InputObject $obj -StatusObject $status
                            #Update resource type, resource Name, Id, etc..
                            $p = @{
                                Data = $obj;
                                Finding = $finding;
                                Object = $newFinding;
                            }
                            $newFinding = Update-OCSFObject @p
                            If($null -ne $newFinding){
                                $newFinding
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
}
