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

Function Get-MonkeyCSOMSite{
    <#
        .SYNOPSIS
        Get site from SharePoint Online

        .DESCRIPTION
        Get site from SharePoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSite
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [Parameter(Mandatory= $false, ParameterSetName = 'Includes', HelpMessage="Includes")]
        [string[]]$Includes
    )
    Begin{
        $select_all_properties = @(
            'Folder','Lists',
            'RoleDefinitionBindings',
            'Member','ParentList',
            'RoleAssignments','File',
            'RootFolder','Webs'
        )
        #Set False
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        #Get Site
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="2" ObjectPathId="1"/><ObjectPath Id="4" ObjectPathId="3"/><Query Id="5" ObjectPathId="3"><Query SelectAllProperties="true"></Query></Query></Actions><ObjectPaths><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current"/><Property Id="3" ParentId="1" Name="Site"/></ObjectPaths></Request>'
        #Set properties
        $properties = $body_data.CreateElement("Properties", $body_data.NamespaceURI)
        #Check if includes
        if($PSCmdlet.ParameterSetName -eq 'Includes'){
            foreach($include in $Includes){
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
        $p = @{
            Authentication = $Authentication;
            Data = $body_data;
            Endpoint = $Endpoint;
            Verbose = $Verbose;
            Debug = $Debug;
            InformationAction = $InformationAction;
        }
        #Execute query
        $raw_sps_site = Invoke-MonkeyCSOMRequest @p
    }
    End{
        if($raw_sps_site){
            return $raw_sps_site
        }
    }
}
