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
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Storage account object")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [String]$APIVersion = "2025-06-01"
    )
    Process{
        $p = @{
			Id = $InputObject.Id;
            Resource = "blobServices/default";
            ApiVersion = $APIVersion;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
            InformationAction = $O365Object.InformationAction;
		}
		$dataProtection = Get-MonkeyAzObjectById @p
        If($null -ne $dataProtection){
            #Add cors rules if any
            $InputObject.dataProtection.cors = $dataProtection.properties.cors
            #Check for static website
            If($null -eq $dataProtection.properties.PsObject.Properties.Item('staticWebsite')){
                $InputObject.dataProtection.staticWebsite.enabled = $false
            }
            Else{
                $InputObject.dataProtection.staticWebsite.enabled = $dataProtection.properties.staticWebsite | Select-Object -ExpandProperty enabled -ErrorAction Ignore
            }
            #Check for versioning
            If($null -eq $dataProtection.properties.PsObject.Properties.Item('isVersioningEnabled')){
                $InputObject.dataProtection.isVersioningEnabled = $false
            }
            Else{
                $InputObject.dataProtection.isVersioningEnabled = $dataProtection.properties.isVersioningEnabled
            }
            #Check for restore policy
            If($null -eq $dataProtection.properties.PsObject.Properties.Item('restorePolicy')){
                $InputObject.dataProtection.restorePolicy.enabled = $false
            }
            Else{
                $InputObject.dataProtection.restorePolicy.enabled = $dataProtection.properties.restorePolicy | Select-Object -ExpandProperty enabled -ErrorAction Ignore
                $InputObject.dataProtection.restorePolicy.days = $dataProtection.properties.restorePolicy | Select-Object -ExpandProperty days -ErrorAction Ignore
                $InputObject.dataProtection.restorePolicy.lastEnabledTime = $dataProtection.properties.restorePolicy | Select-Object -ExpandProperty lastEnabledTime -ErrorAction Ignore
                $InputObject.dataProtection.restorePolicy.minRestoreTime = $dataProtection.properties.restorePolicy | Select-Object -ExpandProperty minRestoreTime -ErrorAction Ignore
            }
            #Check for container policy
            If($null -eq $dataProtection.properties.PsObject.Properties.Item('containerDeleteRetentionPolicy')){
                $InputObject.dataProtection.containerDeleteRetentionPolicy.enabled = $false
            }
            Else{
                $InputObject.dataProtection.containerDeleteRetentionPolicy.enabled = $dataProtection.properties.containerDeleteRetentionPolicy | Select-Object -ExpandProperty enabled -ErrorAction Ignore
                $InputObject.dataProtection.containerDeleteRetentionPolicy.days = $dataProtection.properties.containerDeleteRetentionPolicy | Select-Object -ExpandProperty days -ErrorAction Ignore
                $InputObject.dataProtection.containerDeleteRetentionPolicy.allowPermanentDelete = $dataProtection.properties.containerDeleteRetentionPolicy | Select-Object -ExpandProperty allowPermanentDelete -ErrorAction Ignore
            }
            #Check for change feed policy
            If($null -eq $dataProtection.properties.PsObject.Properties.Item('changeFeed')){
                $InputObject.dataProtection.changeFeed.enabled = $false
            }
            Else{
                $InputObject.dataProtection.changeFeed.enabled = $dataProtection.properties.changeFeed | Select-Object -ExpandProperty enabled -ErrorAction Ignore
                $InputObject.dataProtection.changeFeed.retentionInDays = $dataProtection.properties.changeFeed | Select-Object -ExpandProperty retentionInDays -ErrorAction Ignore
            }
            #Check for delete retention policy
            If($null -eq $dataProtection.properties.PsObject.Properties.Item('deleteRetentionPolicy')){
                $InputObject.dataProtection.deleteRetentionPolicy.enabled = $false
            }
            Else{
                $InputObject.dataProtection.deleteRetentionPolicy.enabled = $dataProtection.properties.deleteRetentionPolicy | Select-Object -ExpandProperty enabled -ErrorAction Ignore
                $InputObject.dataProtection.deleteRetentionPolicy.days = $dataProtection.properties.deleteRetentionPolicy | Select-Object -ExpandProperty days -ErrorAction Ignore
                $InputObject.dataProtection.deleteRetentionPolicy.allowPermanentDelete = $dataProtection.properties.deleteRetentionPolicy | Select-Object -ExpandProperty allowPermanentDelete -ErrorAction Ignore
            }
            #Add raw object
            $InputObject.dataProtection.rawObject = $dataProtection
        }
        #return object
        return $InputObject
    }
}
