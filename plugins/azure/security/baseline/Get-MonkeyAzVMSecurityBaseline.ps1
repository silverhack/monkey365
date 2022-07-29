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


Function Get-MonkeyAZSecurityBaseline{
    <#
        .SYNOPSIS
		Plugin to get about Security Baseline from Azure

        .DESCRIPTION
		Plugin to get about Security Baseline from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZSecurityBaseline
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
        #get Config
        $AzureSecStatus = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureSecurityStatuses"} | Select-Object -ExpandProperty resource
        #Get VMs
        $vms_v2 = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.Compute/virtualMachines'}
        $classic_vms = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.ClassicCompute/virtualMachines'}
        if(-NOT $vms_v2 -and -NOT $classic_vms){continue}
        #create synchronized array
        $AllSecBaseline = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
        #Generate vars
        $vars = @{
            "O365Object"=$O365Object;
            "WriteLog"=$WriteLog;
            'Verbosity' = $Verbosity;
            'InformationAction' = $InformationAction;
            "AllSecBaseline"=$AllSecBaseline;
        }
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure security baseline", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureSecurityBaselineInfo');
        }
        Write-Information @msg
        #Get all security statuses
        $params = @{
            Authentication = $rm_auth;
            Provider = $AzureSecStatus.provider;
            ObjectType = "securityStatuses";
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = $AzureSecStatus.api_version;
        }
        $all_status = Get-MonkeyRMObject @params
        $all_vm_status = $all_status | Where-Object {$_.properties.type -like '*VirtualMachine'}
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
        #Get primary object
        if($all_vms){
            $param = @{
                ScriptBlock = {Get-AzVmSecurityBaseline -vm $_};
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
    End{
        if($AllSecBaseline){
            $AllSecBaseline.PSObject.TypeNames.Insert(0,'Monkey365.Azure.SecurityBaseline')
            [pscustomobject]$obj = @{
                Data = $AllSecBaseline
            }
            $returnData.az_vm_security_baseline = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Security Baseline", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureSecBaselineEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
