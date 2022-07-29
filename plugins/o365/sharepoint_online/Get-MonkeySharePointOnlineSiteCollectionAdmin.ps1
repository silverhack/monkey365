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


Function Get-MonkeySharePointOnlineSiteCollectionAdmin{
    <#
        .SYNOPSIS
		Plugin to get information about SPS site collection admins

        .DESCRIPTION
		Plugin to get information about SPS site collection admins

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySharePointOnlineSiteCollectionAdmin
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $false, HelpMessage="Background Plugin ID")]
        [String]$pluginId
    )
    Begin{
        #Get Access Token from SPO
        $sps_auth = $O365Object.auth_tokens.SharepointOnline
        $site_collection_admin_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="6" ObjectPathId="5" /><Query Id="7" ObjectPathId="5"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /><Property Name="Email" ScalarProperty="true" /><Property Name="IsShareByEmailGuestUser" ScalarProperty="true" /><Property Name="IsSiteAdmin" ScalarProperty="true" /><Property Name="UserId" ScalarProperty="true" /><Property Name="IsHiddenInUI" ScalarProperty="true" /><Property Name="PrincipalType" ScalarProperty="true" /><Property Name="Alerts"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Title" ScalarProperty="true" /><Property Name="Status" ScalarProperty="true" /></Properties></ChildItemQuery></Property><Property Name="Groups"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /></Properties></ChildItemQuery></Property></Properties><QueryableExpression><Where><Test><Parameters><Parameter Name="u" /></Parameters><Body><ExpressionProperty Name="IsSiteAdmin"><ExpressionParameter Name="u" /></ExpressionProperty></Body></Test><Object><QueryableObject /></Object></Where></QueryableExpression></ChildItemQuery></Query></Actions><ObjectPaths><Property Id="5" ParentId="3" Name="SiteUsers" /><Property Id="3" ParentId="1" Name="Web" /><StaticProperty Id="1" TypeId="{3747adcd-a3c3-41b9-bfab-4a64dd2f1e0a}" Name="Current" /></ObjectPaths></Request>'
        $all_admins = @()
    }
    Process{
        $msg = @{
            MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Sharepoint Online site collection admins", $O365Object.TenantID);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'info';
            InformationAction = $InformationAction;
            Tags = @('SPSSiteCollectionAdminInfo');
        }
        Write-Information @msg
        #Get all webs for user
        $allowed_sites = Get-MonkeySPSWebsForUser
        #Getting users & groups for each site
        foreach($site in $allowed_sites){
            #Set object metadata
            $objectMetadata = @{
                CheckValue = 3;
                isEqualTo =7;
                GetValue =4;
                ChildItems = '';
            }
            #Set param
            $param = @{
                Authentication = $sps_auth;
                Content_Type = 'application/json; charset=utf-8';
                Data = $site_collection_admin_data;
                objectMetadata= $objectMetadata;
                endpoint = $site.Url;
            }
            #execute query SPS
            $site_admins = Invoke-MonkeySPSDefaultUrlRequest @param
            if($site_admins){
                #Convert values
                foreach($element in $site_admins){
                    $element.PrincipalType = [PrincipalType]$element.PrincipalType
                }
                #Create array to store effective site admin users
                $effective_admins = @()
                #Getting users from Graph
                $users = ($site_admins | Where-Object {$_.principalType -eq "User"})
                if($null -ne $users){
                    $effective_admins +=$users
                }
                #Getting all effective users
                $aad_groups = ($site_admins | Where-Object {$_.principalType -eq "SecurityGroup"})
                if($null -ne $aad_groups){
                    foreach($group in $aad_groups){
                        $group_id = $group.LoginName.Split('|')[-1]
                        if($group_id.Contains('_o')){
                            $group_id = $group_id.Split('_')[0]
                            #Execute Query
                            $effective_admins += Get-PSGraphGroupOwner -group_id $group_id
                        }
                        else{
                            $param = @{
                                group_id= $group_id;
                                Parents = @($group_id);
                            }
                            #Execute Query
                            $effective_admins += Get-PSGraphGroupMember @param
                        }
                    }
                    $site_collection = [PsCustomObject]@{
                        site = $site.Url;
                        Title = $site.Title;
                        users = ($site_admins | Where-Object {$_.principalType -eq "User"})
                        aad_groups = ($site_admins | Where-Object {$_.principalType -eq "SecurityGroup"})
                        effective_users = $effective_admins;
                        raw = $site_admins;
                        raw_site = $site;
                    }
                    #Add to array
                    $all_admins+=$site_collection
                }
            }
        }
    }
    End{
        if($all_admins){
            $all_admins.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.SiteCollection.Admins')
            [pscustomobject]$obj = @{
                Data = $all_admins
            }
            $returnData.o365_spo_site_admins = $obj
        }
        else{
            $msg = @{
                MessageData = ($message.MonkeyEmptyResponseMessage -f "Sharepoint Online External Users", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('SPSExternalUsersEmptyResponse');
            }
            Write-Warning @msg
        }
    }
}
