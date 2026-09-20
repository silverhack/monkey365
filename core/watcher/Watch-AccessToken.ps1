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


Function Watch-AccessToken{
    <#
        .SYNOPSIS
		####### Utility that will monitor access tokens lifetime ########

        .DESCRIPTION
		####### Utility that will monitor access tokens lifetime ########

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Watch-AccessToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        #Attempt to unregister event and stop all jobs.
        [Parameter(Mandatory = $false)]
        [switch] $Stop
    )
    try{
        If($PSBoundParameters.ContainsKey('Stop') -and $PSBoundParameters['Stop'].IsPresent){
            If($null -ne (Get-Variable -Name TokenWatcher -ErrorAction Ignore)){
                #Get potential exceptions
                $JobStatus = $TokenWatcher.Job.JobStatus();
                if($JobStatus.Error.Count -gt 0){
                    foreach($exception in $JobStatus.Error.GetEnumerator()){
                        Write-Error $exception;
                    }
                }
                $TokenWatcher | Remove-MonkeyJob -Force
                Start-Sleep -Milliseconds 1500
                #Remove Variable
                Remove-Variable -Name TokenWatcher -Scope Script -Force -ErrorAction Ignore
            }
        }
        Else{
            #Modules
            $MSAL = @(
                ("{0}{1}core/modules/monkeymsal" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar),
                ("{0}{1}core/modules/monkeylogger" -f $O365Object.Localpath,[System.IO.Path]::DirectorySeparatorChar)
            )
            $vars = [ordered]@{
                O365Object = $O365Object;
                WriteLog = $O365Object.WriteLog;
                Verbosity = $O365Object.VerboseOptions;
                InformationAction = $O365Object.InformationAction;
                returnData = $null;
                LogQueue = $O365Object.MonkeyLogQueue;
            }
            #Scriptblock
            $scriptblock = {
                while($true){
                    Try{
                        #Get Tokens
                        foreach($at in $O365Object.auth_tokens.GetEnumerator().Where({$null -ne $_.Value -and $_.Value.IsNearExpiry()})){
                            $new_token = $null
                            $expired_token = $at.Value
                            $duration = $expired_token.ExpiresOn.LocalDateTime - (Get-Date)
                            $msg = @{
                                Message = ($message.CloseToExpireTokenMessage -f $expired_token.resource, $duration.TotalMinutes);
                                Verbose = $O365Object.Verbose;
                            }
                            Write-Verbose @msg
                            #Get new params
                            $new_params = @{}
                            foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
                                [void]$new_params.add($param.Key, $param.Value)
                            }
                            #Get MSAL application
                            if($O365Object.isConfidentialApp){
                                $app = $O365Object.msal_confidential_applications.Where({$_.ClientId -eq $expired_token.clientId})
                                if($app.Count -gt 0){
                                    $new_params.Item('confidentialApp') = $app[0]
                                }
                                else{
                                    Write-Warning ("MSAL application was not found for {0}" -f $expired_token.clientId)
                                    return
                                }
                            }
                            else{
                                $app = $O365Object.msal_public_applications.Where({$_.ClientId -eq $expired_token.clientId})
                                if($app.Count -gt 0){
                                    $new_params.Item('publicApp') = $app[0]
                                }
                                else{
                                    Write-Warning ("MSAL application was not found for {0}" -f $expired_token.clientId)
                                    return
                                }
                            }
                            #Add Silent
                            if($new_params.ContainsKey('Silent')){
                                $new_params.Silent = $True;
                            }
                            else{
                                [ref]$null = $new_params.Add('Silent',$True);
                            }
                            #Add force refresh
                            if(-NOT $new_params.ContainsKey('ForceRefresh')){
                                #Add Force refresh
                                [ref]$null = $new_params.Add('ForceRefresh',$true)
                            }
                            else{
                                $new_params.ForceRefresh = $True;
                            }
                            ##Add Resource
                            $new_params.Resource = $expired_token.resource;
                            #Refresh Authentication Token
                            $new_token = Get-MonkeyMSALToken @new_params
                            if($null -ne $new_token){
                                $msg = @{
                                    Message = ($message.MonkeyWatcherRefreshTokenMessage -f $at.Name);
                                    Verbose = $O365Object.Verbose;
                                }
                                Write-Verbose @msg
                                #Add Subscription Id if any
                                try{
                                    if($null -ne $O365Object.current_subscription -and $null -ne $O365Object.current_subscription.psobject.Properties.Item('subscriptionId')){
                                        $new_token | Add-Member -type NoteProperty -name SubscriptionId -value $O365Object.current_subscription.subscriptionId -Force
                                    }
                                }
                                catch{
                                    Write-Warning "Unable to find a subscription"
                                }
                                #Add the new token to hashtable
                                $O365Object.auth_tokens.Item($at.Name) = $new_token
                            }
                            else{
                                $msg = @{
                                    Message = ($message.UnableToGetAccessToken -f $expired_token.resource);
                                    Verbose = $O365Object.Verbose;
                                }
                                Write-Verbose @msg
                            }
                            #Sleep
                            Start-Sleep -Milliseconds 5
                        }
                    }
                    Catch{
                        Write-Error $_
                    }
                    Finally{
                        $msg = @{
                            Message = $message.MonkeyWatcherSleepMessage;
                            Verbose = $O365Object.Verbose;
                        }
                        Write-Verbose @msg
                        Start-Sleep -Seconds 300
                    }
                }
            }
            #Execute job
            $p = @{
                JobName = "WatchAccessTokenJob";
                ScriptBlock = $scriptblock;
                ImportVariables = $vars;
                ImportModules = $MSAL;
                StartUpScripts = $O365Object.runspace_init;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            New-Variable -Name TokenWatcher -Scope Script -Value (Start-MonkeyJob @p) -Force
        }
    }
    catch{
        Write-Error $_
    }
}

