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

Function Connect-MonkeyAzure{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Connect-MonkeyAzure
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param ()
    Begin{
        $azure_services = @{
            ResourceManager = $O365Object.Environment.ResourceManager;
            Graph = $O365Object.Environment.Graph;
            ServiceManagement = $O365Object.Environment.Servicemanagement;
            AzurePortal = Get-WellKnownAzureService -AzureService AzurePortal;
            SecurityPortal = $O365Object.Environment.Servicemanagement;
            AzureStorage = $O365Object.Environment.Storage;
            AzureVault = $O365Object.Environment.Vaults;
            MSGraph =$O365Object.Environment.Graphv2;
            LogAnalytics = $O365Object.Environment.LogAnalytics;
        }
        #Get new app params
        if($null -ne $O365Object.msal_application_args){
            $app_params = $O365Object.msal_application_args;
        }
        else{
            $app_params = $null;
        }
    }
    Process{
        if($null -ne $O365Object.auth_tokens.ResourceManager){
            $O365Object.subscriptions = Select-MonkeyAzureSubscription
        }
    }
    End{
        if($null -ne $O365Object.subscriptions -and $null -ne $app_params){
            foreach($service in $azure_services.GetEnumerator()){
                $msg = @{
                    MessageData = ($message.TokenRequestInfoMessage -f $service.Name)
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('TokenRequestInfoMessage');
                }
                Write-Information @msg
                $azure_service = $service.Name
                #Get new parameters
                $new_params = @{}
                foreach ($param in $app_params.GetEnumerator()){
                    $new_params.add($param.Key, $param.Value)
                }
                #Add resource parameter
                $new_params.Add('Resource',$service.Value)
                try{
                    $O365Object.auth_tokens.$($azure_service) = Get-MSALTokenForResource @new_params
                    $msg = @{
                        MessageData = ($message.TokenAcquiredInfoMessage -f $service.Name)
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('TokenAcquiredMessage');
                    }
                    Write-Information @msg
                }
                catch{
                    $msg = @{
                        MessageData = ($message.UnableToGetAccessToken -f $service.Name)
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('TokenErrorMessage');
                    }
                    Write-Warning @msg
                    if($O365Object.auth_tokens.ContainsKey($azure_service)){
                        $O365Object.auth_tokens.$($azure_service) = $null
                    }
                    else{
                        [ref]$null = $O365Object.auth_tokens.Add($azure_service,$null)
                    }
                    $msg = @{
                        MessageData = $_;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('TokenError');
                    }
                    Write-Verbose $_
                }
            }
        }
    }
}
