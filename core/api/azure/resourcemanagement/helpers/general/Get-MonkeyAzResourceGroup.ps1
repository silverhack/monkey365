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

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$resourceGroupNames
        )
    Begin{
        $all_resource_groups = @()
    }
    Process{
        if($null -ne $resourceGroupNames -and $resourceGroupNames.Count -gt 0){
            foreach($rg in $resourceGroupNames.GetEnumerator()){
                #Get Resource Group
                $objectType = ("resourcegroups/{0}" -f $rg)
                $params = @{
                    Authentication = $O365Object.auth_tokens.ResourceManager;
                    ObjectType = $objectType;
                    Environment = $O365Object.Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = "2019-10-01";
                }
                $resource_group = Get-MonkeyRMObject @params
                if($resource_group){
                    $all_resource_groups +=$resource_group
                }
                else{
                    $msg = @{
                        MessageData = ($message.ResourceGroupNotFoundMessage -f $rg, $Script:Subscription.subscriptionId);
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
                APIVersion = "2019-10-01";
            }
            $resource_group = Get-MonkeyRMObject @params
            if($resource_group){
                $all_resource_groups +=$resource_group
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
