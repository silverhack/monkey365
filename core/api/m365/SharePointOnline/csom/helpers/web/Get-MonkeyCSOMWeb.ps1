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

Function Get-MonkeyCSOMWeb{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMWeb
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$false, HelpMessage="Recursive search")]
        [Switch]$Recurse,

        [Parameter(Mandatory= $false, ParameterSetName = 'Includes', HelpMessage="Includes")]
        [string[]]$Includes,

        [Parameter(Mandatory=$false, HelpMessage="Subsite depth limit recursion")]
        [int32]$Limit = 10
    )
    Begin{
        $select_all_properties = @(
            'Folder','Lists',
            'RoleDefinitionBindings',
            'Member','ParentList',
            'RoleAssignments','File',
            'RootFolder','Webs'
        )
        $spo_web = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        #Get PNPWeb
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="2" ObjectPathId="1"/><ObjectPath Id="4" ObjectPathId="3"/><Query Id="5" ObjectPathId="3"><Query SelectAllProperties="true"></Query></Query></Actions><ObjectPaths><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current"/><Property Id="3" ParentId="1" Name="Web"/></ObjectPaths></Request>'
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
            Endpoint = $endpoint;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        #Construct query
        $raw_spo_web = Invoke-MonkeyCSOMRequest @p
        if($raw_spo_web){
            if($Includes){
                #Remove childitem
                foreach($include in $Includes){
                    if($null -ne $raw_spo_web.($include) -and $null -ne $raw_spo_web.($include).PsObject.Properties.Item('_Child_Items_')){
                        $raw_spo_web.($include) = $raw_spo_web.($include)._Child_Items_
                    }
                }
            }
            [void]$spo_web.Add($raw_spo_web)
        }
        #Check if recurse
        if($Recurse.IsPresent -and $null -ne $raw_spo_web.Psobject.Properties.Item('Url')){
            $msg = @{
                MessageData = ($message.SharepointSubSitesMessage -f $raw_spo_web.Url);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('SPSSearchSubsites');
            }
            Write-Information @msg
            $p = @{
                Authentication = $Authentication;
                Web = $raw_spo_web;
                Recurse = $Recurse;
                Limit = $Limit;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Construct query
            $raw_spo_web = Get-MonkeyCSOMSubWeb @p
            if($raw_spo_web){
                foreach($web in @($raw_spo_web)){
                    [void]$spo_web.Add($web)
                }
            }
        }
    }
    End{
        return $spo_web
    }
}
