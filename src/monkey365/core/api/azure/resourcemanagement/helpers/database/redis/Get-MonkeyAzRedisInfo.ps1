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

Function Get-MonkeyAzRedisInfo {
    <#
        .SYNOPSIS
		Get redis instance metadata from Azure

        .DESCRIPTION
		Get redis instance metadata from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRedisInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-08-01-preview"
    )
    Begin{
        $config = @($O365Object.internal_config.resourceManager).Where({$_.Name -eq "DiagnosticSettings"}) | Select-Object -ExpandProperty resource -ErrorAction Ignore
        If($config){
            $diag_settings_api_Version = $config.api_version;
        }
        Else{
            #Fallback
            $diag_settings_api_Version = "2021-05-01-preview"
        }
    }
    Process{
        try{
            $p = @{
			    Id = $InputObject.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
		    }
		    $redisServer = Get-MonkeyAzObjectById @p
            if($redisServer){
                $newRedis = New-MonkeyCacheRedisObject -InputObject $redisServer
                if($newRedis){
                    #Get Access Policy
                    $p = @{
						InputObject = $newRedis;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
                    $newRedis.dataAccess.accessPolicy = Get-MonkeyAzRedisAccessPolicy @p
                    #Get policy assignments
                    $p = @{
						InputObject = $newRedis;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$newRedis.dataAccess.accessPolicyAssignments = Get-MonkeyAzRedisAccessPolicyAssignment @p
                    #######Get patch schedule########
                    $p = @{
						InputObject = $newRedis;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
                    $newRedis.patchSchedule = Get-MonkeyAzRedisPatchSchedule @p
                    #######Get Private endpoint########
                    $p = @{
						InputObject = $newRedis;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$privateEndpoint = Get-MonkeyAzRedisPrivateEndpoint @p
                    If($privateEndpoint){
                        $newRedis.networking.privateEndpointConnections = $privateEndpoint
                    }
                    #######Get Firewall rules########
                    $p = @{
						InputObject = $newRedis;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
					}
					$newRedis.networking.firewall = Get-MonkeyAzRedisFirewallRule @p
                    #Get locks
                    $newRedis.locks = $newRedis | Get-MonkeyAzLockInfo
                    #Get diagnostic settings
                    If($InputObject.supportsDiagnosticSettings -eq $True){
                        $p = @{
		                    Id = $newRedis.Id;
                            ApiVersion = $diag_settings_api_Version;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
	                    }
	                    $diag = Get-MonkeyAzDiagnosticSettingsById @p
                        if($diag){
                            #Add to object
                            $newRedis.diagnosticSettings.enabled = $true;
                            $newRedis.diagnosticSettings.name = $diag.name;
                            $newRedis.diagnosticSettings.id = $diag.id;
                            $newRedis.diagnosticSettings.properties = $diag.properties;
                            $newRedis.diagnosticSettings.rawData = $diag;
                        }
                    }
                    #return object
                    return $newRedis
                }
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}
