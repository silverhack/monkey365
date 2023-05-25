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

Function Get-MonkeyCSOMSiteProperty {
    <#
        .SYNOPSIS
		Get site properties from SharePoint Online

        .DESCRIPTION
		Get site properties from SharePoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSiteProperty
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'Site', HelpMessage="Site URL")]
        [String]$Site,

        [Parameter(Mandatory=$false, HelpMessage="As user")]
        [Switch]$AsUser
    )
    Begin{
        #Set null
        $site_property = $null
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
        #Get SharePoint Online administrator token
        $spo_admin = $O365Object.auth_tokens.SharePointAdminOnline
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharepointOnline
    }
    Process{
        if($PSBoundParameters.ContainsKey('AsUser') -and $PSBoundParameters.AsUser.IsPresent){
            if($PSCmdlet.ParameterSetName -eq 'Site'){
                $p = @{
                    Authentication = $sps_auth;
                    EndPoint = $Site;
                    ObjectPath = 'SiteProperties';
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                $site_property = Invoke-MonkeySPOAdminApi @p
            }
            else{
                $p = @{
                    Authentication = $sps_auth;
                    ObjectPath = 'SiteProperties';
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                $site_property = Invoke-MonkeySPOAdminApi @p
            }
        }
        elseif($PSCmdlet.ParameterSetName -eq 'Site'){
            $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="34" ObjectPathId="33"/><ObjectPath Id="36" ObjectPathId="35"/><Query Id="37" ObjectPathId="35"><Query SelectAllProperties="true"><Properties/></Query></Query></Actions><ObjectPaths><Constructor Id="33" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}"/><Method Id="35" ParentId="33" Name="GetSitePropertiesByUrl"><Parameters><Parameter Type="String">${url}</Parameter><Parameter Type="Boolean">true</Parameter></Parameters></Method></ObjectPaths></Request>' -replace '\${url}', $Site
            $p = @{
                Authentication = $spo_admin;
                Data = $body_data;
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
            }
            $site_property = Invoke-MonkeyCSOMRequest @p
        }
        else{
            #Get site properties for all sites
            $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="824" ObjectPathId="823" /><ObjectPath Id="826" ObjectPathId="825" /><Query Id="827" ObjectPathId="825"><Query SelectAllProperties="true"><Properties><Property Name="NextStartIndexFromSharePoint" ScalarProperty="true" /></Properties></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Constructor Id="823" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /><Method Id="825" ParentId="823" Name="GetSitePropertiesFromSharePoint"><Parameters><Parameter Type="Null" /><Parameter Type="Boolean">false</Parameter></Parameters></Method></ObjectPaths></Request>')
            $p = @{
                Authentication = $spo_admin;
                Data = $body_data;
                ChildItems = $True;
                Verbose = $Verbose;
                Debug = $Debug;
                InformationAction = $InformationAction;
            }
            $site_property = Invoke-MonkeyCSOMRequest @p
        }
        #return data
        if($null -ne $site_property){
            return $site_property
        }
    }
    End{
        #Nothing to do here
    }
}