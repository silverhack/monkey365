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

Function Get-MonkeyAzStorageAccountDataProtection {
    <#
        .SYNOPSIS
		Get storage account data protecction settings from Azure

        .DESCRIPTION
		Get storage account data protecction settings from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzStorageAccountDataProtection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True)]
        [Object]$StorageAccount,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2021-06-01"
    )
    Begin{
        #new Restore object policy
        $PolicyObj = [PSCustomObject]@{
            enabled = $false;
        }
    }
    Process{
        $p = @{
			Id = $StorageAccount.Id;
            Resource = "blobServices/default";
            ApiVersion = $APIVersion;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
		}
		$dataProtection = Get-MonkeyAzObjectById @p
        if($dataProtection){
            #Check for versioning
            if($null -eq $dataProtection.properties.PsObject.Properties.Item('isVersioningEnabled')){
                $dataProtection.properties | Add-Member -Type NoteProperty -Name isVersioningEnabled -Value $false
            }
            #Check for restore policy
            if($null -eq $dataProtection.properties.PsObject.Properties.Item('restorePolicy')){
                $dataProtection.properties | Add-Member -Type NoteProperty -Name restorePolicy -Value $PolicyObj
            }
            #Check for container policy
            if($null -eq $dataProtection.properties.PsObject.Properties.Item('containerDeleteRetentionPolicy')){
                $dataProtection.properties | Add-Member -Type NoteProperty -Name containerDeleteRetentionPolicy -Value $PolicyObj
            }
            #Check for change feed policy
            if($null -eq $dataProtection.properties.PsObject.Properties.Item('changeFeed')){
                $dataProtection.properties | Add-Member -Type NoteProperty -Name changeFeed -Value $PolicyObj
            }
            $StorageAccount.dataProtection = $dataProtection
        }
    }
    End{
        $StorageAccount
    }
}

