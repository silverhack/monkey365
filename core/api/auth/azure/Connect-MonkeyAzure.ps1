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
    Param (
        [Parameter(Mandatory=$true, HelpMessage="parameters")]
        [Object]$parameters
    )
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
    }
    Process{
        if($null -ne $O365Object.auth_tokens.ResourceManager){
            $O365Object.subscriptions = Select-MonkeyAzureSubscription
        }
    }
    End{
        if($null -ne $O365Object.subscriptions){
            foreach($service in $azure_services.GetEnumerator()){
                $msg = @{
                    MessageData = ("Authenticating to {0}" -f $service.Name);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AuthenticatingInfoMessage');
                }
                Write-Information @msg
                $azure_service = $service.Name
                #Get new parameters
                $new_params = @{}
                foreach ($param in $parameters.GetEnumerator()){
                    $new_params.add($param.Key, $param.Value)
                }
                #Add resource parameter
                $new_params.Add('Resource',$service.Value)
                try{
                    $O365Object.auth_tokens.$($azure_service) = Get-MSALTokenForResource @new_params
                    $msg = @{
                        MessageData = ("Successfully connected to {0}" -f $service.Name);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AuthSuccessInfoMessage');
                    }
                    Write-Information @msg
                }
                catch{
                    Write-Warning ("Unable to get Token for {0}" -f $service.Name)
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
                        Tags = @('TokenError');
                    }
                    Write-Verbose $_
                }
            }
        }
    }
}
