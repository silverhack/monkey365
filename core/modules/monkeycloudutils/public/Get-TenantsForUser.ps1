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

Function Get-TenantsForUser{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-TenantsForUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [object]$AuthObject,

        [Parameter(Mandatory=$false, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [Parameter(Mandatory=$false, HelpMessage="Tenant Id")]
        [String]$TenantId
     )
     try{
        [System.Uri]$audience = $Endpoint
    }
    catch{
        Write-Warning $_
        $audience = $null
    }
    if($null -ne $audience){
        try{
            if(Test-IsValidAudience -token $AuthObject.AccessToken -audience $audience.Authority){
                $Authorization = $AuthObject.CreateAuthorizationHeader()
                # Set HTTP request headers to include Authorization header
                $requestHeader = @{
                    "x-ms-version" = "2014-10-01";
                    "Authorization" = $Authorization
                }
                $uri = "{0}/tenants?api-version=2020-01-01" -f $Endpoint
                $Tenants = Invoke-RestMethod -Uri $uri -Method Get -Headers $requestHeader -ContentType 'application/json'
                if(![string]::IsNullOrEmpty($TenantId) -and $TenantId -ne [System.Guid]::Empty.Guid){
                    Write-Information -MessageData ("Getting information for TenantId {0}"-f $TenantId)
                    $Tenants = $Tenants.Value | Where-Object {$_.tenantid -eq $TenantID} | Select-Object *
                    return $Tenants
                }
                else{
                    return $Tenants.Value
                }
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
            if($null -ne $detailed_message){
                Write-Verbose -Message $detailed_message.error.code
                Write-Verbose -Message $detailed_message.error.message
                Write-Debug -Message $_
            }
        }
    }
}
