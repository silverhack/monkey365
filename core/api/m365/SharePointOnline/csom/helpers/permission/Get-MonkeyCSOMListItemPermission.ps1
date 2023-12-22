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


Function Get-MonkeyCSOMListItemPermission{
    <#
        .SYNOPSIS
		Get Sharepoint Online list item permissions

        .DESCRIPTION
		Get Sharepoint Online list item permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMListItemPermission
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
        #Get libs for runspace
        $rsOptions = Initialize-MonkeyScan -Provider Microsoft365 | Where-Object {$_.scanName -eq 'SharePointOnline'}
        $arg = @{
            Authentication = $Authentication;
            Endpoint = $Endpoint;
        }
        $job_params = @{
            Command = "Invoke-MonkeyCSOMPermission";
            Arguments = $arg;
            ImportCommands = $rsOptions.libCommands;
            ImportVariables = $O365Object.runspace_vars;
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
        <#
        $job_params = @{
            Command = "Invoke-MonkeyCSOMPermission";
            Arguments = $arg;
            Runspacepool = $O365Object.monkey_runspacePool;
			ReuseRunspacePool = $true;
			Debug = $O365Object.VerboseOptions.Debug;
			Verbose = $O365Object.VerboseOptions.Verbose;
			MaxQueue = $O365Object.MaxQueue;
			BatchSleep = $O365Object.BatchSleep;
			BatchSize = $O365Object.BatchSize;
            Throttle = $O365Object.nestedRunspaceMaxThreads;
        }
        #>
    }
    Process{
        #Get only items
        $all_items = $ListItems | Where-Object {$_.FileSystemObjectType -eq [FileSystemObjectType]::File -and ($_.FileLeafRef -ne "Forms") -and (-Not($_.FileLeafRef.StartsWith("_")))}
        if($all_items){
            if($PSBoundParameters.ContainsKey('IncludeInheritedPermission') -and $PSBoundParameters.IncludeInheritedPermission){
                $all_items | Invoke-MonkeyJob @job_params
            }
            else{
                foreach($item in @($all_items)){
                    #Check if web has direct permissions
                    $p = @{
                        ClientObject = $item;
                        Properties = "HasUniqueRoleAssignments";
                        Authentication = $Authentication;
                        Endpoint = $Endpoint;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $role = Get-MonkeyCSOMProperty @p
                    if($null -ne $role -and $role.HasUniqueRoleAssignments){
                        $p = @{
                            Object = $item;
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $objectType =  Get-MonkeyCSOMObjectType @p
                        $msg = @{
                            MessageData = ($message.SPSPermissionInfoMessage -f $objectType.ObjectPath, $objectType.ObjectType);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'info';
                            InformationAction = $O365Object.InformationAction;
                            Tags = @('SPSPermissionMessage');
                        }
                        Write-Information @msg
                        #Add to list
                        Invoke-MonkeyJob @job_params -InputObject $item
                        continue
                    }
                }
            }
        }
    }
    End{
        #Nothing to do here
    }
}
