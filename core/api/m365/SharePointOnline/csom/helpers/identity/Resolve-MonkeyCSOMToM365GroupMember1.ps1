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

Function Resolve-MonkeyCSOMToM365GroupMemberOld{
    <#
        .SYNOPSIS
        Get group members from Microsoft 365

        .DESCRIPTION

        Get group members from Microsoft 365

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-MonkeyCSOMToM365GroupMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$True, HelpMessage="Group Id")]
        [Object]$Groups
    )
    Process{
        foreach($grp in @($Groups)){
            #Check if Admin group
            try{
                $GroupId = $grp.LoginName.Split('|')[2]
            }
            catch{
                $GroupId = $null
            }
            if($null -ne $GroupId -and $GroupId.Length -gt 36 -and $GroupId.Substring(36, 2) -eq "_o"){
                $GroupId = $GroupId.Split('_')[0]
                #Get group owners
                $p = @{
                    GroupId = $GroupId;
                    Expand = 'Owners';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $Group = Get-MonkeyMSGraphGroup @p
                if($null -ne $Group){
                    $grp | Add-Member NoteProperty -name Members -value $Group.owners
                }
            }
            elseIf ($null -ne $GroupId -and $grp.PrincipalType -eq 4 -and ($grp.LoginName -like '*federateddirectoryclaimprovider*')){
                #Get group members
                $p = @{
                    GroupId = $GroupId;
                    Expand = 'members';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $Group = Get-MonkeyMSGraphGroup @p
                if($null -ne $Group){
                    $grp | Add-Member NoteProperty -name Members -value $Group.members
                }
            }
        }
    }
    End{
        return $Groups
    }
}


