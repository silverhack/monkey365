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

Function ConvertTo-GenericPsObject{
    <#
        .SYNOPSIS
        Convert finding object to PsObject
        .DESCRIPTION
        Convert finding object to PsObject
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: ConvertTo-GenericPsObject
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
    Process{
        Try{
            Foreach($finding in @($InputObject)){
                If($Provider.ToLower() -eq 'azure'){
                    If($finding.statusCode.Trim().ToLower() -eq 'pass' -or $finding.output.text.onlyStatus){
                        $newFinding = $finding | New-AzureOutputPsObject
                        If($null -ne $newFinding){
                            $newFinding.status = $finding.output.text.status.defaultMessage
                            #Set TenantId
                            $newFinding.tenantId = $PSBoundParameters['TenantId']
                            #Set TenantName
                            $newFinding.tenantName = $PSBoundParameters['TenantName']
                            #Set SubscriptionId
                            $newFinding.subscriptionId = $PSBoundParameters['SubscriptionId']
                            #Set SubscriptionName
                            $newFinding.subscriptionName = $PSBoundParameters['SubscriptionName']
                            #Set unique id
                            $newFinding.uniqueId = ("Monkey365-{0}-{1}-{2}" -f $finding.idSuffix.Replace('_','-'), $PSBoundParameters['TenantId'].Replace('-',''), (New-RandomId));
                            #Set provider
                            $newFinding.provider = $PSBoundParameters['Provider']
                            #Set Version
                            $newFinding.monkey365Version = $PSBoundParameters['ProductVersion']
                            $newFinding
                        }
                    }
                    Else{
                        Foreach($obj in @($finding.affectedResources)){
                            $newFinding = $finding | New-AzureOutputPsObject
                            If($null -ne $newFinding){
                                #Set TenantId
                                $newFinding.tenantId = $PSBoundParameters['TenantId']
                                #Set TenantName
                                $newFinding.tenantName = $PSBoundParameters['TenantName']
                                #Set SubscriptionId
                                $newFinding.subscriptionId = $PSBoundParameters['SubscriptionId']
                                #Set SubscriptionName
                                $newFinding.subscriptionName = $PSBoundParameters['SubscriptionName']
                                #Set unique id
                                $newFinding.uniqueId = ("Monkey365-{0}-{1}-{2}" -f $Finding.idSuffix.Replace('_','-'), $PSBoundParameters['TenantId'].Replace('-',''), (New-RandomId));
                                #Set provider
                                $newFinding.provider = $PSBoundParameters['Provider']
                                #Set Version
                                $newFinding.monkey365Version = $PSBoundParameters['ProductVersion']
                                #Get Status detail
                                $status = $finding.output.text.status
                                $newFinding.status = Get-FindingLegend -InputObject $obj -StatusObject $status
                                #Get Name
                                $newFinding.resourceName = $obj | Get-PropertyFromPsObject -Property "name"
                                #Get Type
                                $newFinding.resourceType = Get-ObjectResourceType -InputObject $obj
                                #Get Id
                                $newFinding.resourceId = Get-ObjectResourceId -InputObject $obj
                                $newFinding
                            }
                        }
                    }
                }
                Else{
                    If($finding.statusCode.Trim().ToLower() -eq 'pass' -or $finding.output.text.onlyStatus){
                        $newFinding = $finding | New-GenericOutputPsObject
                        If($null -ne $newFinding){
                            $newFinding.status = $finding.output.text.status.defaultMessage
                            #Set TenantId
                            $newFinding.tenantId = $PSBoundParameters['TenantId']
                            #Set TenantName
                            $newFinding.tenantName = $PSBoundParameters['TenantName']
                            #Set unique id
                            $newFinding.uniqueId = ("Monkey365-{0}-{1}-{2}" -f $Finding.idSuffix.Replace('_','-'), $PSBoundParameters['TenantId'].Replace('-',''), (New-RandomId));
                            #Set provider
                            $newFinding.provider = $PSBoundParameters['Provider']
                            #Set Version
                            $newFinding.monkey365Version = $PSBoundParameters['ProductVersion']
                            $newFinding
                        }
                    }
                    Else{
                        Foreach($obj in @($finding.output.text.out)){
                            $newFinding = $finding | New-GenericOutputPsObject
                            If($null -ne $newFinding){
                                #Get Status detail
                                $status = $finding.output.text.status
                                $newFinding.status = Get-FindingLegend -InputObject $obj -StatusObject $status
                                #Set TenantId
                                $newFinding.tenantId = $PSBoundParameters['TenantId']
                                #Set TenantName
                                $newFinding.tenantName = $PSBoundParameters['TenantName']
                                #Set unique id
                                $newFinding.uniqueId = ("Monkey365-{0}-{1}-{2}" -f $Finding.idSuffix.Replace('_','-'), $PSBoundParameters['TenantId'].Replace('-',''), (New-RandomId));
                                #Set provider
                                $newFinding.provider = $PSBoundParameters['Provider']
                                #Set Version
                                $newFinding.monkey365Version = $PSBoundParameters['ProductVersion']
                                #Get Name
                                $resourceName = $finding.output.text.properties.resourceName
                                If($resourceName){
                                    $newFinding.resourceName = $obj | Get-PropertyFromPsObject -Property $resourceName
                                }
                                Else{
                                    $newFinding.resourceName = $obj | Get-PropertyFromPsObject -Property "name"
                                }
                                #Get Type
                                $resourceType = $finding.output.text.properties.resourceType
                                If($resourceType){
                                    $newFinding.resourceType = $resourceType
                                }
                                Else{
                                    $newFinding.resourceType = Get-ObjectResourceType -InputObject $obj
                                }
                                #Get Id
                                $resourceId = $finding.output.text.properties.resourceId
                                If($resourceId){
                                    $newFinding.resourceId = $obj | Get-PropertyFromPsObject -Property $resourceId
                                }
                                Else{
                                    $newFinding.resourceId = Get-ObjectResourceId -InputObject $obj
                                }
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

