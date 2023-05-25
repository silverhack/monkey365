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


Function Get-MonkeyCSOMFolderPermission{
    <#
        .SYNOPSIS
		Get Sharepoint Online folder permissions

        .DESCRIPTION
		Get Sharepoint Online folder permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMFolderPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, HelpMessage="List Items")]
        [Object]$ListItems,

        [Parameter(Mandatory= $false, HelpMessage="Sharepoint Endpoint")]
        [String]$Endpoint,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Begin{
        #Set generic list
        $folderPermissions = New-Object System.Collections.Generic.List[System.Object]
    }
    Process{
        #Get only folders
        $all_folders = $ListItems | Where-Object {$_.FileSystemObjectType -eq [FileSystemObjectType]::Folder -and ($_.FileLeafRef -ne "Forms") -and (-Not($_.FileLeafRef.StartsWith("_")))}
        if($all_folders){
            foreach($folder in @($all_folders)){
                if($folder.Title){
                    $title = $folder.Title
                }
                else{
                    $title = $folder.FileLeafRef
                }
                $msg = @{
                    MessageData = ($message.SPSFolderMessage -f $title);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('SPSFolderInformation');
                }
                Write-Information @msg
                $p = @{
                    Object = $folder;
                    Authentication = $Authentication;
                    Endpoint = $Endpoint;
                    IncludeInheritedPermission = $IncludeInheritedPermission;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $perms = Get-MonkeyCSOMObjectPermission @p
                if($perms){
                    #Add to list
                    foreach($perm in $perms){
                        [void]$folderPermissions.Add($perm)
                    }
                }
            }
        }
    }
    End{
        #return permissions
        return $folderPermissions
    }
}
