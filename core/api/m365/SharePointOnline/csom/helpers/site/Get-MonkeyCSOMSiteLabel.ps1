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
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint,

        [parameter(Mandatory=$false, ParameterSetName = 'Site',ValueFromPipeline = $true, HelpMessage="SharePoint Site")]
        [Object]$Site
    )
    Begin{
        $_Endpoint = $null
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'Endpoint'){
            $_Endpoint = $PSBoundParameters['Endpoint']
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'Site'){
            $objectType = $PSBoundParameters['Site'] | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
            if ($null -ne $objectType -and $objectType -eq 'SP.Site'){
                $_Endpoint = $PSBoundParameters['Site'].Url
            }
            Else{
                $msg = @{
                    MessageData = ($message.SPOInvalidSiteObjectMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMInvalidWebObject');
                }
                Write-Warning @msg
                $_Endpoint = $null
            }
        }
        Else{#Current
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMSite" -Params $PSBoundParameters
            $_Site = Get-MonkeyCSOMSite @p
            if($_Site){
                #Add Site to PsboundParameters
                [void]$PSBoundParameters.Add('Site',$_Site);
                Get-SiteLabel @PSBoundParameters
            }
        }
        if($null -ne $_Endpoint){
            #Site Tags
            [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><StaticMethod TypeId="{9efa17eb-0d34-4f69-a085-5cc3f802439e}" Name="GetAvailableTagsForSite" Id="22"><Parameters><Parameter Type="String">${url}</Parameter></Parameters></StaticMethod></Actions><ObjectPaths/></Request>' -replace '\${url}', $_Endpoint
            #Set command parameters
            $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMRequest" -Params $PSBoundParameters
            #Add Endpoint
            $p.Item('Endpoint') = $_Endpoint
            #Add authentication header if missing
            if(!$p.ContainsKey('Authentication')){
                if($null -ne $O365Object.auth_tokens.SharePointOnline){
                    [void]$p.Add('Authentication',$O365Object.auth_tokens.SharePointOnline);
                }
                Else{
                    Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
                    break
                }
            }
            #Add Body
            [void]$p.Add('Data',$body_data);
            #Execute query
            Invoke-MonkeyCSOMRequest @p
        }
    }
}
