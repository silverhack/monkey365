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

Function Get-MonkeyCSOMWebByGuid{
    <#
        .SYNOPSIS
        Get web by guid from SharePoint Online

        .DESCRIPTION
        Get web by guid from SharePoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMWebByGuid
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$False, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, ParameterSetName = 'Endpoint', HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$true, ParameterSetName = 'Site', HelpMessage="Site Object")]
        [Object]$Site,

        [parameter(Mandatory=$true, ValueFromPipeline = $true, HelpMessage="Guid")]
        [String]$Id,

        [Parameter(Mandatory= $false, ParameterSetName = 'Includes', HelpMessage="Includes")]
        [string[]]$Includes
    )
    Begin{
        $objectMetadata = @{
            "CheckValue"=3;
            "isEqualTo"=139;
            "GetValue"=4;
        }
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName=".NET Library" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="138" ObjectPathId="137" /><Query Id="139" ObjectPathId="137"><Query SelectAllProperties="true"></Query></Query></Actions><ObjectPaths><Method Id="137" ParentId="10" Name="OpenWebById"><Parameters><Parameter Type="Guid">${guid}</Parameter></Parameters></Method><Identity Id="10" Name="${objectId}" /></ObjectPaths></Request>'
        #Set properties
        $properties = $body_data.CreateElement("Properties", $body_data.NamespaceURI)
        #Check if includes
        if($PSBoundParameters.ContainsKey('Includes') -and $PSBoundParameters['Includes']){
            foreach($include in $PSBoundParameters['Includes']){
                $prop = $body_data.CreateNode([System.Xml.XmlNodeType]::Element, $body_data.Prefix, 'Property', $body_data.NamespaceURI);
                #Set attributes
                [void]$prop.SetAttribute('Name',$include)
                if($include -in $select_all_properties){
                    [void]$prop.SetAttribute('SelectAll','true')
                }
                else{
                    [void]$prop.SetAttribute('ScalarProperty','true')
                }
                [void]$properties.AppendChild($prop)
            }
        }
        [void]$body_data.Request.Actions.Query.Query.AppendChild($properties)
        [xml]$body_data = $body_data.OuterXml.Replace(" xmlns=`"`"", "")
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq "Current" -or $PSCmdlet.ParameterSetName -eq 'Endpoint'){
            #Set command parameters
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMSite" -Params $PSBoundParameters
            $_Site = Get-MonkeyCSOMSite @p
            if($null -ne $_Site){
                #Remove endpoint if exists
                [void]$PSBoundParameters.Remove('Endpoint')
                Get-MonkeyCSOMWebByGuid @PSBoundParameters -Site $_Site
            }
        }
        Else{
            #Set absolute path
            $body_data.Request.ObjectPaths.Method.Parameters.Parameter.'#text' = ("{{{0}}}" -f $PSBoundParameters['Id'])
            #Set object Id
            $body_data.Request.ObjectPaths.Identity.Name = $PSBoundParameters['Site']._ObjectIdentity_
            #$data = $bodyOpenWeb -replace '\${relativeUrl}',$absolutePath -replace '\${objectId}',$PSBoundParameters['Site']._ObjectIdentity_
            #Set command parameters
            $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMDefaultRequest" -Params $PSBoundParameters
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
            #Add endpoint
            $p.Item('Endpoint') = $PSBoundParameters['Site'].Url;
            #Add post Data
            [void]$p.Add('Data',$body_data.OuterXml);
            #Add post Data
            [void]$p.Add('ObjectMetadata',$objectMetadata);
            #Execute query
            Invoke-MonkeyCSOMDefaultRequest @p
        }
    }
    End{
        #Nothing to do here
    }
}

