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

Function Get-MonkeyPSFolderPermission{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPSFolderPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $true, HelpMessage="List Object")]
        [Object]$List,

        [Parameter(Mandatory= $true, HelpMessage="Sharepoint Endpoint")]
        [String]$Endpoint
    )
    Begin{
        #Get switchs
        $inherited = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.SitePermissions.IncludeInheritedPermissions)
        #Set null
        $all_permissions = @()
        $Folders = $null
        $param = @{
            Authentication = $Authentication;
            endpoint = $Endpoint;
            list = $List;
        }
        $raw_items = Get-MonkeySPSListItem @param
        if($null -ne $raw_items){
            #Get Folders
            $Folders = $raw_items | Where-Object {$_.FileSystemObjectType -eq [FileSystemObjectType]::Folder -and ($_.FileLeafRef -ne "Forms") -and (-Not($_.FileLeafRef.StartsWith("_")))}
        }
    }
    Process{
        if($null -ne $Folders){
            foreach($folder in $Folders){
                if($folder.Title){
                    $Title = $folder.Title
                }
                else{
                    $Title = $folder.FileLeafRef
                }
                $msg = @{
                    MessageData = ($message.SPSFolderMessage -f $Title);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('SPSFolderInformation');
                }
                Write-Information @msg
                if($Inherited){
                    $msg = @{
                        MessageData = ($message.SPSInheritedPermsMessage -f $Title);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('SPSFolderInformation');
                    }
                    Write-Information @msg
                    $param = @{
                        Authentication = $Authentication;
                        endpoint = $Endpoint;
                        object = $folder;
                    }
                    $all_permissions += Get-MonkeyPSPermission @param
                }
                else{
                    #Check if the Web has unique permissions
                    $param = @{
                        clientObject = $folder;
                        properties = "HasUniqueRoleAssignments", "RoleAssignments";
                        Authentication = $Authentication;
                        endpoint = $Endpoint;
                        executeQuery = $True;
                    }
                    $permissions = Get-MonkeySPSProperty @param
                    if($null -ne $permissions){
                        #Check if Object has unique permissions
                        if($permissions.HasUniqueRoleAssignments){
                            $msg = @{
                                MessageData = ($message.SPSUniquePermsMessage -f $Title);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'info';
                                InformationAction = $InformationAction;
                                Tags = @('SPSFolderUniquePermissionsInformation');
                            }
                            Write-Information @msg
                            $param = @{
                                Authentication = $Authentication;
                                endpoint = $Endpoint;
                                object = $folder;
                            }
                        }
                        $all_permissions += Get-MonkeyPSPermission @param
                    }
                }
            }
        }
    }
    End{
        if($all_permissions){
            return $all_permissions
        }
    }
}
