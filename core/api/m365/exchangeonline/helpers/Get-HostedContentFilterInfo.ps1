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

Function Get-HostedContentFilterInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-HostedContentFilterInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    Begin{
        #Get instance
        $Environment = $O365Object.Environment
        #Get Exchange Online Auth token
        $ExoAuth = $O365Object.auth_tokens.ExchangeOnline
        #InitParams
        $p = @{
            Authentication = $ExoAuth;
            Environment = $Environment;
            ResponseFormat = 'clixml';
            Command = $null;
            Method = "POST";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $msg = @{
            MessageData = "Getting Anti-Spam Configuration";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('O365AntiSpamInfo');
        }
        Write-Information @msg
        $HostedContentFilterStatus = $null
        $hostedContentCollection = $null
        if($null -ne $ExoAuth){
            $HostedContentFilterStatus = New-Object System.Collections.Generic.List[System.Object]
            $hostedContentCollection = [ordered]@{}
            try{
                #Get Hosted Content Filter Policy
                $p.Command = 'Get-HostedContentFilterPolicy';
                $hostedContentCollection.HostedContentFilterPolicy = Get-PSExoAdminApiObject @p
                #Get Hosted Content Filter Rules
                $msg = @{
                    MessageData = "Getting Hosted Content Filter Rules";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('O365AntiSpamInfo');
                }
                Write-Information @msg
                $p.Command = 'Get-HostedContentFilterRule';
                $hostedContentCollection.HostedContentFilterRule = Get-PSExoAdminApiObject @p
                #Get EOP protection rules
                $msg = @{
                    MessageData = "Getting EOP Protection Policy Rules";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('O365AntiSpamInfo');
                }
                Write-Information @msg
                $p.Command = 'Get-EOPProtectionPolicyRule';
                $hostedContentCollection.EOPProtectionPolicyRule = Get-PSExoAdminApiObject @p
                #Get Quarantine rules
                $msg = @{
                    MessageData = "Getting Quarantine Policy Settings";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('O365AntiSpamInfo');
                }
                Write-Information @msg
                $p.Command = 'Get-QuarantinePolicy';
                $hostedContentCollection.QuarantineSettings = Get-PSExoAdminApiObject @p
            }
            catch{
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('ExoHostedContentError');
                }
                Write-Verbose @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NoPsSessionWasFound -f "Hosted Content");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('ExoHostedContentError');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($null -ne $hostedContentCollection -and $hostedContentCollection.HostedContentFilterPolicy){
            foreach($hostedPolicy in @($hostedContentCollection.HostedContentFilterPolicy)){
                $enabled = $true;
                $policyName = $hostedPolicy.Name
                $quarantineTag = $hostedPolicy.SpamQuarantineTag
                #Get quarantine settings
                if($null -ne $hostedContentCollection.QuarantineSettings){
                    $quarantine_policy = $hostedContentCollection.QuarantineSettings | Where-Object {$_.Name -eq $quarantineTag} -ErrorAction Ignore
                }
                else{
                    $quarantine_policy = $null
                }
                if($null -ne $hostedContentCollection.HostedContentFilterRule){
                    $associated_rule = $hostedContentCollection.HostedContentFilterRule | Where-Object {$_.HostedContentFilterPolicy -eq $policyName} -ErrorAction Ignore
                }
                else{
                    $associated_rule = $null
                }
                if($null -ne $associated_rule){
                    if($associated_rule.State -eq "Enabled"){
                        $enabled = $true;
                    }
                    else{
                        $enabled = $false;
                    }
                }
                elseif ($policyName -match "Built-In") {
                    $enabled = $true;
                }
                elseif ($policyName -match "Default") {
                    $enabled = $true;
                }
                else{
                    if($null -ne $hostedContentCollection.EOPProtectionPolicyRule){
                        $eop_associated_rule = $hostedContentCollection.EOPProtectionPolicyRule | Where-Object {$_.HostedContentFilterPolicy -eq $policyName} -ErrorAction Ignore
                        if($null -ne $eop_associated_rule){
                            $associated_rule = $eop_associated_rule;
                            #Get State
                            $state = $eop_associated_rule.State
                            #Check state
                            if($state -eq "Enabled"){
                                $enabled = $true;
                            }
                            elseif($state -eq "Disabled") {
                                $enabled = $false;
                            }
                            else {
                                $enabled = $false;
                            }
                        }
                        else{
                            $enabled = $false;
                        }
                    }
                    else{
                        $enabled = $false;
                    }
                }
                $policyName = $hostedPolicy.Name;
                $hostedPsObject = New-Object -TypeName PsObject -Property @{
                    policyName = $policyName;
                    isEnabled = $enabled;
                    Policy = $hostedPolicy;
                    Rule = $associated_rule;
                    QuarantinePolicy = $quarantine_policy;
                }
                #Add to array
                [void]$HostedContentFilterStatus.Add($hostedPsObject)
            }
        }
    }
    End{
        $HostedContentFilterStatus
    }
}

