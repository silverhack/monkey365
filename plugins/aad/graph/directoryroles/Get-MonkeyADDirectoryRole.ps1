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



Function Get-MonkeyADDirectoryRole{
    <#
        .SYNOPSIS
		Plugin to get Directoryroles from Azure AD
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .DESCRIPTION
		Plugin to get Directoryroles from Azure AD
        https://docs.microsoft.com/en-us/azure/active-directory/active-directory-assign-admin-roles

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyADDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
            [String]$pluginId
    )
    Begin{
        $tmp_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        $all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        $AADConfig = $O365Object.internal_config.azuread
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        $TmpDirectoryRoles = @()
        #Generate vars
        $vars = @{
            "O365Object"=$O365Object;
            "WriteLog"=$WriteLog;
            'Verbosity' = $Verbosity;
            'InformationAction' = $InformationAction;
            "all_users"=$tmp_users;
        }
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure AD Directory Roles", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphDirectoryRoles');
        }
        Write-Information @msg
        #Get Directory roles
        $params = @{
            Authentication = $AADAuth;
            ObjectType = "directoryRoles";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AADConfig.api_version;
        }
        $directory_roles = Get-MonkeyGraphObject @params
        if ($directory_roles){
            $msg = @{
                MessageData = ($message.MonkeyResponseCountMessage -f $directory_roles.Count);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphDirectoryRolesCount');
            }
            Write-Information @msg
            foreach ($dr in $directory_roles){
                $params = @{
                    Authentication = $AADAuth;
                    ObjectType = "directoryRoles";
                    ObjectId = $dr.objectId;
                    Relationship = 'members';
                    ObjectDisplayName = $dr.displayName;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $AADConfig.api_version;
                }
                $users_count = Get-MonkeyGraphLinkedObject @params -GetLinks
                if($users_count.url){
                    $dr | Add-Member -type NoteProperty -name Members -Value $users_count.url.Count
                }
                else{
                    $dr | Add-Member -type NoteProperty -name Members -Value 0
                }
                $TmpDirectoryRoles+=$dr
                #Getting users from Directory roles
                $params = @{
                    Authentication = $AADAuth;
                    ObjectType = "directoryRoles";
                    ObjectId = $dr.objectId;
                    Relationship = 'members';
                    ObjectDisplayName = $dr.displayName;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $AADConfig.api_version;
                }
                $Users = Get-MonkeyGraphLinkedObject @params
                #Add to Array
                if($Users){
                    $param = @{
                        ScriptBlock = {Get-AADDetailedUser -user $_};
                        ImportCommands = $O365Object.LibUtils;
                        ImportVariables = $vars;
                        ImportModules = $O365Object.runspaces_modules;
                        StartUpScripts = $O365Object.runspace_init;
                        ThrowOnRunspaceOpenError = $true;
                        Debug = $O365Object.VerboseOptions.Debug;
                        Verbose = $O365Object.VerboseOptions.Verbose;
                        Throttle = $O365Object.nestedRunspaceMaxThreads;
                        MaxQueue = $O365Object.MaxQueue;
                        BatchSleep = $O365Object.BatchSleep;
                        BatchSize = $O365Object.BatchSize;
                    }
                    $Users | Invoke-MonkeyJob @param | ForEach-Object {
                        if($_){
                            $_ | Add-Member -type NoteProperty -name MemberOf -Value $dr.displayName -Force
                            $_ | Add-Member -type NoteProperty -name MemberOfDescription -Value $dr.description -Force
                            $_ | Add-Member -type NoteProperty -name roleTemplateId -Value $dr.roleTemplateId -Force
                            [void]$all_users.Add($_)
                        }
                    }
                    <#
                    if($tmp_users){
                        $tmp_users |ForEach-Object {$_ | Add-Member -type NoteProperty -name MemberOf -Value $dr.displayName -Force}
                        #$tmp_users = $tmp_users | Select-Object $AADConfig.DirectoryRolesFilter
                        $tmp_users = $tmp_users | Where-Object {$null -ne $_.objectId}
                        $DirectoryRolesUsers+=$tmp_users
                    }
                    #>
                    #Set new array
                    #$vars.all_users = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
                    #$Users |ForEach-Object {$_ | Add-Member -type NoteProperty -name MemberOf -Value $dr.displayName}
                    #$Users = $Users | Select-Object $AADConfig.DirectoryRolesFilter
                    #$Users = $Users | Where-Object {$null -ne $_.objectId}
                    #$DirectoryRolesUsers+=$Users
                }
            }
        }
    }
    End{
        if($TmpDirectoryRoles){
            $TmpDirectoryRoles.PSObject.TypeNames.Insert(0,'Monkey365.AzureAD.DirectoryRoles')
            [pscustomobject]$obj = @{
                Data = $TmpDirectoryRoles
            }
            $returnData.aad_directory_roles = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Directory roles", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphUsersEmptyResponse');
            }
            Write-Warning @msg
        }
        if($all_users){
            [pscustomobject]$obj = @{
                Data = $all_users
            }
            $returnData.aad_directory_user_roles = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Directory user roles", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureGraphUsersEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
