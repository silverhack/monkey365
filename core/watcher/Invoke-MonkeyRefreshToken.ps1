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

Function Invoke-MonkeyRefreshToken{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyRefreshToken
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$O365Object
    )
    Begin{
        $auth_tokens = [hashtable]::Synchronized(@{})
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams -Verbose -Debug
        if($null -ne $O365Object.InformationAction){
            Set-Variable InformationAction -Value $O365Object.InformationAction -Scope Script -Force
        }
        else{
            Set-Variable InformationAction -Value "SilentlyContinue" -Scope Script -Force
        }
    }
    Process{
        try{
            #Iterate over access token values
            foreach($elem in $O365Object.auth_tokens.GetEnumerator()){
                if($null -ne $elem.Value){
                    #Set null value
                    $new_token = $null
                    $Expired_Auth = $elem.Value
                    #Check if token has expired or is null
                    if($Expired_Auth.ExpiresOn.Date -lt (Get-Date).AddMinutes(5)){
                        $current_date = Get-Date
                        $duration = $Expired_Auth.ExpiresOn.LocalDateTime - $current_date
                        $msg = @{
                            MessageData = ($message.ExpiredTokenMessage -f $duration.TotalMinutes);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            InformationAction = $script:InformationAction;
                            Tags = @('MonkeyWatcherExpiredAccessToken');
                        }
                        Write-Debug @msg
                        #Check if msal application
                        if($null -ne $Expired_Auth.psobject.Properties.Item('scopes') -and $null -ne $O365Object.msalapplication){
                            $msg = @{
                                MessageData = ($message.RefreshTokenMessage -f $Expired_Auth.resource, 'MSAL');
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'debug';
                                InformationAction = $script:InformationAction;
                                Tags = @('MonkeyWatcherRefreshingMSALAccessToken');
                            }
                            Write-Debug @msg
                            #Get new params
                            $new_params = @{}
                            foreach ($param in $O365Object.msal_application_args.GetEnumerator()){
                                $new_params.add($param.Key, $param.Value)
                            }
                            #Add resource parameter
                            $new_params.Add('Resource',$Expired_Auth.resource)
                            #Check if EXO token
                            $clientId = $Expired_Auth.clientId
                            $exo_clientId = (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)
                            if($clientId -eq $exo_clientId){
                                Write-Debug "Exchange Online token detected"
                                if($O365Object.isConfidentialApp -eq $false){
                                    #Public application detected
                                    if($null -eq $O365Object.exo_msal_application){
                                        $app = @{}
                                        foreach($param in $O365Object.msal_application_args){
                                            $app.add($param.Key, $param.Value)
                                        }
                                        #Add clientId and RedirectUri
                                        $app.ClientId = (Get-WellKnownAzureService -AzureService ExchangeOnlineV2)
                                        if($PSEdition -eq "Desktop"){
                                            $app.RedirectUri = (Get-MonkeyExoRedirectUri -Environment $O365Object.Environment)
                                        }
                                        $exo_app = New-MonkeyMsalApplication @app
                                        if($null -ne $exo_app){
                                            $O365Object.exo_msal_application = $exo_app
                                        }
                                        $new_params.publicApp = $O365Object.exo_msal_application
                                    }
                                    else{
                                        $new_params.publicApp = $O365Object.exo_msal_application
                                    }
                                }
                            }
                            #Refreshing token by using MSAL
                            $new_token = Get-MSALTokenForResource @new_params
                        }
                        else{ #ADAL application
                            $msg = @{
                                MessageData = ($message.RefreshTokenMessage -f $Expired_Auth.resource, 'ADAL');
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'debug';
                                InformationAction = $script:InformationAction;
                                Tags = @('MonkeyWatcherRefreshingADALAccessToken');
                            }
                            Write-Debug @msg
                            #Get new params
                            $new_params = @{}
                            foreach ($param in $O365Object.application_args.GetEnumerator()){
                                $new_params.add($param.Key, $param.Value)
                            }
                            #Add resource parameter
                            $new_params.Add('Resource',$Expired_Auth.resource)
                            #Add client Id from Access Token
                            if(-NOT $new_params.ContainsKey('clientid')){
                                $new_params.Add('clientId',$Expired_Auth.clientId)
                            }
                            else{
                                $new_params.clientId = $Expired_Auth.clientId
                            }
                            $auth_context = Get-MonkeyADALAuthenticationContext -TenantID $new_params.TenantId
                            if($null -eq $new_params.Item('AuthContext')){
                                [ref]$null = $new_params.Add('AuthContext',$auth_context)
                            }
                            else{
                                $new_params.AuthContext = $auth_context
                            }
                            #Refreshing token by using ADAL
                            $new_token = Get-AdalTokenForResource @new_params
                        }
                        if($null -ne $new_token){
                            $msg = @{
                                MessageData = ($message.MonkeyWatcherRefreshTokenMessage -f $elem.Name);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'debug';
                                InformationAction = $script:InformationAction;
                                Tags = @('MonkeyWatcherRefreshedTokenMessage');
                            }
                            Write-Debug @msg
                            #Add Subscription Id if any
                            try{
                                if($null -ne $O365Object.current_subscription -and $null -ne $O365Object.current_subscription.psobject.Properties.Item('subscriptionId')){
                                    $new_token | Add-Member -type NoteProperty -name SubscriptionId -value $O365Object.current_subscription.subscriptionId -Force
                                }
                            }
                            catch{
                                Write-Warning "Unable to find a subscription"
                            }
                            $auth_tokens.Add($elem.Name, $new_token)
                        }
                        else{
                            $msg = @{
                                MessageData = ($message.UnableToGetAccessToken -f $Expired_Auth.resource);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'debug';
                                InformationAction = $script:InformationAction;
                                Tags = @('MonkeyWatcherUnableToGetAccessToken');
                            }
                            Write-Debug @msg
                            #Add old token
                            $auth_tokens.Add($elem.Name, $elem.Value)
                        }
                        Start-Sleep -Milliseconds 5
                    }
                    else{
                        #Token looks good
                        $msg = @{
                            MessageData = ($message.TokenIsStillValidMessage -f $Expired_Auth.resource);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            InformationAction = $script:InformationAction;
                            Tags = @('MonkeyWatcherAccessTokenStillValid');
                        }
                        Write-Debug @msg
                        #Add current token to hashtable
                        $auth_tokens.Add($elem.Name, $elem.Value)
                    }
                }
                else{
                    $auth_tokens.Add($elem.Name, $null)
                }
            }
            #Set new values
            $O365Object | Add-Member -type NoteProperty -name auth_tokens -value $auth_tokens -Force
        }
        catch{
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $script:InformationAction;
                Tags = @('MonkeyWatcherErrorMessage');
            }
            Write-Debug @msg
        }
    }
    End{
        $msg = @{
            MessageData = $message.MonkeyWatcherSleepMessage;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            InformationAction = $script:InformationAction;
            Tags = @('MonkeyWatcherSleepMessage');
        }
        Write-Debug @msg
    }
}
