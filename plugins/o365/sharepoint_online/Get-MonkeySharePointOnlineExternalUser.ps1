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


Function Get-MonkeySPSExternalUser{
    <#
        .SYNOPSIS
		Plugin to get information about SPS external users

        .DESCRIPTION
		Plugin to get information about SPS external users

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPSExternalUser
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
        #Get Access Token for Sharepoint admin
        $sps_admin_auth = $O365Object.auth_tokens.SharepointAdminOnline
        #Check if user is sharepoint administrator
        $isSharepointAdministrator = Test-IsUserSharepointAdministrator
        #Set new array
        $sps_external_users = @()
    }
    Process{
        if($isSharepointAdministrator){
            $msg = @{
                MessageData = ($message.MonkeyGenericTaskMessage -f $pluginId, "Sharepoint Online external users", $O365Object.TenantID);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $InformationAction;
                Tags = @('SPSExternalUsersInfo');
            }
            Write-Information @msg
            #Get all webs for user
            $allowed_sites = Get-MonkeySPSWebsForUser
            #Getting external users for each site
            foreach($site in $allowed_sites){
                $msg = @{
                    MessageData = ($message.SPSCheckSiteForExternalUsers -f $site.url);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('SPSExternalUsersInfo');
                }
                Write-Information @msg
                #body
                $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="320" ObjectPathId="319" /><Query Id="321" ObjectPathId="319"><Query SelectAllProperties="false"><Properties><Property Name="TotalUserCount" ScalarProperty="true" /><Property Name="UserCollectionPosition" ScalarProperty="true" /><Property Name="ExternalUserCollection"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="DisplayName" ScalarProperty="true" /><Property Name="InvitedAs" ScalarProperty="true" /><Property Name="UniqueId" ScalarProperty="true" /><Property Name="AcceptedAs" ScalarProperty="true" /><Property Name="WhenCreated" ScalarProperty="true" /><Property Name="InvitedBy" ScalarProperty="true" /></Properties></ChildItemQuery></Property></Properties></Query></Query></Actions><ObjectPaths><Method Id="319" ParentId="316" Name="GetExternalUsersForSite"><Parameters><Parameter Type="String">${site}</Parameter><Parameter Type="Int32">${position}</Parameter><Parameter Type="Int32">50</Parameter><Parameter Type="Null" /><Parameter Type="Enum">0</Parameter></Parameters></Method><Constructor Id="316" TypeId="{e45fd516-a408-4ca4-b6dc-268e2f1f0f83}" /></ObjectPaths></Request>' -replace '\${site}', $site.Url -replace '\${position}', 0
                #Set object metadata
                $objectMetadata = @{
                    CheckValue = 1;
                    isEqualTo =320;
                    GetValue =4;
                }
                $param = @{
                    Authentication = $sps_admin_auth;
                    Content_Type = 'application/json; charset=utf-8';
                    Data = $body_data;
                    objectMetadata= $objectMetadata;
                }
                #call SPS
                $raw_data = Invoke-MonkeySPSDefaultUrlRequest @param
                if([bool]($raw_data.PSobject.Properties.name -match "ExternalUserCollection")){
                    $users = $raw_data.ExternalUserCollection._Child_Items_
                    foreach($user in $users){
                        $user | Add-Member NoteProperty -name SiteUrl -value $site.Url
                        $user | Add-Member NoteProperty -name Site -value $site
                    }
                    $sps_external_users+= $raw_data.ExternalUserCollection._Child_Items_
                }
            }
        }
    }
    End{
        if($sps_external_users){
            $sps_external_users.PSObject.TypeNames.Insert(0,'Monkey365.SharePoint.Tenant.Externalusers')
            [pscustomobject]$obj = @{
                Data = $sps_external_users
            }
            $returnData.o365_spo_external_users = $obj
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
