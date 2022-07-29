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

Function Get-MonkeyPSFilePermission{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPSFilePermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Auth Object")]
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
        $param = @{
            Authentication = $Authentication;
            endpoint = $Endpoint;
            list = $List;
        }
        $raw_items = Get-MonkeySPSListItem @param
        if($null -ne $raw_items){
            #Get Items
            $all_items = $raw_items | Where-Object {$_.FileSystemObjectType -eq [FileSystemObjectType]::File -and ($_.FileLeafRef -ne "Forms") -and (-Not($_.FileLeafRef.StartsWith("_")))}
        }
        $vars = @{
            O365Object = $O365Object;
            WriteLog = $WriteLog;
            Verbosity = $Verbosity;
            InformationAction = $InformationAction;
        }
    }
    Process{
        if($null -ne $all_items){
            $all_params = @()
            foreach($item in $all_items){
                if($inherited){
                    $param = @{
                        Authentication = $Authentication;
                        endpoint = $Endpoint;
                        object = $item;
                    }
                    $all_params +=$param;
                }
                else{
                    #Check if the object has unique permissions
                    $param = @{
                        clientObject = $item;
                        properties = "HasUniqueRoleAssignments", "RoleAssignments";
                        Authentication = $Authentication;
                        endpoint = $Endpoint;
                        executeQuery = $True;
                    }
                    $permissions = Get-MonkeySPSProperty @param
                    if($null -ne $permissions){
                        #End get permissions assigned to the object
                        #Check if Object has unique permissions
                        if($permissions.HasUniqueRoleAssignments){
                            $param = @{
                                Authentication = $Authentication;
                                endpoint = $Endpoint;
                                object = $item;
                            }
                            $all_params +=$param;
                        }
                    }
                    else{
                        Write-Verbose ("Unable to get permissions for {0}" -f $item.Title)
                    }
                }
            }
            $localparams = @{
                ImportVariables = $vars;
                ImportModules = $O365Object.runspaces_modules;
                ImportCommands = $O365Object.LibUtils;
                StartUpScripts = $O365Object.runspace_init;
                ThrowOnRunspaceOpenError = $true;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
                Throttle = $O365Object.nestedRunspaceMaxThreads;
            }
            #Get runspace pool
            $runspacepool = New-RunspacePool @localparams
            if($null -ne $runspacepool -and $runspacepool -is [System.Management.Automation.Runspaces.RunspacePool]){
                $job_params = @{
                    ScriptBlock = {Get-MonkeyPSPermission -Authentication $_.Authentication -Endpoint $_.endpoint -object $_.object};
                    runspacepool = $runspacepool;
                    reuseRunspacePool = $true;
                    MaxQueue = $O365Object.MaxQueue;
                    BatchSleep = $O365Object.BatchSleep;
                    BatchSize = $O365Object.BatchSize;
                    Debug = $O365Object.VerboseOptions.Debug;
                    Verbose = $O365Object.VerboseOptions.Verbose;
                }
                $all_permissions = $all_params | Invoke-MonkeyJob @job_params
            }
            #Close runspacepool
            $runspacepool.Close()
            $runspacepool.Dispose()
            #collect garbage
            [gc]::Collect()
            <#
            $job_params = @{
                ScriptBlock = {Get-MonkeyPSPermission -Authentication $_.Authentication -Endpoint $_.endpoint -object $_.object};
                ImportCommands = $O365Object.LibUtils;
                ImportVariables = $vars;
                ImportModules = $O365Object.runspaces_modules;
                StartUpScripts = $O365Object.runspace_init;
                ThrowOnRunspaceOpenError = $true;
                Debug = $O365Object.VerboseOptions.Debug;
                Verbose = $O365Object.VerboseOptions.Verbose;
            }
            $all_permissions = $all_params | Invoke-MonkeyJob @job_params
            #>
        }
    }
    End{
        if($all_permissions){
            return $all_permissions
        }
    }
}
