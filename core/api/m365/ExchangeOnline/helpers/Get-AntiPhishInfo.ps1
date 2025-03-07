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

Function Get-AntiPhishingInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-AntiPhishingInfo
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
            MessageData = "Getting Anti Phish Configuration";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('O365AntiPhishInfo');
        }
        Write-Information @msg
        $PhishFilterStatus = $null
        $phishFilterCollection = $null
        if($null -ne $ExoAuth){
            $PhishFilterStatus = New-Object System.Collections.Generic.List[System.Object]
            $phishFilterCollection = [ordered]@{}
            try{
                #Get AntiPhish Policy
                $p.Command = 'Get-AntiphishPolicy';
                $phishFilterCollection.AntiPhishPolicy = Get-PSExoAdminApiObject @p
                #Get AntiPhish Rules
                $p.Command = 'Get-AntiPhishRule';
                $phishFilterCollection.AntiPhishRules = Get-PSExoAdminApiObject @p
                #Get EOP protection rules
                $p.Command = 'Get-EOPProtectionPolicyRule';
                $phishFilterCollection.EOPProtectionPolicyRule = Get-PSExoAdminApiObject @p
            }
            catch{
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('ExoAntiPhishError');
                }
                Write-Verbose @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NoPsSessionWasFound -f "Anti-Phishing");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('ExoAntiPhishPsSessionError');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($null -ne $phishFilterCollection -and $phishFilterCollection.AntiPhishPolicy){
            foreach($phishPolicy in @($phishFilterCollection.AntiPhishPolicy)){
                $enabled = $true;
                $policyName = $phishPolicy.Name
                if($null -ne $phishFilterCollection.AntiPhishRules){
                    $associated_rule = $phishFilterCollection.AntiPhishRules | Where-Object {$_.MalwareFilterPolicy -eq $policyName} -ErrorAction Ignore
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
                    if($null -ne $phishFilterCollection.EOPProtectionPolicyRule){
                        $eop_associated_rule = $phishFilterCollection.EOPProtectionPolicyRule | Where-Object {$_.MalwareFilterPolicy -eq $policyName} -ErrorAction Ignore
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
                $policyName = $phishPolicy.Name;
                $phishPsObject = New-Object -TypeName PsObject -Property @{
                    policyName = $policyName;
                    isEnabled = $enabled;
                    Policy = $phishPolicy;
                    Rule = $associated_rule;
                }
                #Add to array
                [void]$PhishFilterStatus.Add($phishPsObject)
            }
        }
    }
    End{
        $PhishFilterStatus
    }
}


