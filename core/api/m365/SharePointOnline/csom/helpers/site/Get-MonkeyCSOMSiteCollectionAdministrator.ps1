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
    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$True, HelpMessage="SPO Web")]
        [Object]$Web
    )
    Begin{
        #Get Site
        [xml]$body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey 365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="6" ObjectPathId="5" /><Query Id="7" ObjectPathId="5"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /><Property Name="Email" ScalarProperty="true" /><Property Name="IsShareByEmailGuestUser" ScalarProperty="true" /><Property Name="IsSiteAdmin" ScalarProperty="true" /><Property Name="UserId" ScalarProperty="true" /><Property Name="IsHiddenInUI" ScalarProperty="true" /><Property Name="PrincipalType" ScalarProperty="true" /><Property Name="Alerts"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Title" ScalarProperty="true" /><Property Name="Status" ScalarProperty="true" /></Properties></ChildItemQuery></Property><Property Name="Groups"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /></Properties></ChildItemQuery></Property></Properties><QueryableExpression><Where><Test><Parameters><Parameter Name="u" /></Parameters><Body><ExpressionProperty Name="IsSiteAdmin"><ExpressionParameter Name="u" /></ExpressionProperty></Body></Test><Object><QueryableObject /></Object></Where></QueryableExpression></ChildItemQuery></Query></Actions><ObjectPaths><Property Id="5" ParentId="3" Name="SiteUsers" /><Property Id="3" ParentId="1" Name="Web" /><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current" /></ObjectPaths></Request>'
        #Set generic list
        $siteAdminCollection = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
    }
    Process{
        $effectiveUsers = $all_users = $null
        #Check for objectType
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            $p = @{
                Authentication = $Authentication;
                Data = $body_data;
                ChildItems = $True;
                Endpoint = $Web.Url;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            #Execute query
            $siteAdmins = Invoke-MonkeyCSOMRequest @p
            if($siteAdmins){
                $p = @{
                    Groups = $siteAdmins;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                #Execute query
                $all_admins = Resolve-MonkeyCSOMToM365GroupMember @p
                if($null -ne $all_admins){
                    [array]$all_users = $all_admins | Where-Object { $_.principalType -eq [PrincipalType]::User }
                    #Add group members
                    [array]$effectiveUsers = $all_admins | Where-Object { $_.principalType -eq [PrincipalType]::SecurityGroup } | Select-Object -ExpandProperty Members -ErrorAction Ignore
                    $rest_users = @()
                    if($null -ne $all_users -and $null -ne $effectiveUsers){
                        #Check email
                        foreach($user in @($all_users)){
                            $match = $effectiveUsers | Where-Object {$_.UserPrincipalName -eq $user.Email} -ErrorAction Ignore
                            if($null -eq $match){
                                #Add user
                                $rest_users+=$user;
                            }
                        }
                        if($rest_users.Count -gt 0){
                            $effectiveUsers+=$rest_users
                        }
                    }
                    else{
                        if($all_users){
                            $effectiveUsers = $all_users
                        }
                    }
                    $site_admins = [pscustomobject]@{
						site = $Web.Url;
						Title = $Web.Title;
						users = ($all_admins | Where-Object { $_.principalType -eq [PrincipalType]::User })
						aad_groups = ($all_admins | Where-Object { $_.principalType -eq [PrincipalType]::SecurityGroup })
						effective_users = $effectiveUsers;
						raw = $all_admins;
					}
                    #Add to list
                    [void]$siteAdminCollection.Add($site_admins)
                }
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SPOInvalieWebObjectMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $InformationAction;
                Tags = @('SPOInvalidWebObject');
            }
            Write-Warning @msg
        }
    }
    End{
        #return , $siteAdminCollection
        Write-Output $siteAdminCollection -NoEnumerate
    }
}
