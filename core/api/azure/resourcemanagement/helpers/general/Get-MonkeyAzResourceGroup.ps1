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

Function Get-MonkeyAzResourceGroup{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResourceGroup
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$ResourceGroupNames
    )
    Begin{
        $all_resource_groups = New-Object System.Collections.Generic.List[System.Object]
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'resourceGroup'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
        if($null -eq $apiDetails){
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        if($null -ne $ResourceGroupNames -and $ResourceGroupNames.Count -gt 0){
            foreach($rg in $ResourceGroupNames.GetEnumerator()){
                #Get Resource Group
                $objectType = ("resourcegroups/{0}" -f $rg)
                $params = @{
                    Authentication = $O365Object.auth_tokens.ResourceManager;
                    ObjectType = $objectType;
                    Environment = $O365Object.Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = $apiDetails.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $resource_group = Get-MonkeyRMObject @params
                if($resource_group){
                    [void]$all_resource_groups.Add($resource_group)
                }
                else{
                    $msg = @{
                        MessageData = ($message.ResourceGroupNotFoundMessage -f $rg, $O365Object.current_subscription.subscriptionId);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $InformationAction;
                        Tags = @('AzureResourceGroupNotFound');
                    }
                    Write-Warning @msg
                }
            }
        }
        else{
            $params = @{
                Authentication = $O365Object.auth_tokens.ResourceManager;
                ObjectType = 'resourcegroups';
                Environment = $O365Object.Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $resource_group = Get-MonkeyRMObject @params
            if($resource_group){
                [void]$all_resource_groups.Add($resource_group)
            }
        }
    }
    End{
        #Resource groups with the following format:
        #@{id=/subscriptions/000000-00000-00000-0000/resourceGroups/myresourcename; name=myresourcename; location=westeurope; properties=}
        if($all_resource_groups){
            return $all_resource_groups
        }
    }
}

