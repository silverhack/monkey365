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


Function Get-MonkeyCSOMExternalUser{
    <#
        .SYNOPSIS
		Get external users from Sharepoint Online Web

        .DESCRIPTION
		Get external users from Sharepoint Online Web

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMExternalUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [Parameter(Mandatory= $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName  = $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web
    )
    Begin{
        #Set generic list
        $externalCollection = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        #Get Access Token for SharePoint admin
		$sps_admin_auth = $O365Object.auth_tokens.SharePointAdminOnline
    }
    Process{
        if($O365Object.isSharePointAdministrator){
            #Check for objectType
            if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
                $msg = @{
				    MessageData = ($message.SPSCheckSiteForExternalUsers -f $Web.url);
				    callStack = (Get-PSCallStack | Select-Object -First 1);
				    logLevel = 'info';
				    InformationAction = $InformationAction;
				    Tags = @('SPSExternalUsersInfo');
			    }
			    Write-Information @msg
                $position = 0;
                while ($true){
                    $body_data = '<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><ObjectPath Id="320" ObjectPathId="319" /><Query Id="321" ObjectPathId="319"><Query SelectAllProperties="false"><Properties><Property Name="TotalUserCount" ScalarProperty="true" /><Property Name="UserCollectionPosition" ScalarProperty="true" /><Property Name="ExternalUserCollection"><Query SelectAllProperties="false"><Properties /></Query><ChildItemQuery SelectAllProperties="false"><Properties><Property Name="DisplayName" ScalarProperty="true" /><Property Name="InvitedAs" ScalarProperty="true" /><Property Name="UniqueId" ScalarProperty="true" /><Property Name="AcceptedAs" ScalarProperty="true" /><Property Name="WhenCreated" ScalarProperty="true" /><Property Name="InvitedBy" ScalarProperty="true" /></Properties></ChildItemQuery></Property></Properties></Query></Query></Actions><ObjectPaths><Method Id="319" ParentId="316" Name="GetExternalUsersForSite"><Parameters><Parameter Type="String">${site}</Parameter><Parameter Type="Int32">${position}</Parameter><Parameter Type="Int32">50</Parameter><Parameter Type="Null" /><Parameter Type="Enum">0</Parameter></Parameters></Method><Constructor Id="316" TypeId="{e45fd516-a408-4ca4-b6dc-268e2f1f0f83}" /></ObjectPaths></Request>' -replace '\${site}',$Web.Url -replace '\${position}',$position
                    $p = @{
                        Authentication = $sps_admin_auth;
                        Data = $body_data;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    #Construct query
                    $raw_external = Invoke-MonkeyCSOMRequest @p
                    if($null -ne $raw_external -and $null -ne $raw_external.PsObject.Properties.Item('ExternalUserCollection')){
                        #Get Position
                        $position = $raw_external.UserCollectionPosition
                        #Get users
                        $external_users = $raw_external.ExternalUserCollection._Child_Items_
                        if($external_users){
                            foreach($user in @($external_users)){
                                $user | Add-Member NoteProperty -Name SiteUrl -Value $Web.Url
                                #Try to get Date
                                try{
                                    if($null -ne $user.PsObject.Properties.Item('WhenCreated') -and $null -ne $user.WhenCreated){
                                        $user.WhenCreated = Convert-SharePointOnlineDateString -Date $user.WhenCreated
                                    }
                                }
                                catch{
                                    $msg = @{
                                        MessageData = ($_);
                                        callStack = (Get-PSCallStack | Select-Object -First 1);
                                        logLevel = 'verbose';
                                        Verbose = $O365Object.verbose;
                                        Tags = @('SPOInvalidDateTimeObject');
                                    }
                                    Write-Verbose @msg
                                }
                                #Add to list
                                [void]$externalCollection.Add($user)
                            }
                        }
                        if($position -eq -1 -or $position -eq $raw_external.TotalUserCount){
                            break;
                        }
                    }
                    else{
                        break;
                    }
                }
            }
            else{
                $msg = @{
                    MessageData = ($message.SPOInvalieWebObjectMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('SPOInvalidWebObject');
                }
                Write-Warning @msg
            }
        }
        else{
            $msg = @{
                MessageData = ($message.SPSAdminErrorMessage -f $O365Object.userPrincipalName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Verbose';
                InformationAction = $InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('SPOExternalUserPermission');
            }
            Write-Verbose @msg
        }
    }
    End{
        #return external users
        #return , $externalCollection
        Write-Output $externalCollection -NoEnumerate
    }
}
