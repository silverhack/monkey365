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

Function Get-MonkeyCSOMSiteCollectionAdministrator{
    <#
        .SYNOPSIS
        Get site collection administrators from SharePoint Online

        .DESCRIPTION
        Get site collection administrators from SharePoint Online

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMSiteCollectionAdministrator
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding(DefaultParameterSetName = 'Current')]
    #[OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$false, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(Mandatory=$false, ParameterSetName = 'Site', ValueFromPipeline = $true, HelpMessage="Web Object")]
        [Object]$Site,

        [parameter(Mandatory=$false, ParameterSetName = 'Endpoint', HelpMessage="SharePoint Url")]
        [Object]$Endpoint
    )
    Begin{
        #Get Site
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="6" ObjectPathId="5" /><Query Id="7" ObjectPathId="5"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /><Property Name="Email" ScalarProperty="true" /><Property Name="IsShareByEmailGuestUser" ScalarProperty="true" /><Property Name="IsSiteAdmin" ScalarProperty="true" /><Property Name="UserId" ScalarProperty="true" /><Property Name="IsHiddenInUI" ScalarProperty="true" /><Property Name="PrincipalType" ScalarProperty="true" /><Property Name="Alerts"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Title" ScalarProperty="true" /><Property Name="Status" ScalarProperty="true" /></Properties></ChildItemQuery></Property><Property Name="Groups"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /></Properties></ChildItemQuery></Property></Properties><QueryableExpression><Where><Test><Parameters><Parameter Name="u" /></Parameters><Body><ExpressionProperty Name="IsSiteAdmin"><ExpressionParameter Name="u" /></ExpressionProperty></Body></Test><Object><QueryableObject /></Object></Where></QueryableExpression></ChildItemQuery></Query></Actions><ObjectPaths><Property Id="5" ParentId="3" Name="SiteUsers" /><Property Id="3" ParentId="1" Name="Web" /><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current" /></ObjectPaths></Request>'
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq "Endpoint" -or $PSCmdlet.ParameterSetName -eq "Current"){
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMSite" -Params $PSBoundParameters
            $_Site = Get-MonkeyCSOMSite @p
            if($_Site){
                $_Site | Get-MonkeyCSOMSiteCollectionAdministrator @PSBoundParameters
            }
        }
    }
    End{
        foreach($_Site in @($PSBoundParameters['Site']).Where({$null -ne $_})){
            $objectType = $_Site | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
            if ($null -ne $objectType -and $objectType -eq 'SP.Site'){
                #Set command parameters
                $p = Set-CommandParameter -Command "Invoke-MonkeyCSOMRequest" -Params $PSBoundParameters
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
                #Update EndPoint
                $p.Item('Endpoint') = $_Site.Url;
                #Add Data
                [void]$p.Add('Data',$body_data);
                #Execute query
                $members = Invoke-MonkeyCSOMRequest @p
                $objectType = $members | Select-Object -ExpandProperty _ObjectType_ -ErrorAction Ignore
                if ($null -ne $objectType -and $objectType -eq 'SP.UserCollection'){
                    $p = Set-CommandParameter -Command "Resolve-MonkeyCSOMIdentity" -Params $PSBoundParameters
                    $members._Child_Items_ | Resolve-MonkeyCSOMIdentity @p
                }
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
            }
        }
    }
}


