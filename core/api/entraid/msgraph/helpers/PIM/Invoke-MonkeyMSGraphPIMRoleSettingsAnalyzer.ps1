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

Function Invoke-MonkeyMSGraphPIMRoleSettingsAnalyzer {
    <#
        .SYNOPSIS
		PIM Role settings analyzer

        .DESCRIPTION
		PIM Role settings analyzer

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyMSGraphPIMRoleSettingsAnalyzer
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Policy Object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "beta"
    )
    Begin{
        #Set args
        $new_arg = @{
            APIVersion = $APIVersion;
        }
        #Set job params
        $jobParam = @{
	        ScriptBlock = { Get-MonkeyMSGraphGroupTransitiveMember -GroupId $_ -Parents @($_)};
            Arguments = $new_arg;
	        Runspacepool = $O365Object.monkey_runspacePool;
	        ReuseRunspacePool = $true;
	        Debug = $O365Object.VerboseOptions.Debug;
	        Verbose = $O365Object.VerboseOptions.Verbose;
	        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	        BatchSize = $O365Object.nestedRunspaces.BatchSize;
        }
    }
    Process{
        Try{
            #Get numbers of approvals within unifiedRoleManagementPolicyApprovalRule
            $approval_rule = @($InputObject.settings).Where({$_.'@odata.type' -like '*unifiedRoleManagementPolicyApprovalRule*'},[System.Management.Automation.WhereOperatorSelectionMode]::First)
            If($approval_rule.Count -eq 1){
                $number_of_approvals = 0;
                #Get approvers
                $approvers = $approval_rule[0].setting.approvalStages[0].primaryApprovers;
                #Get Groups and users
                $groups = @($approvers).Where({$_.'@odata.type' -like '*groupMembers*'}) | Select-Object -ExpandProperty Id -ErrorAction Ignore
                $users = @($approvers).Where({$_.'@odata.type' -like '*singleUser*'}) | Select-Object -ExpandProperty Id -ErrorAction Ignore
                If($null -ne $users){
                    $number_of_approvals = @($users).Count;
                }
                If($null -ne $groups){
                    $members = $groups | Invoke-MonkeyJob @jobParam
                    If($null -ne $members){
                        $number_of_approvals += @($members).Count;
                    }
                }
                #Add to settings
                $approval_rule[0].setting.approvalStages[0] | Add-Member -MemberType NoteProperty -Name primaryApproversCount -Value $number_of_approvals -Force
            }
        }
        Catch{
            $msg = @{
			    MessageData = $_;
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
			    Tags = @('EntraIDPIMRoleSettingsAnalyzerError');
		    }
		    Write-Verbose @msg
        }
        #Return object
        return $InputObject
    }
    End{
        #Nothing to do here
    }
}
