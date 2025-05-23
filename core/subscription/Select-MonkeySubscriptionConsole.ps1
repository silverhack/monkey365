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

Function Select-MonkeySubscriptionConsole{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Select-MonkeySubscriptionConsole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Subscriptions
    )
    Begin{
        $selected_subscriptions = $choices = $null;
        try{
            if($Subscriptions.Count -gt 0){
                $choices = @()
                For($index = 0; $index -lt $Subscriptions.Count; $index++){
                    $Subscriptions[$index] | Add-Member -type NoteProperty -name Id -value $index -Force
                    [psobject]$s = @{
                        id = $index+1
                        displayName = $Subscriptions[$index].displayName
                    }
                    $choices+=$s
                }
            }
        }
        catch{
            Write-Warning "Unable to create subscription choices"
            $msg = @{
                MessageData = $_.Exception;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $script:InformationAction;
                Tags = @('SubscriptionChoicesError');
            }
            Write-Debug @msg
            $choices = $null
        }
    }
    Process{
        if($null -ne $choices){
            while ($true) {
                $choices | Select-Object Id,DisplayName | Format-Table -AutoSize | Out-Host
                $sbsID = Read-Host "Enter the [ID] number to select a subscription. Type 0 or Q to quit. Type A for all"
                if ($sbsID -eq '0' -or $sbsID -eq 'Q') { break }  # exit from the loop, user quits
                if ($sbsID -eq 'A') {$selected_subscriptions = $Subscriptions; break }  # exit from the loop, user quits
                # test if the input is numeric and is in range
                $badInput = $true
                if ($sbsID -notmatch '\D') {    # if the input does not contain an non-digit
                    $index = [int]$sbsID - 1
                    if ($index -ge 0 -and $index -lt $Subscriptions.Count) {
                        $badInput = $false
                        # everything OK and subscription is selected
                        $msg = @{
                            MessageData = ($message.AzureSelectedSubscriptionInfo -f $Subscriptions[$index].DisplayName);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'info';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('AzureSubscriptionInfo');
                        }
                        Write-Information @msg
                        $selected_subscriptions = $Subscriptions[$index]
                        break
                    }
                }
                # if you received bad input, show a message, wait a couple
                # of seconds so the message can be read and start over
                if ($badInput) {
                    $msg = @{
                        MessageData = ($message.AzureConsoleBadInputError);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureSubscriptionBadInput');
                    }
                    Write-Warning @msg
                    Start-Sleep -Seconds 4
                }
            }
        }
    }
    End{
        return $selected_subscriptions
    }
}

