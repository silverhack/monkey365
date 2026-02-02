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

Function Invoke-StrictPolicyForPriorityAccount{
    <#
        .SYNOPSIS
        Get information about preset security policies for priority accounts

        .DESCRIPTION

        .INPUTS

        .OUTPUTS
        PsCustomObject with information about preset security policies for priority accounts

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-StrictPolicyForPriorityAccount
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    Begin{
        #Get instance
        $Environment = $O365Object.Environment;
        #Check if Exchange Online Auth is present, and if not, use token from Purview
        If($null -ne $O365Object.auth_tokens.ExchangeOnline){
            $exoAuth = $O365Object.auth_tokens.ExchangeOnline;
        }
        Else{
            $exoAuth = $O365Object.auth_tokens.ComplianceCenter;
        }
        #Set PsObject
        $presetSecurityPolicyObj = [PsCustomObject]@{
            properties = [PsCustomObject]@{
                eopProtectionPolicy = [PsCustomObject]@{
                    rule = $null;
                    enabled = $false;
                };
                atpProtectionPolicy = [PsCustomObject]@{
                    rule = $null;
                    enabled = $false;
                };
                protectedUsers = [System.Collections.Generic.List[System.Object]]::new();
            }
            config = [PsCustomObject]@{
                protectionType = $null;
                priorityAccountsProtectedByEOP = $true;
                priorityAccountsProtectedByATP = $true;
            }
        }
        $eopUsersProtected = [System.Collections.Generic.List[System.Object]]::new();
        $eopUsersexcluded = [System.Collections.Generic.List[System.Object]]::new();
        $atpUsersProtected = [System.Collections.Generic.List[System.Object]]::new();
        $atpUsersexcluded = [System.Collections.Generic.List[System.Object]]::new();
        $new_arg = @{
            APIVersion = 'v1.0';
        }
        $jobParam = @{
	        ScriptBlock = { Get-MonkeyMSGraphUser -UserPrincipalName $_ -BypassMFACheck};
            Arguments = $new_arg;
	        Runspacepool = $O365Object.monkey_runspacePool;
	        ReuseRunspacePool = $true;
	        Debug = $O365Object.VerboseOptions.Debug;
	        Verbose = $O365Object.VerboseOptions.Verbose;
	        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	        BatchSize = $O365Object.nestedRunspaces.BatchSize;
        }
        $msg = @{
            MessageData = "Getting information about preset security policy";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365PresetSecurityPolicyInfo');
        }
        Write-Information @msg
    }
    Process{
        # Get Preset security policy for AntiPhishing, malware filter policy, etc..
        $p = @{
			Authentication = $exoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-EOPProtectionPolicyRule';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
        $msg = @{
            MessageData = "Getting preset security policies";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365PresetSecurityInfo');
        }
        Write-Information @msg
		$presetSecurityPolicyObj.properties.eopProtectionPolicy.rule = Get-PSExoAdminApiObject @p
        If($null -ne $presetSecurityPolicyObj.properties.eopProtectionPolicy.rule){
            If($presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.State.ToLower() -eq 'enabled'){
                $presetSecurityPolicyObj.properties.eopProtectionPolicy.enabled = $true;
            }
        }
        # Get Preset security policy for Safe links, safe attachment policy, etc..
        $p = @{
			Authentication = $exoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-ATPProtectionPolicyRule';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
        $msg = @{
            MessageData = "Getting ATP protection policy";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365ATPInfo');
        }
        Write-Information @msg
        $presetSecurityPolicyObj.properties.atpProtectionPolicy.rule = Get-PSExoAdminApiObject @p
        If($null -ne $presetSecurityPolicyObj.properties.atpProtectionPolicy.rule){
            If($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.State.ToLower() -eq 'enabled'){
                $presetSecurityPolicyObj.properties.atpProtectionPolicy.enabled = $true;
            }
            #Check protection type
            If($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.Identity.ToLower().Contains('standard')){
                $presetSecurityPolicyObj.config.protectionType = 'standard'
            }
            ElseIf($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.Identity.ToLower().Contains('strict')){
                $presetSecurityPolicyObj.config.protectionType = 'strict'
            }
            Else{
                $presetSecurityPolicyObj.config.protectionType = $null
            }
        }
        # Get protected users
        $p = @{
			Authentication = $exoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-User -IsVIP';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
        $msg = @{
            MessageData = "Getting protected users";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365PriorityAccountInfo');
        }
        Write-Information @msg
        $protectedUsers = Get-PSExoAdminApiObject @p
        IF($null -ne $protectedUsers){
            ForEach ($user in @($protectedUsers)){
                $presetSecurityPolicyObj.properties.protectedUsers.Add($user);
            }
        }
    }
    End{
        If($presetSecurityPolicyObj.Properties.protectedUsers.Count -gt 0){
            If($presetSecurityPolicyObj.properties.eopProtectionPolicy.enabled){
                #Get EOP members
                If($presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.SentTo.Count -gt 0){
                    $users = $presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.SentTo | Invoke-MonkeyJob @jobParam
                    If($null -ne $users){
                        ForEach($user in @($users)){
                            [void]$eopUsersProtected.Add($user);
                        }
                    }
                }
                #Get groups
                If($presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.SentToMemberOf.Count -gt 0){
                    $new_arg = @{
                        APIVersion = 'v1.0';
                    }
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroup -Filter "Mail eq '$_'"};
                    $jobParam.Arguments = $new_arg;
                    $groups = $presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.SentToMemberOf | Invoke-MonkeyJob @jobParam
                    $groupIds = $groups | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    If($null -ne $groupIds){
                        $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroupTransitiveMember -GroupId $_ -Parents @($_)};
                        $groupMembers = $groupIds | Invoke-MonkeyJob @jobParam
                        If($null -ne $groupMembers){
                            ForEach($member in @($groupMembers)){
                                [void]$eopUsersProtected.Add($member);
                            }
                        }
                    }
                }
                #Get EOP user exception
                If($presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.ExceptIfSentTo.Count -gt 0){
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphUser -UserPrincipalName $_ -BypassMFACheck};
                    $users = $presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.ExceptIfSentTo | Invoke-MonkeyJob @jobParam
                    If($null -ne $users){
                        ForEach($user in @($users)){
                            [void]$eopUsersexcluded.Add($user);
                        }
                    }
                }
                #Get EOP excluded groups
                If($presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.ExceptIfSentToMemberOf.Count -gt 0){
                    $new_arg = @{
                        APIVersion = 'v1.0';
                    }
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroup -Filter "Mail eq '$_'"};
                    $jobParam.Arguments = $new_arg;
                    $groups = $presetSecurityPolicyObj.properties.eopProtectionPolicy.rule.ExceptIfSentToMemberOf | Invoke-MonkeyJob @jobParam
                    $groupIds = $groups | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    If($null -ne $groupIds){
                        $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroupTransitiveMember -GroupId $_ -Parents @($_)};
                        $groupMembers = $groupIds | Invoke-MonkeyJob @jobParam
                        If($null -ne $groupMembers){
                            ForEach($member in @($groupMembers)){
                                [void]$eopUsersexcluded.Add($member);
                            }
                        }
                    }
                }
            }
            Else{
                $presetSecurityPolicyObj.config.priorityAccountsProtectedByEOP = $false
            }
            If($presetSecurityPolicyObj.properties.atpProtectionPolicy.enabled){
                #Get ATP members
                If($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.SentTo.Count -gt 0){
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphUser -UserPrincipalName $_ -BypassMFACheck};
                    $users = $presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.SentTo | Invoke-MonkeyJob @jobParam
                    If($null -ne $users){
                        ForEach($user in @($users)){
                            [void]$atpUsersProtected.Add($user);
                        }
                    }
                }
                #Get ATP groups
                If($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.SentToMemberOf.Count -gt 0){
                    $new_arg = @{
                        APIVersion = 'v1.0';
                    }
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroup -Filter "Mail eq '$_'"};
                    $jobParam.Arguments = $new_arg;
                    $groups = $presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.SentToMemberOf | Invoke-MonkeyJob @jobParam
                    $groupIds = $groups | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    If($null -ne $groupIds){
                        $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroupTransitiveMember -GroupId $_ -Parents @($_)};
                        $groupMembers = $groupIds | Invoke-MonkeyJob @jobParam
                        If($null -ne $groupMembers){
                            ForEach($member in @($groupMembers)){
                                [void]$atpUsersProtected.Add($member);
                            }
                        }
                    }
                }
                #Get ATP user exception
                If($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.ExceptIfSentTo.Count -gt 0){
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphUser -UserPrincipalName $_ -BypassMFACheck};
                    $users = $presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.ExceptIfSentTo | Invoke-MonkeyJob @jobParam
                    If($null -ne $users){
                        ForEach($user in @($users)){
                            [void]$atpUsersexcluded.Add($user);
                        }
                    }
                }
                #Get ATP excluded groups
                If($presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.ExceptIfSentToMemberOf.Count -gt 0){
                    $new_arg = @{
                        APIVersion = 'v1.0';
                    }
                    $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroup -Filter "Mail eq '$_'"};
                    $jobParam.Arguments = $new_arg;
                    $groups = $presetSecurityPolicyObj.properties.atpProtectionPolicy.rule.ExceptIfSentToMemberOf | Invoke-MonkeyJob @jobParam
                    $groupIds = $groups | Select-Object -ExpandProperty Id -ErrorAction Ignore
                    If($null -ne $groupIds){
                        $jobParam.ScriptBlock = { Get-MonkeyMSGraphGroupTransitiveMember -GroupId $_ -Parents @($_)};
                        $groupMembers = $groupIds | Invoke-MonkeyJob @jobParam
                        If($null -ne $groupMembers){
                            ForEach($member in @($groupMembers)){
                                [void]$atpUsersexcluded.Add($member);
                            }
                        }
                    }
                }
            }
            Else{
                $presetSecurityPolicyObj.config.priorityAccountsProtectedByATP = $false
            }
            #Remove duplicates
            $atpUsersProtected = $atpUsersProtected | Select-Object -Unique -ExpandProperty Id -ErrorAction Ignore
            $atpUsersexcluded = $atpUsersexcluded | Select-Object -Unique -ExpandProperty Id -ErrorAction Ignore
            $eopUsersProtected = $eopUsersProtected | Select-Object -Unique -ExpandProperty Id -ErrorAction Ignore
            $eopUsersexcluded = $eopUsersexcluded | Select-Object -Unique -ExpandProperty Id -ErrorAction Ignore
            #Get Protected Users
            $protectedUsers = $presetSecurityPolicyObj.properties.protectedUsers | Select-Object -ExpandProperty Id -ErrorAction Ignore
            ForEach($user in @($protectedUsers)){
                IF($user -notin $eopUsersProtected){$presetSecurityPolicyObj.config.priorityAccountsProtectedByEOP = $false}
                IF($user -in $eopUsersexcluded){$presetSecurityPolicyObj.config.priorityAccountsProtectedByEOP = $false}
                IF($user -notin $atpUsersProtected){$presetSecurityPolicyObj.config.priorityAccountsProtectedByATP = $false}
                IF($user -in $atpUsersexcluded){$presetSecurityPolicyObj.config.priorityAccountsProtectedByATP = $false}
            }
        }
        Else{
            $presetSecurityPolicyObj.config.priorityAccountsProtectedByATP = $false
            $presetSecurityPolicyObj.config.priorityAccountsProtectedByEOP = $false
        }
        return $presetSecurityPolicyObj
    }
}

