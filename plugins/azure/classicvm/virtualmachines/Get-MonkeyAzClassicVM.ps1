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


Function Get-MonkeyAzClassicVM{
    <#
        .SYNOPSIS
		Plugin to get classic VMs from Azure

        .DESCRIPTION
		Plugin to get classic VMs from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzClassicVM
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
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        #Get Classic VMs
        $classic_vms = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.ClassicCompute/virtualMachines'}
        if(-NOT $classic_vms){continue}
        #Get config
        $AzureClassicVMConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureClassicVM"} | Select-Object -ExpandProperty resource
        #Set array
        $AllClassicVM = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure virtual machine", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureVMInfo');
        }
        Write-Information @msg
        if($classic_vms){
            foreach($classic_vm in $classic_vms){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $classic_vm.name, 'virtual machine');
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureVMInfoMessage');
                }
                Write-Information @msg
                #Construct URI
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager, `
                            $classic_vm.id,$AzureClassicVMConfig.api_version)
                #launch request
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $vm = Get-MonkeyRMObject @params
                if($vm.id){
                    #Check for antimalware
                    $av = $vm | Where-Object {$_.properties.extensions.extension -match "IaaSAntimalware" -and $_.properties.storageProfile.operatingSystemDisk.operatingSystem -eq "Windows"}
                    if($av){
                        $vm | Add-Member -type NoteProperty -name antimalwareAgent -value $true
                    }
                    else{
                        $vm | Add-Member -type NoteProperty -name antimalwareAgent -value $false
                    }
                    #Check for installed agent
                    $agent = $vm | Where-Object {$_.properties.extensions.extension -match "MicrosoftMonitoringAgent" -or $_.resources.id -match "OmsAgentForLinux"}
                    if($agent){
                        $vm | Add-Member -type NoteProperty -name vmagentinstalled -value $true
                    }
                    else{
                        $vm | Add-Member -type NoteProperty -name vmagentinstalled -value $false
                    }
                    #Check for diagnostic agent
                    $agent = $vm | Where-Object {$_.properties.extensions.extension -match "IaaSDiagnostics" -or $_.resources.id -match "OmsAgentForLinux"}
                    if($agent){
                        $vm | Add-Member -type NoteProperty -name diagnosticagentinstalled -value $true
                    }
                    else{
                        $vm | Add-Member -type NoteProperty -name diagnosticagentinstalled -value $false
                    }
                    #Add encryption settings
                    $vm | Add-Member -type NoteProperty -name encryptionsettingsenabled -value "notsupported"
                    #Add to list
                    $AllClassicVM+=$vm
                }
            }
        }
    }
    End{
        if($AllClassicVM){
            $AllClassicVM.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ClassicVM')
            [pscustomobject]$obj = @{
                Data = $AllClassicVM
            }
            $returnData.az_classic_vm = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure virtual machine", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureClassicVMEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
