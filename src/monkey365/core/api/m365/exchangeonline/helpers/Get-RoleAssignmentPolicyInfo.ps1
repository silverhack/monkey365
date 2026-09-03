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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function Get-RoleAssignmentPolicyInfo{
    <#
        .SYNOPSIS
        Get Role Assignment Policy information from Exchange Online

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-RoleAssignmentPolicyInfo
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PsObject]])]
    Param()
    Begin{
        #Get excluded roles from configuration file
        Try{
            $excludedRoles = $O365Object.internal_config.o365.ExchangeOnline.userRoleAssignmentPolicy.excludedRoles;
        }
        Catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('ExoRoleAssignmentPolicyError');
            }
            Write-Verbose @msg
            $excludedRoles = $null;
        }
        #Get instance
        $Environment = $O365Object.Environment
        #Get Exchange Online Auth token
        $ExoAuth = $O365Object.auth_tokens.ExchangeOnline
        #Set array
        $roleAssignmentPolicies = [System.Collections.Generic.List[System.Management.Automation.PsObject]]::new()
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
    }
    Process{
        If($null -ne $ExoAuth){
            $msg = @{
                MessageData = "Getting Role Assignment Policies";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('M365RoleAssignmentPolicyInfo');
            }
            Write-Information @msg
            #Get Role Assignment Policy
            $p.Command = 'Get-RoleAssignmentPolicy';
            $rap = Get-PSExoAdminApiObject @p
            ForEach($_rap in @($rap)){
                #Set PsObject
                $rapObj = [PsCustomObject]@{
                    id = $_rap.ExchangeObjectId.Guid;
                    identity = $_rap.Identity;
                    name = $_rap.Name;
                    description = $_rap.Description;
                    isDefault = $_rap.IsDefault;
                    isValid = $_rap.IsValid;
                    compliant = $null;
                    nonCompliantRoles = [System.Collections.Generic.List[System.String]]::new();
                    policy = $_rap;
                }
                If($null -ne $excludedRoles){
                    $p = @{
                        ReferenceObject = $_rap.AssignedRoles;
                        DifferenceObject = $excludedRoles;
                        IncludeEqual = $true;
                    }
                    $result = Compare-Object @p | Where-Object {$_.SideIndicator -eq "=="} | Select-Object -ExpandProperty InputObject -ErrorAction Ignore;
                    If($null -ne $result){
                        $rapObj.compliant = $false;
                        ForEach($_result in @($result)){
                            [void]$rapObj.nonCompliantRoles.Add($_result);
                        }
                    }
                    Else{
                        $rapObj.compliant = $true;
                    }
                }
                Else{
                    $rapObj.compliant = 'Unknown';
                }
                #Add obj
                [void]$roleAssignmentPolicies.Add($rapObj);
            }
        }
        Else{
            $msg = @{
                MessageData = ($message.NoPsSessionWasFound -f "RoleAssignmentPolicy");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('ExoRoleAssignmentPolicyInfo');
            }
            Write-Warning @msg
        }
    }
    End{
        return $roleAssignmentPolicies
    }
}

