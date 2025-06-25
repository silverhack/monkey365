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

	[CmdletBinding(DefaultParameterSetName = 'Current')]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint,

        [parameter(Mandatory=$false, ParameterSetName = 'Site',ValueFromPipeline = $true, HelpMessage="SharePoint Site")]
        [Object]$Site,

        #[Parameter(Mandatory=$false, HelpMessage="Request as user")]
        [Parameter(Mandatory = $false, ParameterSetName = 'Endpoint')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Site')]
        [Parameter(Mandatory = $false, ParameterSetName = 'Current')]
        [Switch]$AsUser,

        [Parameter(Mandatory=$false, ParameterSetName = 'All', HelpMessage="Site properties for all sites")]
        [Switch]$All
    )
    Process{
        if($PSCmdlet.ParameterSetName -eq "All"){
            #Get site properties for all sites
            $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="824" ObjectPathId="823" /><ObjectPath Id="826" ObjectPathId="825" /><Query Id="827" ObjectPathId="825"><Query SelectAllProperties="true"><Properties><Property Name="NextStartIndexFromSharePoint" ScalarProperty="true" /></Properties></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Constructor Id="823" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}" /><Method Id="825" ParentId="823" Name="GetSitePropertiesFromSharePoint"><Parameters><Parameter Type="Null" /><Parameter Type="Boolean">false</Parameter></Parameters></Method></ObjectPaths></Request>')
            #Set command parameters
            $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMRequest" -Params $PSBoundParameters
            #Add authentication header if missing
            if(!$p.ContainsKey('Authentication')){
                if($null -ne $O365Object.auth_tokens.SharePointAdminOnline){
                    [void]$p.Add('Authentication',$O365Object.auth_tokens.SharePointAdminOnline);
                }
                Else{
                    Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
                    break
                }
            }
            #Add ChildItems
            [void]$p.Add('ChildItems',$true);
            #Add Body
            [void]$p.Add('Data',$body_data);
            #Execute query
            Invoke-MonkeyCSOMRequest @p
        }
        ElseIf($PSCmdlet.ParameterSetName -eq "Current"){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMSite" -Params $PSBoundParameters
            $_Site = Get-MonkeyCSOMSite @p
            if($_Site){
                #Add Site to PsboundParameters
                [void]$PSBoundParameters.Add('Site',$_Site);
                Get-MonkeyCSOMSiteProperty @PSBoundParameters
            }
        }
        Else{
            If ($PSCmdlet.ParameterSetName -eq "Site"){
                $objectType = $PSBoundParameters['Site'] | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
                if ($null -ne $objectType -and $objectType -eq 'SP.Site'){
                    $Ep = $PSBoundParameters['Site'].Url
                }
                Else{
                    $msg = @{
                        MessageData = ($message.SPOInvalidSiteObjectMessage);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Warning';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('MonkeyCSOMInvalidSiteObject');
                    }
                    Write-Warning @msg
                    $Ep = $null
                }
            }
            Else{
                $Ep = $PSBoundParameters['EndPoint']
            }
            if($null -ne $Ep){
                if($PSBoundParameters.ContainsKey('AsUser') -and $PSBoundParameters['AsUser'].IsPresent){
                    #Set command parameters
                    $p = Set-CommandParameter -Command "Invoke-MonkeySPOAdminApi" -Params $PSBoundParameters
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
                    #Add EndPoint
                    $p.Item('Endpoint') = $Ep;
                    #Add ObjectPath
                    [void]$p.Add('ObjectPath','SiteProperties');
                    #Execute query
                    Invoke-MonkeySPOAdminApi @p
                }
                Else{
                    $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="34" ObjectPathId="33"/><ObjectPath Id="36" ObjectPathId="35"/><Query Id="37" ObjectPathId="35"><Query SelectAllProperties="true"><Properties/></Query></Query></Actions><ObjectPaths><Constructor Id="33" TypeId="{268004ae-ef6b-4e9b-8425-127220d84719}"/><Method Id="35" ParentId="33" Name="GetSitePropertiesByUrl"><Parameters><Parameter Type="String">${url}</Parameter><Parameter Type="Boolean">true</Parameter></Parameters></Method></ObjectPaths></Request>' -replace '\${url}', $Ep
                    #Set command parameters
                    $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMRequest" -Params $PSBoundParameters
                    #Remove Endpoint
                    [void]$p.Remove('Endpoint');
                    #Add authentication header if missing
                    if(!$p.ContainsKey('Authentication')){
                        if($null -ne $O365Object.auth_tokens.SharePointAdminOnline){
                            [void]$p.Add('Authentication',$O365Object.auth_tokens.SharePointAdminOnline);
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
    }
    End{
        #Nothing to do here
    }
}
