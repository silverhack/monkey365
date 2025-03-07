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

Function Invoke-AzureScanner{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-M365Scanner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param()
    try{
        if($null -ne $O365Object.Collectors -and @($O365Object.Collectors).Count -gt 0){
            if($O365Object.IncludeEntraID){
                #Set synchronized hashtable
                Set-Variable aadReturnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
                #Set params
                $p = @{
                    Provider = 'EntraID';
                    Throttle = $O365Object.threads;
                    ReturnData = $Script:aadReturnData;
                    Debug = $O365Object.Debug;
                    Verbose = $O365Object.Verbose;
                    InformationAction = $O365Object.InformationAction;
                }
                #Launch collectors
                Invoke-MonkeyScanner @p
            }
            if($null -ne $O365Object.subscriptions){
                foreach($azSubscription in @($O365Object.subscriptions)){
                    $msg = @{
                        MessageData = ($message.SubscriptionWorkingMessage -f $azSubscription.displayName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureSubscriptionScanner');
                    }
                    Write-Information @msg
                    #Add current subscription to O365Object
                    $O365Object.current_subscription = Resolve-AzureSubscription -Subscription $azSubscription
                    #Update authentication objects
                    Update-MonkeyAuthObject
                    $O365Object.azPermissions = Get-MonkeyAzIAMPermission -CurrentUser
                    #Get ExecutionInfo
                    $O365Object.executionInfo = Get-ExecutionInfo
                    $msg = @{
                        MessageData = ($message.SubscriptionResourcesMessage -f $O365Object.current_subscription.displayName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureSubscriptionScanner');
                    }
                    Write-Information @msg
                    $msg = @{
                        MessageData = ($message.SubscriptionResourcesMessage -f $O365Object.current_subscription.displayName);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureSubscriptionScanner');
                    }
                    Write-Information @msg
                    #Get resource groups
                    if($O365Object.initParams.psobject.Properties.Item('resourcegroups')){
                        $rg_names = $O365Object.initParams.resourcegroups
                    }
                    else{
                        $rg_names = $null
                    }
                    $O365Object.ResourceGroups = Get-MonkeyAzResourceGroup -ResourceGroupNames $rg_names
                    #Get all resources within subscription
                    $O365Object.all_resources = Get-MonkeyAzResource -ResourceGroupNames $rg_names -DiagnosticSettingsSupport
                    #Check if should skip resources from being scanned
                    Skip-MonkeyAzResource
                    #Set synchronized hashtable
                    Set-Variable returnData -Value ([hashtable]::Synchronized(@{})) -Scope Script -Force
                    #Set params
                    $p = @{
                        Provider = 'Azure';
                        Throttle = $O365Object.threads;
                        ReturnData = $Script:returnData;
                        Debug = $O365Object.Debug;
                        Verbose = $O365Object.Verbose;
                        InformationAction = $O365Object.InformationAction;
                    }
                    #Launch collectors
                    Invoke-MonkeyScanner @p
                    #Check if AAD data
                    if($null -ne (Get-Variable -Name aadReturnData -Scope Script -ErrorAction Ignore)){
                        $Script:returnData = Join-HashTable -HashTable $returnData -JoinHashTable $aadReturnData
                    }
                    if($Script:returnData.Count -gt 0){
                        #Prepare output
                        Out-MonkeyData -OutData $returnData
                    }
                    else{
                        $msg = @{
                            MessageData = "There is no data to export";
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('AzureScannerEmptyData');
                        }
                        Write-Warning @msg
                    }
                }
            }
        }
    }
    Catch{
        Write-Error $_
    }
    Finally{
        #Perform garbage collection
        [System.GC]::GetTotalMemory($true) | out-null
    }
}


