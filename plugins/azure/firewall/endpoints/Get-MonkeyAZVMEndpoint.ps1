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


Function Get-MonkeyAZVMEndpoint{
    <#
        .SYNOPSIS
		Plugin to get information regarding EndPoints from Azure

        .DESCRIPTION
		Plugin to get information regarding EndPoints from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAZVMEndpoint
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
        #Get Config
        $AzureClassicVMConfig = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureClassicVM"} | Select-Object -ExpandProperty resource
        #Get Classic VMs
        $classic_vms = $O365Object.all_resources | Where-Object {$_.type -like 'Microsoft.ClassicCompute/virtualMachines'}
        if(-NOT $classic_vms){continue}
        #Set Array
        $all_classic_endpoints = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure classic VMs Endpoints", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureEndpointsInfo');
        }
        Write-Information @msg
        if($classic_vms){
            foreach($classic_vm in $classic_vms){
                $msg = @{
                    MessageData = ($message.AzureUnitResourceMessage -f $classic_vm.name, "classic virtual machine");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('AzureDocumentDBServerInfo');
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
                    $endpoints = $vm.properties.networkProfile.inputEndpoints
                    foreach ($Endpoint in $Endpoints){
                        $new_classic_endpoint = New-Object -TypeName PSCustomObject
                        $new_classic_endpoint | Add-Member -type NoteProperty -name VMName -value $VM.name
                        $new_classic_endpoint | Add-Member -type NoteProperty -name EndPointName -value $EndPoint.EndPointName
                        $new_classic_endpoint | Add-Member -type NoteProperty -name publicIpAddress -value $EndPoint.publicIpAddress
                        $new_classic_endpoint | Add-Member -type NoteProperty -name privatePort -value $EndPoint.privatePort
                        $new_classic_endpoint | Add-Member -type NoteProperty -name publicPort -value $EndPoint.publicPort
                        $new_classic_endpoint | Add-Member -type NoteProperty -name protocol -value $EndPoint.protocol
                        $new_classic_endpoint | Add-Member -type NoteProperty -name enableDirectServerReturn -value $EndPoint.enableDirectServerReturn
                        #Add to array
                        $all_classic_endpoints+=$new_classic_endpoint
                    }
                }
            }
        }
    }
    End{
        if($all_classic_endpoints){
            $all_classic_endpoints.PSObject.TypeNames.Insert(0,'Monkey365.Azure.classic.endpoints')
            [pscustomobject]$obj = @{
                Data = $all_classic_endpoints
            }
            $returnData.az_classic_endpoints = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure classic vm endpoints", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureClassicVMEndpointEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
