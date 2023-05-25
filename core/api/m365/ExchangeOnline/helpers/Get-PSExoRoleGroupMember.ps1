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

Function Get-PSExoRoleGroupMember{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSExoRoleGroupMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, position=0, HelpMessage="role group")]
        [object]$role,

        [Parameter(Mandatory=$True, ValueFromPipeline=$true, position=0, HelpMessage="return role Object")]
        [Switch]$asObject
    )
    Begin{
        #Getting environment
        $Environment = $O365Object.Environment
        #Get Exo authentication
        $exo_auth = $O365Object.auth_tokens.ExchangeOnline
        #Set var with null
        $new_role = $null
    }
    Process{
        #Get role group members
        $objectType = ("ExchangeRoleGroupMember('{0}')" -f $role.id)
        $param = @{
            Authentication = $exo_auth;
            Environment = $Environment;
            ObjectType = $objectType;
            ExtraParameters = "PropertySet=All";
            Method = "GET";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $members = Get-PSExoAdminApiObject @param
        if($asObject){
            if($members){
                $role | Add-Member -type NoteProperty -name Members -Value $members
            }
            else{
                $role | Add-Member -type NoteProperty -name Members -Value $null
            }
            $new_role = $role;
        }
        else{
            $new_role = $members
        }
    }
    End{
        if($null -ne $new_role){
            return $new_role
        }
    }
}
