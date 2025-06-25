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

Function Get-MonkeyMSPIMRoleDefinition {
    <#
        .SYNOPSIS
		Get role definition from PIM

        .DESCRIPTION
		Get role definition from PIM

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
	Param ()
    Begin{
        $Environment = $O365Object.Environment
        #Get PIM Auth
        $PIMAuth = $O365Object.auth_tokens.MSPIM
    }
    Process{
        $Select = 'id,displayName,type,templateId,resourceId,externalId,isbuiltIn,subjectCount,eligibleAssignmentCount,activeAssignmentCount'
        #Set params
        $params = @{
            Authentication = $PIMAuth;
            Environment = $Environment;
            InternalPath = 'privilegedAccess';
            Resource = 'aadroles';
            ObjectType = 'roleDefinitions';
            Select = $Select;
            OrderBy = 'displayName'
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
