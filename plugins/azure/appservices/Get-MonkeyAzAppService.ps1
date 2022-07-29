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


Function Get-MonkeyAzAppService{
    <#
        .SYNOPSIS
		Azure WebApp

        .DESCRIPTION
		Azure WebApp

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

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        $AzureWebApps = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureWebApps"} | Select-Object -ExpandProperty resource
        #Get all sites
        $app_services = $O365Object.all_resources | Where-Object {$_.type -eq 'Microsoft.Web/sites'}
        if(-NOT $app_services){continue}
        #Create array
        $AllMyWebApps = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure app services", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureAPPServices');
        }
        Write-Information @msg
        if($app_services){
            foreach($new_app in $app_services){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $new_app.name, 'app service');
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureAppServicesInfoMessage');
                }
                Write-Information @msg
                #Construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$new_app.id, `
                            $AzureWebApps.api_version)

                #launch request
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $app = Get-MonkeyRMObject @params
                if($app.id){
                    #Get Web app config
                    $URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, $app.id, "config","2016-08-01")
                    $params = @{
                        Authentication = $rm_auth;
                        OwnQuery = $URI;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                    }
                    $appConfiguration = Get-MonkeyRMObject @params
                    #TODO ADD IP_RESTRICTIONS
                    #$appConfiguration.properties.ipSecurityRestrictions -ForegroundColor Yellow
                    if($appConfiguration){
                        $app | Add-Member -type NoteProperty -name configuration -Value $appConfiguration
                    }
                    #Get siteAuth settings
                    try{
                        $PostData = @{"resourceUri"=$app.id} | ConvertTo-Json | ForEach-Object { [System.Text.RegularExpressions.Regex]::Unescape($_) }
                        $URI = ("{0}/api/Websites/GetSiteAuthSettings" -f $O365Object.Environment.WebAppServicePortal)
                        $params = @{
                            Authentication = $rm_auth;
                            OwnQuery = $URI;
                            Environment = $Environment;
                            ContentType = 'application/json';
                            Method = "POST";
                            Data = $PostData;
                        }
                        $appAuthSettings = Get-MonkeyRMObject @params
                        if($appAuthSettings){
                            $app | Add-Member -type NoteProperty -name siteAuthSettings -value $appAuthSettings
                        }
                    }
                    catch{
                        $msg = @{
                            MessageData = $_;
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'error';
                            InformationAction = $InformationAction;
                            Tags = @('AzureAppServicesErrorMessage');
                        }
                        Write-Error @msg
                        #Debug error
                        $msg = @{
                            MessageData = $_.Exception.StackTrace;
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            InformationAction = $InformationAction;
                            Tags = @('AzureAppServicesDebugErrorMessage');
                        }
                        Write-Debug @msg
                    }
                    #Get Backup counts
                    $URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, $app.id, "backups","2016-08-01")
                    $params = @{
                        Authentication = $rm_auth;
                        OwnQuery = $URI;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                    }
                    $appBackup = Get-MonkeyRMObject @params
                    if($appBackup){
                        #Add to object
                        $app | Add-Member -type NoteProperty -name backupCount -value $appBackup.value.Count
                        $app | Add-Member -type NoteProperty -name backupInfo -value $appBackup
                    }
                    else{
                        $app | Add-Member -type NoteProperty -name backupCount -value 0
                        $app | Add-Member -type NoteProperty -name backupInfo -value $null
                    }
                    #Get snapShot counts
                    $URI = ("{0}{1}/{2}?api-version={3}" -f $O365Object.Environment.ResourceManager, $app.id, "config/web/snapshots","2016-08-01")
                    $params = @{
                        Authentication = $rm_auth;
                        OwnQuery = $URI;
                        Environment = $Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                    }
                    $appSnapShots = Get-MonkeyRMObject @params
                    if($appSnapShots){
                        #Add to object
                        $app | Add-Member -type NoteProperty -name snapshotCount -value $appSnapShots.properties.Count
                        $app | Add-Member -type NoteProperty -name SnapShotInfo -value $appSnapShots
                    }
                    else{
                        $app | Add-Member -type NoteProperty -name snapshotCount -value 0
                        $app | Add-Member -type NoteProperty -name SnapShotInfo -value $null
                    }
                    #Decorate object
                    $app.PSObject.TypeNames.Insert(0,'Monkey365.Azure.WebApp')
                    $AllMyWebApps+=$app
                }
            }
        }
    }
    End{
        if($AllMyWebApps){
            $AllMyWebApps.PSObject.TypeNames.Insert(0,'Monkey365.Azure.WebApps')
            [pscustomobject]$obj = @{
                Data = $AllMyWebApps
            }
            $returnData.az_app_services = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure app services", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureAppServicesEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
