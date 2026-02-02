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

Function Get-SafeLinksInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-SafeLinksInfo
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
            MessageData = "Getting ATP Safe Links Information";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('O365ATPInfo');
        }
        Write-Information @msg
        $safeLinksInfo = $null
        $safeLinksCollection = $null
        if($null -ne $ExoAuth){
            #Set generic list and HashTable
            $safeLinksInfo = New-Object System.Collections.Generic.List[System.Object]
            $safeLinksCollection = [ordered]@{}
            try{
                $p.Command = 'Get-SafeLinksPolicy';
                $safeLinksCollection.SafeLinksPolicy = Get-PSExoAdminApiObject @p
                #Get Safe Links Rules
                $msg = @{
                    MessageData = "Getting ATP Safe Links Rules";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('O365ATPInfo');
                }
                Write-Information @msg
                $p.Command = 'Get-SafeLinksRule';
                $safeLinksCollection.SafeLinksRules = Get-PSExoAdminApiObject @p
                #Get ATP protection rules
                $msg = @{
                    MessageData = "Getting ATP Protection Policy Rules";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('O365ATPInfo');
                }
                Write-Information @msg
                $p.Command = 'Get-ATPProtectionPolicyRule';
                $safeLinksCollection.ATPProtectionPolicyRule = Get-PSExoAdminApiObject @p
            }
            catch{
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('ExoSafeLinksError');
                }
                Write-Verbose @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NoPsSessionWasFound -f "SafeLinks");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('ExoSafeLinksInfo');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($null -ne $safeLinksCollection -and $safeLinksCollection.SafeLinksPolicy){
            foreach($slPolicy in @($safeLinksCollection.SafeLinksPolicy)){
                $enabled = $true;
                $policyName = $slPolicy.Name
                if($null -ne $safeLinksCollection.SafeLinksRules){
                    $associated_rule = $safeLinksCollection.SafeLinksRules | Where-Object {$_.SafeLinksPolicy -eq $policyName} -ErrorAction Ignore
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
                    if($null -ne $safeLinksCollection.ATPProtectionPolicyRule){
                        $atp_associated_rule = $safeLinksCollection.ATPProtectionPolicyRule | Where-Object {$_.SafeLinksPolicy -eq $policyName} -ErrorAction Ignore
                        if($null -ne $atp_associated_rule){
                            $associated_rule = $atp_associated_rule;
                            #Get State
                            $state = $atpRule.State
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
                $policyName = $slPolicy.Name;
                $slPsObject = New-Object -TypeName PsObject -Property @{
                    policyName = $policyName;
                    isEnabled = $enabled;
                    isBuiltin = $slPolicy.IsBuiltInProtection;
                    policy = $slPolicy;
                    policyId = $slPolicy.Guid.Guid;
                    rule = $associated_rule;
                    ruleId = If($associated_rule){$associated_rule.Guid.Guid};
                }
                #Add to array
                [void]$safeLinksInfo.Add($slPsObject)
            }
        }
    }
    End{
        $safeLinksInfo
    }
}

