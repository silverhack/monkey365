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


Function Get-MonkeyCSOMListPermission{
    <#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online list item permissions

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online list item permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMListPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, HelpMessage="Sharepoint Web Object")]
        [Object]$Web,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Begin{
        #Set generic list
        $listPermissions = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
    }
    Process{
        #Check for objectType
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            #Get all lists
            $p = @{
                Authentication = $Authentication;
                Web = $Web;
                ExcludeInternalLists = $true;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $all_lists = Get-MonkeyCSOMList @p
            foreach($list in @($all_lists)){
                $p = @{
                    Object = $list;
                    Authentication = $Authentication;
                    Endpoint = $Web.Url;
                    IncludeInheritedPermission = $IncludeInheritedPermission;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $perms = Get-MonkeyCSOMObjectPermission @p
                if($perms){
                    #Add to list
                    foreach($perm in $perms){
                        [void]$listPermissions.Add($perm)
                    }
                }
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SPOInvalieWebObjectMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $InformationAction;
                Tags = @('SPOInvalidWebObject');
            }
            Write-Warning @msg
            break;
        }
    }
    End{
        #return permissions
        return , $listPermissions
    }
}
