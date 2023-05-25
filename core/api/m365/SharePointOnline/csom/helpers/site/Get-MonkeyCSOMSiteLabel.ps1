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

Function Get-MonkeyCSOMSiteLabel{
    <#
        .SYNOPSIS
        Get Compliance Tags published to a site collection

        .DESCRIPTION
        Get Compliance Tags published to a site collection

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSiteLabel
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, HelpMessage="Endpoint")]
        [String]$Endpoint
    )
    Begin{
        $tags = $null
        #Tenant client sync restriction
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><StaticMethod TypeId="{9efa17eb-0d34-4f69-a085-5cc3f802439e}" Name="GetAvailableTagsForSite" Id="22"><Parameters><Parameter Type="String">https://tenant.sharepoint.com/sites/siteurl</Parameter></Parameters></StaticMethod></Actions><ObjectPaths/></Request>'
    }
    Process{
        $p = @{
            Authentication = $Authentication;
            Data = $body_data;
            Endpoint = $Endpoint;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        #Execute query
        $tags = Invoke-MonkeyCSOMRequest @p
    }
    End{
        if($tags){
            return $tags
        }
    }
}
