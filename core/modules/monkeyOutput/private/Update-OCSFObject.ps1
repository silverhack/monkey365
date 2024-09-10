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

Function Update-OCSFObject{
    <#
        .SYNOPSIS
        Update OCSF object with location, resourceName, resource Type, Id, etc..
        .DESCRIPTION
        Update OCSF object with location, resourceName, resource Type, Id, etc..
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-OCSFObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$True, HelpMessage="InputObject")]
        [Object]$Data,

        [parameter(Mandatory=$True, HelpMessage="Base finding")]
        [Object]$Finding,

        [parameter(Mandatory=$True, HelpMessage="Object to update")]
        [Object]$Object
    )
    Try{
        If($Finding.metadata.Provider.ToLower() -eq "azure"){
            #Get Labels
            $Object.Resources.Labels = Get-ObjectTag -InputObject $Data
            #Get region
            $Object.Resources.Region = Get-ObjectLocation -InputObject $Data
            #Get Name
            $Object.Resources.Name = Get-ObjectName -InputObject $Data
            #Get Type
            $Object.Resources.Type = Get-ObjectResourceType -InputObject $Data
            #Get Id
            $Object.Resources.Id = Get-ObjectResourceId -InputObject $Data
            #Check if region is null
            If($null -eq $Object.Resources.Region){
                $Object.Resources.Region = "Global"
            }
        }
        Else{
            #Get Labels
            $Object.Resources.Labels = Get-ObjectTag -InputObject $Data
            #Get region
            $Object.Resources.Region = Get-ObjectLocation -InputObject $Data
            #Get Name
            $resourceName = $Finding.output.text.properties.resourceName
            If($resourceName){
                $Object.Resources.Name = $Data | Get-PropertyFromPsObject -ResourceName $resourceName
            }
            Else{
                $Object.Resources.Name = Get-ObjectName -InputObject $Data
            }
            #Get Type
            $resourceType = $Finding.output.text.properties.resourceType
            If($resourceType){
                $Object.Resources.Type = $Data | Get-PropertyFromPsObject -ResourceName $resourceType
            }
            Else{
                $Object.Resources.Type = Get-ObjectResourceType -InputObject $Data
            }
            #Get Id
            $resourceId = $Finding.output.text.properties.resourceId
            If($resourceId){
                $Object.Resources.Id = $Data | Get-PropertyFromPsObject -ResourceName $resourceId
            }
            Else{
                $Object.Resources.Id = Get-ObjectResourceId -InputObject $Data
            }
            #Check if region is null
            If($null -eq $Object.Resources.Region){
                $Object.Resources.Region = "Global"
            }
        }
        #Return updated object
        return $Object
    }
    Catch{
        Write-Error $_
    }
}
