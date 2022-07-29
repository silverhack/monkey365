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

Function Get-MonkeyAzResource{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzResource
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$resourceGroupNames
        )
    Begin{
        $all_resources = @()
    }
    Process{
        if($null -ne $resourceGroupNames -and $resourceGroupNames.Count -gt 0){
            foreach($rg in $resourceGroupNames.GetEnumerator()){
                $q = [uri]::EscapeDataString(("'{0}', resourceGroup" -f $rg))
                $filter = ('&$filter=substringof({0})' -f $q)
                #Get Resources
                $params = @{
                    Authentication = $O365Object.auth_tokens.ResourceManager;
                    ObjectType = 'resources';
                    Query = $filter;
                    Environment = $O365Object.Environment;
                    ContentType = 'application/json';
                    Method = "GET";
                    APIVersion = "2021-04-01";
                }
                $resources = Get-MonkeyRMObject @params
                if($resources){
                    $all_resources +=$resources
                }
            }
        }
        else{
            #Get all resources within subscription
            $params = @{
                Authentication = $O365Object.auth_tokens.ResourceManager;
                ObjectType = 'resources';
                Environment = $O365Object.Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = "2019-10-01";
            }
            $resources = Get-MonkeyRMObject @params
            if($resources){
                $all_resources +=$resources
            }
        }
    }
    End{
        if($all_resources){
            return $all_resources
        }
    }
}
