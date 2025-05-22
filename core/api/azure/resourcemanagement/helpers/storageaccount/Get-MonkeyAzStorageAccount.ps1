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

Function Get-MonkeyAzStorageAccount {
    <#
        .SYNOPSIS
		Get storage account from Azure

        .DESCRIPTION
		Get storage account from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccount
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2019-06-01"
    )
    Process{
        try{
            if(!$PSBoundParameters.ContainsKey('APIVersion')){
                #Get Config
                $strConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureStorage" } | Select-Object -ExpandProperty resource
                $api_version = $strConfig.api_version;
            }
            else{
                $api_version = $PSBoundParameters['APIVersion'];
            }
            $p = @{
                Id = ("subscriptions/{0}/providers/Microsoft.Storage" -f $O365Object.current_subscription.subscriptionId);
                Resource = 'storageAccounts';
                ApiVersion = $api_version;
                Method = 'Get';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $straccounts = Get-MonkeyAzObjectById @p
            #return storage accounts
            if($straccounts){
                $straccounts
            }
        }
        catch{
            Write-Debug $_
        }
    }
    End{
        #Nothing to do here
    }
}
