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

Function Get-OcsfDetectionFindingObject{
    <#
        .SYNOPSIS
        Get OCSF detection finding object
        .DESCRIPTION
        Get OCSF detection finding object
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-OcsfDetectionFindingObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Finding")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Product Name")]
        [String]$ProductName,

        [parameter(Mandatory=$false, HelpMessage="Product Version")]
        [String]$ProductVersion,

        [parameter(Mandatory=$false, HelpMessage="Product Vendor Name")]
        [String]$ProductVendorName,

        [parameter(Mandatory=$false, HelpMessage="Tenant Id")]
        [String]$TenantId,

        [parameter(Mandatory=$false, HelpMessage="Tenant Name")]
        [String]$TenantName,

        [parameter(Mandatory=$false, HelpMessage="Subscription Id")]
        [String]$SubscriptionId,

        [parameter(Mandatory=$false, HelpMessage="Subscription Name")]
        [String]$SubscriptionName,

        [parameter(Mandatory=$false, HelpMessage="Provider")]
        [ValidateSet("Azure","EntraId","Microsoft365")]
        [String]$Provider = "Azure"
    )
    Process{
        $detectionFindingObj = New-OcsfDetectionFindingObject
        #Add timestamp
        $detectionFindingObj.time = $InputObject.timestamp;
        #Add activity Id
        $detectionFindingObj.ActivityId = [Ocsf.ActivityId]::Create.value__
        $detectionFindingObj.ActivityName = [Ocsf.ActivityId]::Create.ToString()
        $detectionFindingObj.Severity = Get-Severity -Level $InputObject.level
        $detectionFindingObj.SeverityId = Get-SeverityId -Level $InputObject.level
        #Get StatusCode
        $detectionFindingObj.statusCode = $InputObject.statusCode
        #Get Remediation
        $detectionFindingObj.Remediation = Get-Remediation -InputObject $InputObject
        #Get Metadata
        $Metadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-Metadata")
        #Set new dict
        $newPsboundParams = [ordered]@{}
        $param = $Metadata.Parameters.Keys
        foreach($p in $param.GetEnumerator()){
            if($PSBoundParameters.ContainsKey($p)){
                $newPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        $detectionFindingObj.Metadata = Get-Metadata @newPsboundParams
        #Get FindingInfo
        $FindingInfoMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-FindingInfo")
        #Set new dict
        $newPsboundParams = [ordered]@{}
        $param = $FindingInfoMetadata.Parameters.Keys
        foreach($p in $param.GetEnumerator()){
            if($PSBoundParameters.ContainsKey($p)){
                $newPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        $detectionFindingObj.FindingInfo = Get-FindingInfo @newPsboundParams
        ##Fill Category and Class##
        $detectionFindingObj.CategoryId = [Ocsf.CategoryId]::Findings.value__
        $detectionFindingObj.CategoryName = [Ocsf.CategoryId]::Findings.ToString()
        $detectionFindingObj.ClassId = [Ocsf.ClassId]::Detection.value__
        $detectionFindingObj.ClassName = [Ocsf.ClassId]::Detection.ToString()
        #Get Cloud object
        $CloudObjMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-CloudObject")
        #Set new dict
        $newPsboundParams = [ordered]@{}
        $param = $CloudObjMetadata.Parameters.Keys
        foreach($p in $param.GetEnumerator()){
            if($PSBoundParameters.ContainsKey($p)){
                $newPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        $detectionFindingObj.Cloud = Get-CloudObject @newPsboundParams
        ####Calc Type Id class_uid * 100 + activity_id ###
        $detectionFindingObj.typeId = ([Ocsf.ClassId]::Detection.value__ * 100) + [Ocsf.ActivityId]::Create.value__
        $detectionFindingObj.TypeName = [Ocsf.TypeId]::Create.ToString()
        #Get Status
        $detectionFindingObj.Status = Get-Status -Level $InputObject.level;
        $detectionFindingObj.StatusId = Get-StatusId -Level $InputObject.level;
        #Get Resource details
        $resourceDetails = New-OcsfResourceDetailsObject
        if($resourceDetails){
            $resourceDetails.Group.Name = $InputObject.serviceType
            $resourceDetails.CloudPartition = [Ocsf.Objects.Entity.AccountType]::AzureADAccount
            $detectionFindingObj.Resources = $resourceDetails;
        }
        #Add Unmapped data
        $unmapped = [PsCustomObject]@{
            Provider = $InputObject.metadata.Provider;
            PluginId = $InputObject.metadata.Id;
            ApiType = $InputObject.metadata.ApiType;
            Resource = $InputObject.metadata.Resource;
        }
        $detectionFindingObj.unmapped = $unmapped;
        return $detectionFindingObj
    }
}
