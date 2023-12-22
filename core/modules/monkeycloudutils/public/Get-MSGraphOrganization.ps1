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

Function Get-MSGraphOrganization{
    <#
        .SYNOPSIS
        Get the properties and relationships of the currently authenticated organization

        .DESCRIPTION
        Get the properties and relationships of the currently authenticated organization

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MSGraphOrganization
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Tenant Id')]
        [String]$TenantId,

        [Parameter(Mandatory = $true, HelpMessage = 'Authentication object')]
        [object]$AuthObject
     )
     try{
        if($AuthObject.resource -like "*graph.microsoft*"){
            if($PSBoundParameters.ContainsKey('TenantId') -and $PSBoundParameters['TenantId'] -ne [System.Guid]::Empty){
                $uri = ("{0}/v1.0/organization/{1}" -f $AuthObject.resource, $PSBoundParameters['TenantId'])
            }
            else{
                $uri = ("{0}/v1.0/organization" -f $AuthObject.resource)
            }
            #Create authorization header
            $Authorization = $AuthObject.CreateAuthorizationHeader()
            $Tenants = Invoke-WebRequest $uri -Method Get -Headers @{Authorization=$Authorization};
            $Tenants = (ConvertFrom-Json $Tenants.Content).value;
            if($Tenants){
                foreach($organization in @($Tenants)){
                    #Add objectId legacy property
                    $organization | Add-Member -type NoteProperty -name objectId -value $organization.id -Force
                    #Add tenantName legacy property
                    $organization | Add-Member -type NoteProperty -name TenantName -value $organization.displayName -Force
                }
                return $Tenants
            }
        }
        else{
            Write-Warning -Message ($Script:messages.InvalidAudienceError -f "Tenant information")
            Write-Warning "Unable to get Tenant information. Invalid Audience"
        }
    }
    catch{
        Write-Warning -Message $_.Exception
        Write-Debug -Message $_
        try{
            if($null -ne $_.PsObject.Properties.Item('error') -and $null -ne $_.error.Psobject.Properties.Item('message')){
                Write-Verbose -Message $_.error.code
                Write-Verbose -Message $_.error.message
            }
        }
        catch{
            Write-Warning "Unable to get Tenant information"
        }
    }
}
