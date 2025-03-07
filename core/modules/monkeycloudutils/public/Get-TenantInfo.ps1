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

Function Get-TenantInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-TenantInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory = $false, HelpMessage = 'Tenant name')]
        [String]$Tenant,

        [Parameter(Mandatory = $true, HelpMessage = 'Authentication object')]
        [object]$AuthObject
     )
     try{
        if($AuthObject.resource -like "*graph.windows*"){
            if([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq [System.Guid]::Empty){
                $Tenant = "/myOrganization"
            }
            $Authorization = $AuthObject.CreateAuthorizationHeader()
            $uri = ("{0}/{1}/tenantDetails?api-version=1.6" -f $AuthObject.resource, $Tenant)
            $Tenants = Invoke-WebRequest $uri -Method Get -Headers @{Authorization=$Authorization};
            return (ConvertFrom-Json $Tenants.Content).value;
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
            if($null -ne $_.PsObject.Properties.Item('ErrorDetails') -and $null -ne $_.ErrorDetails.Psobject.Properties.Item('Message')){
                $detailed_message = ConvertFrom-Json $_.ErrorDetails.Message
                Write-Verbose -Message $detailed_message.'odata.error'.code
                Write-Verbose -Message $detailed_message.'odata.error'.message.value
            }
        }
        catch{
            Write-Warning "Unable to get Tenant information"
        }
    }
}


