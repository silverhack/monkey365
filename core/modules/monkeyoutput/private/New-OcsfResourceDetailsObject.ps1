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

Function New-OcsfResourceDetailsObject{
    <#
        .SYNOPSIS
        Get OCSF resource details object
        .DESCRIPTION
        Get OCSF resource details object
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-OcsfResourceDetailsObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [OutputType([System.Management.Automation.PSCustomObject])]
	param(
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Finding")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Resource data")]
        [Object]$Data,

        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraId","Microsoft365")]
        [String]$Provider = "Azure"
    )
    Begin{
        #Set properties
        $properties = @(
            'cloudPartition','region',
            'data','group',
            'labels','name',
            'type','id'
        )
        #Set resource Array
        $resourceArray = [System.Collections.Generic.List[System.Management.Automation.PsObject]]::new()
    }
    Process{
        Try{
            $resourceDetails = [Ocsf.Objects.ResourceDetails]::new() | Select-Object $properties
            #Get group
            $group = New-OcsfGroupObject
            $resourceDetails.Group = $group
            $resourceDetails.CloudPartition = [Ocsf.Objects.Entity.AccountType]::AzureADAccount
            $resourceDetails.Group.Name = $InputObject | Select-Object -ExpandProperty serviceType -ErrorAction Ignore
            #Check if Data is present
            If($PSBoundParameters.ContainsKey('Data') -and $PSBoundParameters['Data']){
                #Get Labels
                $resourceDetails.Labels = $PSBoundParameters['Data'] | Get-ObjectTag
                #Get region
                $resourceDetails.Region = $PSBoundParameters['Data'] | Get-ObjectLocation
                #Get Name
                $resourceDetails.Name = $PSBoundParameters['Data'] | Get-PropertyFromPsObject -Property "name"
                #Get Type
                $resourceDetails.Type = $PSBoundParameters['Data'] | Get-ObjectResourceType
                #Get Id
                $resourceDetails.Id = $PSBoundParameters['Data'] | Get-ObjectResourceId
                #Check for fallback properties
                #Check if region is null
                If($null -eq $resourceDetails.Region){
                    $resourceDetails.Region = "Global"
                }
                #Check if id is null
                If($null -eq $resourceDetails.Id){
                    #Get property from finding
                    Try{
                        $resourceId = $InputObject.output.text.properties.resourceId
                        If($null -ne $resourceId){
                            $resourceDetails.Id = $PSBoundParameters['Data'] | Get-PropertyFromPsObject -Property $resourceId
                        }
                    }
                    Catch{
                        Write-Warning ("Unable to get property Id from {0}" -f $InputObject.displayName)
                        Write-Error $_.Exception.Message
                    }
                }
                #Check if type is null
                If($null -eq $resourceDetails.Type){
                    #Get property from finding
                    Try{
                        $resourceType = $InputObject.output.text.properties.resourceType
                        IF($null -ne $resourceType){
                            $resourceDetails.Type = $resourceType
                        }
                    }
                    Catch{
                        Write-Warning ("Unable to get property Type from {0}" -f $InputObject.displayName)
                        Write-Error $_.Exception.Message
                    }
                }
                #Check if name is null
                If($null -eq $resourceDetails.Name){
                    #Get property from finding
                    Try{
                        $resourceName = $Finding.output.text.properties.resourceName
                        If($null -ne $resourceName){
                            $resourceDetails.Name = $PSBoundParameters['Data'] | Get-PropertyFromPsObject -Property $resourceName
                        }
                    }
                    Catch{
                        Write-Warning ("Unable to get property Name from {0}" -f $InputObject.displayName)
                        Write-Error $_.Exception.Message
                    }
                }
                #Set Raw Data object
                $rawData = [PsCustomObject]@{
                    details = [System.String]::Empty;
                    metadata = $PSBoundParameters['Data']
                }
                #Add to array
                [void]$resourceArray.Add($rawData);
                #Add to object
                $resourceDetails.Data = $resourceArray;
            }
            Else{
                #Add empty array Data object
                $rawData = [PsCustomObject]@{
                    details = [System.String]::Empty;
                    metadata = @{};
                }
                #Add to array
                [void]$resourceArray.Add($rawData);
                #Add to object
                $resourceDetails.Data = $resourceArray;
            }
            #return Object
            return $resourceDetails
        }
        Catch{
            Write-Error $_
        }
    }
}
