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



Function Get-MonkeyAzContainerRegistry{
    <#
        .SYNOPSIS
		Plugin to get Azure Container registry
        https://docs.microsoft.com/en-us/rest/api/containerregistry

        .DESCRIPTION
		Plugin to get Azure Container registry
        https://docs.microsoft.com/en-us/rest/api/containerregistry

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzContainerRegistry
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
        $cntRegistryAPI = $O365Object.internal_config.resourceManager | Where-Object {$_.name -eq "azureContainerRegistry"} | Select-Object -ExpandProperty resource
        #Get container registries
        $container_registries = $O365Object.all_resources | Where-Object {$_.type -eq 'Microsoft.ContainerRegistry/registries'}
        if(-NOT $container_registries){continue}
        $all_container_registries = @();
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Azure Container Registries", $O365Object.current_subscription.DisplayName);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('AzureContainerInfo');
        }
        Write-Information @msg
        #Get all containers registries
        if($container_registries){
            foreach($container_registry in $container_registries){
                $URI = ("{0}{1}?api-version={2}" `
                        -f $O365Object.Environment.ResourceManager,$container_registry.id,$cntRegistryAPI.api_version)
                #launch request
                $params = @{
                    Authentication = $rm_auth;
                    OwnQuery = $URI;
                    Environment = $Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                }
                $my_container_registry = Get-MonkeyRMObject @params
                if($my_container_registry){
                    #Get Network properties
                    if(-NOT $my_container_registry.properties.NetworkRuleSet){
                        $my_container_registry | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $true
                    }
                    else{
                        $my_container_registry | Add-Member -type NoteProperty -name allowAccessFromAllNetworks -value $false
                    }
                    #Add container registries to array
                    $all_container_registries += $my_container_registry
                }
            }
        }
    }
    End{
        if($all_container_registries){
            $all_container_registries.PSObject.TypeNames.Insert(0,'Monkey365.Azure.ContainerRegistries')
            [pscustomobject]$obj = @{
                Data = $all_container_registries
            }
            $returnData.az_container_registries = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Azure Container registry", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureContainersEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
