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

Function Get-CloudObject{
    <#
        .SYNOPSIS
        Get cloud object
        .DESCRIPTION
        Get cloud object
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Remediation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$false, HelpMessage="Tenant Id")]
        [String]$TenantId,

        [parameter(Mandatory=$false, HelpMessage="Tenant Name")]
        [String]$TenantName,

        [parameter(Mandatory=$false, HelpMessage="Subscription Id")]
        [String]$SubscriptionId,

        [parameter(Mandatory=$false, HelpMessage="Subscription Name")]
        [String]$SubscriptionName,

        [parameter(Mandatory=$true, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraId","Microsoft365")]
        [String]$Provider = "Azure"
    )
    Process{
        Try{
            $cloudObject = New-OcsfCloudObject
            if($null -ne $cloudObject){
                if($Provider.ToLower() -eq "azure"){
                    $cloudObject.Account.Name = $PSBoundParameters['SubscriptionName']
                    $cloudObject.Account.Id = $PSBoundParameters['SubscriptionId']
                    $cloudObject.Account.Type = [Ocsf.Objects.Entity.AccountType]::AzureADAccount
                    $cloudObject.Account.TypeId = ([Ocsf.Objects.Entity.AccountType]::AzureADAccount.value__).ToString();
                    $cloudObject.Organization.Name = $PSBoundParameters['TenantName']
                    $cloudObject.Organization.Id = $PSBoundParameters['TenantId']
                    $cloudObject.Provider = $Provider
                    $cloudObject.Region = 'global'
                }
                else{
                    $cloudObject.Account.Name = $PSBoundParameters['TenantName']
                    $cloudObject.Account.Id = $PSBoundParameters['TenantId']
                    $cloudObject.Account.Type = [Ocsf.Objects.Entity.AccountType]::AzureADAccount
                    $cloudObject.Account.TypeId = ([Ocsf.Objects.Entity.AccountType]::AzureADAccount.value__).ToString();
                    $cloudObject.Organization.Name = $PSBoundParameters['TenantName']
                    $cloudObject.Organization.Id = $PSBoundParameters['TenantId']
                    $cloudObject.Provider = $Provider
                    $cloudObject.Region = 'global'                    
                }
                #return object
                return $cloudObject
            }
        }
        Catch{
            Write-Error $_
        }
    }
}