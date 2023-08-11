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

Function Get-MonkeyAzAppService {
    <#
        .SYNOPSIS
		Get DomainInfo

        .DESCRIPTION
		Get DomainInfo

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzAppService
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True)]
        [Object]$App,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2021-02-01"
    )
    Process{
        try{
            $p = @{
		        Id = $App.Id;
                ApiVersion = $APIVersion;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
	        }
	        $app_service = Get-MonkeyAzObjectById @p
            if($app_service){
                $app_service = New-MonkeyAppServiceObject -App $app_service
                if($app_service){
                    #Get app configuration
                    $p = @{
		                App = $app_service;
                        ApiVersion = $APIVersion;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $app_conf = Get-MonkeyAzAppServiceConfiguration @p
                    if($app_conf){
                        #Add to object
                        $app_service.appConfig = $app_conf;
                    }
                    #Get app auth settings
                    $p = @{
		                App = $app_service;
                        ApiVersion = $APIVersion;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $app_auth = Get-MonkeyAzAppServiceAuthSetting @p
                    if($app_auth){
                        #Add to object
                        $app_service.authSettings = $app_auth;
                    }
                    #Get app backup
                    $p = @{
		                App = $app_service;
                        ApiVersion = $APIVersion;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $app_backup = Get-MonkeyAzAppServiceBackup @p
                    if($app_backup){
                        #Add to object
                        $app_service.recovery.backup.count = @($app_backup).Count;
                        $app_service.recovery.backup.rawData = $app_backup;
                    }
                    #Get app snapshot
                    $p = @{
		                App = $app_service;
                        ApiVersion = $APIVersion;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $app_snapshot = Get-MonkeyAzAppServiceSnapShot @p
                    if($app_snapshot){
                        #Add to object
                        $app_service.recovery.snapShot.count = @($app_snapshot).Count;
                        $app_service.recovery.snapShot.rawData = $app_snapshot;
                    }
                    #Get diagnostic settings
                    $p = @{
		                Id = $app_service.Id;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                        InformationAction = $O365Object.InformationAction;
	                }
	                $diag = Get-MonkeyAzDiagnosticSettingsById @p
                    if($diag){
                        #Add to object
                        $app_service.diagnosticSettings.enabled = $true;
                        $app_service.diagnosticSettings.name = $diag.name;
                        $app_service.diagnosticSettings.id = $diag.id;
                        $app_service.diagnosticSettings.properties = $diag.properties;
                        $app_service.diagnosticSettings.rawData = $diag;
                    }
                    #Check if identity is present
                    if($null -ne $app_service.rawObject.PsObject.Properties.Item('identity')){
                        $app_service.identity.enabled = $true;
                        $app_service.identity.type = $app_service.rawObject.identity.type;
                        $app_service.identity.rawData = $app_service.rawObject.identity;
                    }
                }
                return $app_service
            }
        }
        catch{
            Write-Verbose $_
        }
    }
}