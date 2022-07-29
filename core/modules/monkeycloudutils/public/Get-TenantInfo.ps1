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
        if(Test-IsValidAudience -token $AuthObject.AccessToken -audience "graph.windows.net"){
            if([string]::IsNullOrEmpty($Tenant) -or $Tenant -eq [System.Guid]::Empty){
                $Tenant = "/myOrganization"
            }
            $Authorization = $AuthObject.CreateAuthorizationHeader()
            $uri = ("https://graph.windows.net/{0}/{1}?api-version={2}" -f $Tenant, "tenantDetails", "1.6")
            $Tenants = Invoke-WebRequest $uri -Method Get -Headers @{Authorization=$Authorization};
            return (ConvertFrom-Json $Tenants.Content).value;
        }
        else{
            Write-Warning -Message ($Script:messages.InvalidAudienceError -f "Tenant information")
            Write-Warning "Unable to get Tenant information. Invalid Audience"
        }
    }
    catch{
        if($_.ErrorDetails.Message){
            $detailed_message = ConvertFrom-Json $_.ErrorDetails.Message
        }
        #Write message
        Write-Warning -Message $_.Exception
        Write-Verbose -Message $detailed_message.'odata.error'.code
        Write-Verbose -Message $detailed_message.'odata.error'.message.value
        Write-Debug -Message $_
    }
}
