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

Function Resolve-AzureSubscription{
    <#
        .SYNOPSIS
        Utility to check subscription status

        .DESCRIPTION
        Utility to check subscription status

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-AzureSubscription
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Subscription object")]
        [Object]$subscription
    )
    Begin{
        $state = $null
        $subscriptionId = $null
        $EmptyGuid = [System.Guid]::empty
        #Get Subscription details
        if($null -ne $subscription.Psobject.Properties.Item('Id')){
            $subscriptionId = $subscription.Id;
        }
        if($null -ne $subscription.Psobject.Properties.Item('state')){
            $state = $subscription.state
        }
        $isValidSubscription = [System.Guid]::TryParse($subscriptionId,[System.Management.Automation.PSReference]$EmptyGuid)
    }
    Process{
        if($isValidSubscription -eq $false){
            $msg = @{
                MessageData = ($message.AzureSubscriptionError -f $subscription.displayName, $state);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExpiredSubscription');
            }
            Write-Warning @msg
            #Change Id value to point subscriptionId
            $subscription.Id = $subscription.subscriptionId
        }
    }
    End{
        return $subscription
    }
}