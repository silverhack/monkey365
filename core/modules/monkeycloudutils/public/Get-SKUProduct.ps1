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

Function Get-SKUProduct{
    <#
        .SYNOPSIS

        Get the list of commercial subscriptions (SKUs) from Microsoft.com

        .DESCRIPTION

        Get the list of commercial subscriptions (SKUs) from Microsoft.com

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-SKUProduct
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    try{
        $licenses = 'https://download.microsoft.com/download/e/3/e/e3e9faf2-f28b-490a-9ada-c6089a1fc5b0/Product%20names%20and%20service%20plan%20identifiers%20for%20licensing.csv'
        #Get CSV licenses
        $metadata = Invoke-WebRequest -Uri $licenses -Method Get -UseBasicParsing
        #Convert To CSV
        $csv = [System.Text.Encoding]::UTF8.GetString($metadata.Content) | ConvertFrom-Csv
        #Convert to RAW object
        $rawObject = $csv | Select-Object @{Label="ProductName";Expression={($_.Product_Display_Name)}}, `
                                  @{Label="StringId";Expression={($_.String_Id)}}, `
                                  @{Label="Guid";Expression={($_.GUID)}}, `
                                  @{Label="ServicePlanName";Expression={($_.Service_Plan_Name)}},`
                                  @{Label="ServicePlanId";Expression={($_.Service_Plan_Id)}},`
                                  @{Label="ServicePlanFriendlyName";Expression={($_.Service_Plans_Included_Friendly_Names)}}
        #Return JSON object
        $rawObject | ConvertTo-Json
    }
    catch{
        if($_.ErrorDetails.Message){
            Write-Verbose $_.ErrorDetails.Message
        }
        else{
            Write-Verbose $_.Exception.Message
            Write-Debug $_.Exception.Response.StatusDescription
        }
    }
}


