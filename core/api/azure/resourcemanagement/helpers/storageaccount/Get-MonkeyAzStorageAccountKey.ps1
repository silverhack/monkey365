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

Function Get-MonkeyAzStorageAccountKey {
    <#
        .SYNOPSIS
		Get storage account key from Azure

        .DESCRIPTION
		Get storage account key from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccountKey
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$StorageAccount
    )
    Process{
        try{
            #Get Config
            $strConfig = $O365Object.internal_config.ResourceManager | Where-Object { $_.Name -eq "azureStorage" } | Select-Object -ExpandProperty resource
            $p = @{
                Id = $StorageAccount.Id;
                Resource = 'listKeys';
                ApiVersion = $strConfig.api_version;
                Method = 'Post';
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                InformationAction = $O365Object.InformationAction;
            }
            $strkeys = Get-MonkeyAzObjectById @p
            #return key1
            if($strkeys){
                $strkeys.Keys | Where-Object { $_.keyname -eq 'key1' } | Select-Object -ExpandProperty value
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
