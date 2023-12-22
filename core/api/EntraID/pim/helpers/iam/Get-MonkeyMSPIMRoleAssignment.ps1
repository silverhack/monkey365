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

Function Get-MonkeyMSPIMRoleAssignment {
    <#
        .SYNOPSIS
		Get role assignment from PIM

        .DESCRIPTION
		Get role assignment from PIM

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSPIMRoleDefinition
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, HelpMessage="Role definition Id")]
        [String]$RoleDefinitionId,

        [parameter(Mandatory=$False, HelpMessage="Assignment type")]
        [ValidateSet("Eligible","Active")]
        [String]$AssignmentType = "Active"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get PIM Auth
        $PIMAuth = $O365Object.auth_tokens.MSPIM
    }
    Process{
        switch ($AssignmentType) {
            'Active'{
                $expand = 'linkedEligibleRoleAssignment,subject,scopedResource,roleDefinition($expand=resource)'
                $filter = ("(roleDefinition/resource/id eq '{0}') and (roleDefinition/id eq '{1}') and (assignmentState eq 'Active')" -f $O365Object.TenantId, $RoleDefinitionId)
            }
            'Eligible'{
                $expand = 'linkedEligibleRoleAssignment,subject,scopedResource,roleDefinition($expand=resource)'
                $filter = ("(roleDefinition/resource/id eq '{0}') and (roleDefinition/id eq '{1}') and (assignmentState eq 'Eligible')" -f $O365Object.TenantId, $RoleDefinitionId)
            }
            Default {
                $expand = 'linkedEligibleRoleAssignment,subject,scopedResource,roleDefinition($expand=resource)'
                $filter = ("(roleDefinition/resource/id eq '{0}') and (roleDefinition/id eq '{1}') and (assignmentState eq 'Active')" -f $O365Object.TenantId, $RoleDefinitionId)
            }
        }
        #Set params
        $params = @{
            Authentication = $PIMAuth;
            Environment = $Environment;
            InternalPath = 'privilegedAccess';
            Resource = 'aadroles';
            ObjectType = 'roleAssignments';
            Filter = $filter;
            Expand = $expand;
            Count = $True;
            OrderBy = 'roleDefinition/displayName'
            ContentType = 'application/json';
            Method = "GET";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        Get-MonkeyMSPIMObject @params
    }
    End{
        #Nothing to do here
    }
}