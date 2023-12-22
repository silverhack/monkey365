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

Function Get-MonkeyMSGraphAADRoleAssignment {
    <#
        .SYNOPSIS
		Get Azure AD role assignment

        .DESCRIPTION
		Get Azure AD role assignment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        #Get Roles and expand the Principal attribute
        $params = @{
	        Authentication = $graphAuth;
	        ObjectType = "roleManagement/directory/roleAssignments";
	        Environment = $Environment;
            Expand = 'Principal';
	        ContentType = 'application/json';
	        Method = "GET";
	        APIVersion = $APIVersion;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $role_assignments = Get-MonkeyMSGraphObject @params
        #Get Roles and expand the roleDefinition attribute
        $params.Expand = 'roleDefinition';
        $role_definitions = Get-MonkeyMSGraphObject @params
        #Populate all role definitions
        if($role_assignments -and $role_definitions){
            foreach ($role in $role_assignments){
                $role_definition = $role_definitions | Where-Object {$_.id -eq $role.id} | Select-Object -ExpandProperty roleDefinition
                if($null -ne $role_definition){
                    $role | Add-Member -type NoteProperty -name roleDefinition -value $role_definition -Force
                }
                #Count principals
                $role | Add-Member -type NoteProperty -name members -value (@($role.principal).Count) -Force
            }
        }
        #Return role assignments
        return $role_assignments
    }
    End{
        #Nothing to do here
    }
}