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

Function Invoke-PriorityAccountConfig{
    <#
        .SYNOPSIS
        Get information about priority account protection feature

        .DESCRIPTION

        .INPUTS

        .OUTPUTS
        PsCustomObject with information about priority accounts

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-PriorityAccountConfig
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    Begin{
        #Get instance
        $Environment = $O365Object.Environment;
        #Get Purview Auth token
        $purviewAuth = $O365Object.auth_tokens.ComplianceCenter;
        #Get Purview backend Uri
		$Uri = $O365Object.SecCompBackendUri;
        #Checi if Exchange Online Auth is present, and if not, use token from Purview
        If($null -ne $O365Object.auth_tokens.ExchangeOnline){
            $exoAuth = $O365Object.auth_tokens.ExchangeOnline;
        }
        Else{
            $exoAuth = $O365Object.auth_tokens.ComplianceCenter;
        }
        #Set PsObject
        $priorityObj = [PsCustomObject]@{
            properties = [PsCustomObject]@{
                Id = $null;
                emailTenantSettings = $null;
                protectedUsers = [System.Collections.Generic.List[System.Object]]::new();
                alertPolicies = [System.Collections.Generic.List[System.Object]]::new();
            }
            config = [PsCustomObject]@{
                priorityAccountProtectionEnabled = $false;
                protectedUsers = $false;
                phishAlertPolicy = [PsCustomObject]@{
                    policy = $null;
                    enabled = $false;
                };
                malwareAlertPolicy = [PsCustomObject]@{
                    policy = $null;
                    enabled = $false;
                };
                presetSecurityPolicy = [PsCustomObject]@{
                    protectionType = $null;
                    priorityAccountsProtectedByEOP = $true;
                    priorityAccountsProtectedByATP = $true;
                }
            }
        }
        $msg = @{
            MessageData = "Getting Priority Account Protection Configuration";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365PriorityAccountInfo');
        }
        Write-Information @msg
    }
    Process{
        #Get Email tenant settings
        $p = @{
			Authentication = $exoAuth;
			Environment = $Environment;
			ResponseFormat = 'clixml';
			Command = 'Get-EmailTenantSettings';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
        $msg = @{
            MessageData = "Getting email tenant settings";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365PriorityAccountInfo');
        }
        Write-Information @msg
		$priorityObj.properties.emailTenantSettings = Get-PSExoAdminApiObject @p
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
                $priorityObj.properties.protectedUsers.Add($user);
            }
        }
        #Get alert policies
        $p = @{
			Authentication = $purviewAuth;
			EndPoint = $Uri;
			ResponseFormat = 'clixml';
			Command = 'Get-ProtectionAlert';
			Method = "POST";
			InformationAction = $O365Object.InformationAction;
			Verbose = $O365Object.Verbose;
			Debug = $O365Object.Debug;
		}
        $msg = @{
            MessageData = "Getting alert policies";
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $O365Object.InformationAction;
            Tags = @('M365PriorityAccountInfo');
        }
        Write-Information @msg
        $alertPolicies = Get-PSExoAdminApiObject @p
        If($null -ne $alertPolicies){
            $priorityObj.properties.alertPolicies = @($alertPolicies).Where({$_.IsSystemRule -eq $false});
        }
    }
    End{
        #Check if Priority Account is enabled at tenant level
        If($null -ne $priorityObj.properties.emailTenantSettings){
            $priorityObj.config.priorityAccountProtectionEnabled = $priorityObj.properties.emailTenantSettings.EnablePriorityAccountProtection;
            $priorityObj.properties.Id = $priorityObj.properties.emailTenantSettings | Select-Object -ExpandProperty Id -ErrorAction Ignore
        }
        #Check if protected users are present
        If($null -ne $priorityObject.properties.protectedUsers){
            $priorityObj.config.protectedUsers = $true;
        }
        #Iterate to each Phish and Malware alert policies
        If($null -ne $priorityObject.properties.alertPolicies){
            $policies = @($priorityObject.properties.alertPolicies).Where({
                $_.Disabled -eq $false -and `
                $_.Severity -in @('High','Medium') -and `
                $_.Mode -eq "Enforce" -and `
                $_.RecipientTags -eq 'Priority account' -and `
                $_.ThreatType -in @('Phish','Malware')}
            );
            ForEach($policy in $policies){
                Switch($policy.ThreatType.ToLower()){
                    'malware'{
                        If($policy.Filter -like "*(Mail.Direction -eq 'Inbound')*" -or $policy.Filter -like "*(Mail.Direction -eq 'ToInternalRecipient')*"){
                            $priorityObj.config.malwareAlertPolicy.enabled = $true;
                            $priorityObj.config.malwareAlertPolicy.policy = $policy;
                        }
                    }
                    'phish'{
                        If($policy.Filter -like "*(Mail.IsSystemZap -eq '0')*" -and ($policy.Filter -like "*(Mail.Direction -eq 'Inbound')*" -or $policy.Filter -like "*(Mail.AntispamDirection -eq 'ToInternalRecipient')*")){
                            $priorityObj.config.phishAlertPolicy.enabled = $true;
                            $priorityObj.config.phishAlertPolicy.policy = $policy;
                        }
                    }
                }
            }
        }
        #Get Preset security policies
        $presetSecurityInfo = Invoke-StrictPolicyForPriorityAccount
        If($null -ne $presetSecurityInfo){
            $priorityObj.config.presetSecurityPolicy.protectionType = $presetSecurityInfo.config.protectionType;
            $priorityObj.config.presetSecurityPolicy.priorityAccountsProtectedByATP = $presetSecurityInfo.config.priorityAccountsProtectedByATP;
            $priorityObj.config.presetSecurityPolicy.priorityAccountsProtectedByATP = $presetSecurityInfo.config.priorityAccountsProtectedByEOP;
        }
        #return object
        return $priorityObj
    }
}

