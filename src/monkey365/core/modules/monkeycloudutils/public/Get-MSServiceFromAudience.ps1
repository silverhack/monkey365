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

Function Get-MSServiceFromAudience{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MSServiceFromAudience
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    Param(
        # Well Known Azure service
        [Parameter(Mandatory = $True, ValueFromPipeline = $True, HelpMessage = 'Audience')]
        [String]$InputObject
    )
    Begin{
        $WellKnownAudience = [Ordered]@{
            Teams = '48ac35b8-9aa8-4d74-927d-1f4a14a0b239';
            SharePoint = '00000003-0000-0ff1-ce00-000000000000';
            ResourceManager = "https://management.azure.com?.$|core.windows.net?.$|core.usgovcloudapi.net?.$|usgovcloudapi.net?.$";
            MSGraph = "https://graph.microsoft.com?.$|.us?.$|microsoftgraph.chinacloudapi.cn?.$";
            ExchangeOnline = "https://outlook.office365.com|.us";
            AzurePortal = '74658136-14ec-4630-ad9b-26e160ff0fc6';
            PowerBI = 'https://analysis.windows.net|analysis.chinacloudapi.cn|analysis.usgovcloudapi.net/powerbi/api';
            AADRM = "https://aadrm.com?.$|.us?.$";
            AzureStorage = 'https://storage.azure.com?.$|us?.$';
            AzureVault = "cfa8b339-82a2-471a-a3c9-0fc0be7a4093";
            Fabric = "https://api.fabric.microsoft.com?.$|us?.$"
        }
    }
    Process{
        $WellKnownAudience.GetEnumerator().Where({$InputObject.Trim() -match $_.Value}) | Select-Object -ExpandProperty Name -ErrorAction Ignore
    }
}

