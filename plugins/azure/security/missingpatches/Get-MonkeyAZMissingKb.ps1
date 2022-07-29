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


Function Get-MonkeyAZMissingKb{
    <#
        .SYNOPSIS
		Plugin to get information regarding missing patches from Azure

        .DESCRIPTION
		Plugin to get information regarding missing patches from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZMissingKb
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
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure RM Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Config
        $AzureSecStatus = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureSecurityStatuses"} | Select-Object -ExpandProperty resource
        #Get VMs
        $vms_v2 = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Compute/virtualMachines'}
        $classic_vms = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.ClassicCompute/virtualMachines'}
        if(-NOT $vms_v2 -and -NOT $classic_vms){continue}
        #create synchronized array
        $AllMissingPatches = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        #Generate vars
        $vars = @{
            "O365Object"=$O365Object;
            "WriteLog"=$WriteLog;
            'Verbosity' = $Verbosity;
            'InformationAction' = $InformationAction;
            "AllMissingPatches"=$AllMissingPatches;
        }
    }
    Process{
        if($null -ne $vms_v2 -or $null -ne $classic_vms){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Missing Patches", $O365Object.current_subscription.DisplayName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('AzureMissingPatchesInfo');
            }
            Write-Information @msg
            #List all VMs
            $params = @{
                Authentication = $rm_auth;
                Provider = $AzureSecStatus.provider;
                ObjectType = "securityStatuses";
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $AzureSecStatus.api_version;
            }
            $TmpStatus = Get-MonkeyRMObject @params
            $all_vm_status = $TmpStatus | Where-Object {$_.properties.type -eq 'VirtualMachine' -or $_.properties.type -eq 'ClassicVirtualMachine'}
            #Set array
            $all_vms = @()
            foreach($vm in $vms_v2){
                $vm_rm = $all_vm_status | Where-Object {$_.name -eq $vm.name}
                if($vm_rm){
                    $all_vms+=$vm_rm
                }
            }
            foreach($vm in $classic_vms){
                $classic = $all_vm_status | Where-Object {$_.name -eq $vm.name}
                if($classic){
                    $all_vms+=$classic
                }
            }
            if($all_vms){
                $param = @{
                    ScriptBlock = {Get-MonkeyAzMissingPatchesForVM -vm $_};
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
                $all_vms | Invoke-MonkeyJob @param
            }
        }
    }
    End{
        if($AllMissingPatches){
            $AllMissingPatches.PSObject.TypeNames.Insert(0,'Monkey365.Azure.MissingPatches')
            [pscustomobject]$obj = @{
                Data = $AllMissingPatches
            }
            $returnData.az_vm_missing_patches = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Missing patches", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureMissingPatchesEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
