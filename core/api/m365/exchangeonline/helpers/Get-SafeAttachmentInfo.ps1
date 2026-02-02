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

Function Get-SafeAttachmentInfo{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-SafeAttachmentInfo
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
            MessageData = "Getting ATP Safe Attachment Information";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('O365ATPInfo');
        }
        Write-Information @msg
        $SafeAttachmentStatus = $null
        $safeAttachmentCollection = $null
        if($null -ne $ExoAuth){
            $SafeAttachmentStatus = New-Object System.Collections.Generic.List[System.Object]
            $safeAttachmentCollection = [ordered]@{}
            try{
                #Get Safe Attachment Policy
                $p.Command = 'Get-SafeAttachmentPolicy';
                $safeAttachmentCollection.SafeAttachmentsPolicy = Get-PSExoAdminApiObject @p
                #Get Safe Attachment Rules
                $msg = @{
                    MessageData = "Getting ATP Safe Attachment Rules";
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('O365ATPInfo');
                }
                Write-Information @msg
                $p.Command = 'Get-SafeAttachmentRule';
                $safeAttachmentCollection.SafeAttachmentsRules = Get-PSExoAdminApiObject @p
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
                $safeAttachmentCollection.ATPProtectionPolicyRule = Get-PSExoAdminApiObject @p
            }
            catch{
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Tags = @('ExoSafeAttachmentError');
                }
                Write-Verbose @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.NoPsSessionWasFound -f "SafeAttachments");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('ExoSafeAttachmentsPsSessionError');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($null -ne $safeAttachmentCollection -and $safeAttachmentCollection.SafeAttachmentsPolicy){
            foreach($saPolicy in @($safeAttachmentCollection.SafeAttachmentsPolicy)){
                $enabled = $true;
                $policyName = $saPolicy.Name
                if($null -ne $safeAttachmentCollection.SafeAttachmentsRules){
                    $associated_rule = $safeAttachmentCollection.SafeAttachmentsRules | Where-Object {$_.SafeAttachmentPolicy -eq $policyName} -ErrorAction Ignore
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
                    if($null -ne $safeAttachmentCollection.ATPProtectionPolicyRule){
                        $atp_associated_rule = $safeAttachmentCollection.ATPProtectionPolicyRule | Where-Object {$_.SafeAttachmentPolicy -eq $policyName} -ErrorAction Ignore
                        if($null -ne $atp_associated_rule){
                            $associated_rule = $atp_associated_rule;
                            #Get State
                            $state = $atp_associated_rule.State
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
                $policyName = $saPolicy.Name;
                $saPsObject = New-Object -TypeName PsObject -Property @{
                    policyName = $policyName;
                    isEnabled = $enabled;
                    policy = $saPolicy;
                    policyId = $saPolicy.Guid.Guid;
                    rule = $associated_rule;
                    ruleId = IF($associated_rule){$associated_rule.ImmutableId.Guid};
                }
                #Add to array
                [void]$SafeAttachmentStatus.Add($saPsObject)
            }
        }
    }
    End{
        $SafeAttachmentStatus
    }
}

