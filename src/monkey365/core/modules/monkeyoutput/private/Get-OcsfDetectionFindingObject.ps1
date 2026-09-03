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

        [parameter(Mandatory=$false, HelpMessage="Resource data")]
        [Object]$Data,

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
    Begin{
        #Get Metadata
        $Metadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-Metadata")
        #Set new dict
        $metadataPsboundParams = [ordered]@{}
        $param = $Metadata.Parameters.Keys
        ForEach($p in $param.GetEnumerator()){
            If($p -eq "InputObject"){continue}
            If($PSBoundParameters.ContainsKey($p)){
                $metadataPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        #Get Finding info params
        $FindingInfoMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-FindingInfo")
        #Set new dict
        $findingInfoPsboundParams = [ordered]@{}
        $param = $FindingInfoMetadata.Parameters.Keys
        ForEach($p in $param.GetEnumerator()){
            If($p -eq "InputObject"){continue}
            If($PSBoundParameters.ContainsKey($p)){
                $findingInfoPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        #Get cloud param
        $CloudObjMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "Get-CloudObject")
        #Set new dict
        $cloudPsboundParams = [ordered]@{}
        $param = $CloudObjMetadata.Parameters.Keys
        ForEach($p in $param.GetEnumerator()){
            If($PSBoundParameters.ContainsKey($p)){
                $cloudPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
    }
    Process{
        #Set detection finding obj
        $detectionFindingObj = New-OcsfDetectionFindingObject
        #Add timestamp
        $detectionFindingObj.time = $InputObject.timestamp;
        #Add activity Id
        $detectionFindingObj.ActivityId = [Ocsf.ActivityId]::Create.value__
        $detectionFindingObj.ActivityName = [Ocsf.ActivityId]::Create.ToString()
        $detectionFindingObj.Severity = $InputObject.level | Get-Severity
        $detectionFindingObj.SeverityId = $InputObject.level | Get-SeverityId
        #Get StatusCode
        $detectionFindingObj.statusCode = $InputObject.statusCode
        #Get Remediation
        $detectionFindingObj.Remediation = $InputObject | Get-Remediation
        #Get metadata from inputobject
        $detectionFindingObj.Metadata = $InputObject | Get-Metadata @metadataPsboundParams
        #Get Finding info
        $detectionFindingObj.FindingInfo = $InputObject | Get-FindingInfo @findingInfoPsboundParams
        ##Fill Category and Class##
        $detectionFindingObj.CategoryId = [Ocsf.CategoryId]::Findings.value__
        $detectionFindingObj.CategoryName = [Ocsf.CategoryId]::Findings.ToString()
        $detectionFindingObj.ClassId = [Ocsf.ClassId]::Detection.value__
        $detectionFindingObj.ClassName = [Ocsf.ClassId]::Detection.ToString()
        #Get cloud object
        $detectionFindingObj.Cloud = Get-CloudObject @cloudPsboundParams
        ####Calc Type Id class_uid * 100 + activity_id ###
        $detectionFindingObj.typeId = ([Ocsf.ClassId]::Detection.value__ * 100) + [Ocsf.ActivityId]::Create.value__
        $detectionFindingObj.TypeName = [Ocsf.TypeId]::Create.ToString()
        #Get Status
        $detectionFindingObj.Status = $InputObject.level | Get-Status
        $detectionFindingObj.StatusId = $InputObject.level | Get-StatusId
        #Add Unmapped data
        $unmapped = [PsCustomObject]@{
            Provider = $InputObject.metadata.Provider;
            PluginId = $InputObject.metadata.Id;
            ApiType = $InputObject.metadata.ApiType;
            Resource = $InputObject.metadata.Resource;
            ruleId = $InputObject.id;
            immutableId = $null;
        }
        $detectionFindingObj.unmapped = $unmapped;
        #Get resource details param
        $ResourcesObjMetadata = New-Object -TypeName "System.Management.Automation.CommandMetaData" (Get-Command -Name "New-OcsfResourceDetailsObject")
        #Set new dict
        $resourceDetailsPsboundParams = [ordered]@{}
        $param = $ResourcesObjMetadata.Parameters.Keys
        ForEach($p in $param.GetEnumerator()){
            If($PSBoundParameters.ContainsKey($p)){
                $resourceDetailsPsboundParams.Add($p,$PSBoundParameters[$p])
            }
        }
        $detectionFindingObj.Resources = New-OcsfResourceDetailsObject @resourceDetailsPsboundParams
        #Set status
        If($PSBoundParameters.ContainsKey('Data') -and $PSBoundParameters['Data']){
            #Get Status from inputobject
            Try{
                $status = $InputObject.output.text.status;
                $detectionFindingObj.StatusDetail = $PSBoundParameters['Data'] | Get-FindingLegend -StatusObject $status
            }
            Catch{
                Write-Warning ("Unable to get status from {0}" -f $InputObject.displayName)
                Write-Error $_.Exception.Message
            }
            #Get Immutable Id;
            $properties = $InputObject | Select-Object -ExpandProperty immutable_properties -ErrorAction Ignore
            If($null -ne $properties){
                $p = @{
                    Properties = $properties
                    TenantId = $PSBoundParameters['TenantId']
                }
                $immutableId = $PSBoundParameters['Data'] | Get-ImmutableId @p
                If($null -ne $immutableId){
                    $detectionFindingObj.unmapped.immutableId = $immutableId
                }
                Else{
                    Write-Warning ("immutable Id failed for {0}" -f $InputObject.displayName)
                }
            }
            Else{
                Write-Verbose ("immutable properties were not found for {0}" -f $InputObject.displayName)
            }
        }
        Else{
            #Get default status message
            Try{
                $detectionFindingObj.StatusDetail = $InputObject.output.text.status.defaultMessage
            }
            Catch{
                Write-Warning ("Unable to get default status from {0}" -f $InputObject.displayName)
                Write-Error $_.Exception.Message
            }
        }
        #return object
        return $detectionFindingObj
    }
}

