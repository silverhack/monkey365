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

Function Update-MonkeyAuthObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Update-MonkeyAuthObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    Param ()
    try{
        foreach($auth in $O365Object.auth_tokens.GetEnumerator()){
            if($null -ne $auth.Value -and $null -ne $auth.Value.psobject.Properties.Item('AccessToken')){
                if($null -ne (Get-Variable -Name Subscription -Scope Script -ErrorAction Ignore) -and $null -ne $Script:Subscription){
                    $auth.Value | Add-Member -type NoteProperty -name SubscriptionId -value $script:Subscription.subscriptionId -Force
                }
            }
        }
    }
    catch{
        $msg = @{
            MessageData = $message.AuthObjectErrorMessage;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('AzureSubscriptionError');
        }
        Write-Warning @msg
        $msg = @{
            MessageData = $_;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'error';
            InformationAction = $InformationAction;
            Tags = @('AzureSubscriptionError');
        }
        Write-Error @msg
        #Debug error
        $msg = @{
            MessageData = $_.Exception.StackTrace;
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            InformationAction = $InformationAction;
            Tags = @('AzureSubscriptionError');
        }
        Write-Debug @msg
    }
}
