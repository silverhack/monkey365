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

Function Get-MonkeyAzAPIMInfo {
    <#
        .SYNOPSIS
		Get APIM instance metadata from Azure

        .DESCRIPTION
		Get APIM instance metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAPIMInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2022-09-01-preview"
    )
    Process{
        try{
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $APIM = Get-MonkeyAzObjectById @p
            if($APIM){
                $apimObject = New-MonkeyAPIMObject -InputObject $APIM
                if($apimObject){
                    #Check if read-only users can read secrets
					if($null -eq $apimObject.properties.apiVersionConstraint.minApiVersion){
                        $apimObject.canReadOnlyUsersReadSecrets = $false
                    }
                    elseif ($null -ne $apimObject.Properties.apiVersionConstraint.minApiVersion) {
                        $fixedDate = '2019-12-01'
                        $date =$apimObject.Properties.apiVersionConstraint.minApiVersion
                        if($date -lt $fixedDate){
	                        $apimObject.canReadOnlyUsersReadSecrets = $false
                        }
	                }
	                else {
		                $apimObject.canReadOnlyUsersReadSecrets = $true
	                }
                    #Get named values
                    $apimObject.namedValue = $apimObject | Get-MonkeyAzAPIMNamedValue
                    #Get portal config
                    $apimObject.portalConfig = $apimObject | Get-MonkeyAzAPIMPortalConfig
                    #Get portal users
                    $apimObject.users = $apimObject | Get-MonkeyAzAPIMUsers
                    #Get portal groups
                    $apimObject.groups = $apimObject | Get-MonkeyAzAPIMGroups
                    #Get identities
                    $apimObject.identities = $apimObject | Get-MonkeyAzAPIMIdentity
                    #Get backend
                    $apimObject.backend = $apimObject | Get-MonkeyAzAPIMBackend
                    #Get locks
                    $apimObject.locks = $apimObject | Get-MonkeyAzLockInfo
                    #Check if diagnostic settings
                    If($InputObject.supportsDiagnosticSettings -eq $True){
                        $p = @{
		                    Id = $apimObject.Id;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
	                    }
	                    $diag = Get-MonkeyAzDiagnosticSettingsById @p
                        if($diag){
                            #Add to object
                            $apimObject.diagnosticSettings.enabled = $true;
                            $apimObject.diagnosticSettings.name = $diag.name;
                            $apimObject.diagnosticSettings.id = $diag.id;
                            $apimObject.diagnosticSettings.properties = $diag.properties;
                            $apimObject.diagnosticSettings.rawData = $diag;
                        }
                    }
                    #return object
                    return $apimObject
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
