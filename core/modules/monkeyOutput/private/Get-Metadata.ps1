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

Function Get-Metadata{
    <#
        .SYNOPSIS
        Get remediation object
        .DESCRIPTION
        Get remediation object
        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-Remediation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSCustomObject])]
	Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Level")]
        [Object]$InputObject,

        [parameter(Mandatory=$false, HelpMessage="Product Name")]
        [String]$ProductName,

        [parameter(Mandatory=$false, HelpMessage="Product Version")]
        [String]$ProductVersion,

        [parameter(Mandatory=$false, HelpMessage="Product Vendor Name")]
        [String]$ProductVendorName
    )
    Process{
        Try{
            $metadataObject = New-OcsfMetadataObject
            if($null -ne $metadataObject){
                ##Populate Metadata##
                $metadataObject.EventCode = $InputObject.idSuffix;
                $metadataObject.Product.Name = $PSBoundParameters['ProductName'];
                $metadataObject.Product.VendorName = $PSBoundParameters['ProductVendorName'];
                $metadataObject.Product.Version = $PSBoundParameters['ProductVersion'];;
                $metadataObject.Version = '1.1.0';
                #return Object
                return $metadataObject;
            }
        }
        Catch{
            Write-Error $_
        }
    }
}