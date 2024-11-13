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

Function Export-MonkeyData{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Export-MonkeyData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $True, HelpMessage = 'Output format')]
        [String]$ExportTo
    )
    Process{
        If($ExportTo.ToLower() -in @('json','csv','clixml')){
            $out_folder = ('{0}/{1}' -f $Script:Report, $ExportTo.ToLower())
            $OutDir = New-MonkeyFolder -destination $out_folder
            If($null -ne $OutDir){
                If($O365Object.Instance.ToLower() -eq 'azure'){
                    $p = @{
                        InputObject = $matchedRules;
                        ProductName = 'Monkey365';
                        ProductVersion = Get-MonkeyVersion;
                        ProductVendorName = 'Monkey365';
                        TenantId = $O365Object.executionInfo.Tenant.TenantId;
                        TenantName = $O365Object.executionInfo.Tenant.TenantName;
                        SubscriptionId = $O365Object.executionInfo.subscription.subscriptionId;
                        SubscriptionName = $O365Object.executionInfo.subscription.subscriptionId;
                        Provider = $O365Object.Instance;
                        ExportTo = $ExportTo;
                        OutDir = $OutDir;
                    }
                }
                Else{
                    $p = @{
                        InputObject = $matchedRules;
                        ProductName = 'Monkey365';
                        ProductVersion = Get-MonkeyVersion;
                        ProductVendorName = 'Monkey365';
                        TenantId = $O365Object.executionInfo.Tenant.TenantId;
                        TenantName = $O365Object.executionInfo.Tenant.TenantName;
                        Provider = $O365Object.Instance;
                        ExportTo = $ExportTo;
                        OutDir = $OutDir;
                    }
                }
                #Export Data
                Invoke-MonkeyOutput @p
            }
        }
        ElseIf($ExportTo.ToLower() -eq "html"){
            $out_folder = ('{0}/{1}' -f $Script:Report, $ExportTo.ToLower())
            $OutDir = New-MonkeyFolder -destination $out_folder
            if($OutDir){
                Invoke-HtmlReport -OutDir $OutDir
            }
        }
    }
}
