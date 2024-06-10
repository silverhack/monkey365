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

Function Get-MonkeyCSOMGroupMember{
    <#
        .SYNOPSIS
        Get group members from SharePoint Online Group id

        .DESCRIPTION
        Get group members from SharePoint Online Group id

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMGroupMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Group Id")]
        [String]$GroupId,

        [parameter(Mandatory=$False, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, HelpMessage="Endpoint")]
        [String]$Endpoint
    )
    Process{
        try{
            $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="320" ObjectPathId="276"><Query SelectAllProperties="true"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="IsHiddenInUI" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="PrincipalType" ScalarProperty="true" /><Property Name="AllowMembersEditMembership" ScalarProperty="true" /><Property Name="AllowRequestToJoinLeave" ScalarProperty="true" /><Property Name="AutoAcceptRequestToJoinLeave" ScalarProperty="true" /><Property Name="Description" ScalarProperty="true" /><Property Name="OnlyAllowMembersViewMembership" ScalarProperty="true" /><Property Name="OwnerTitle" ScalarProperty="true" /><Property Name="RequestToJoinLeaveEmailSetting" ScalarProperty="true" /></Properties></Query></Query><Query Id="321" ObjectPathId="277"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Identity Id="276" Name="{0}" /><Property Id="277" ParentId="276" Name="Users" /></ObjectPaths></Request>' -f $GroupId)
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
            #Add endpoint
            [void]$p.Add('Data',$body_data);
            Invoke-MonkeyCSOMRequest @p
        }
        Catch{
            $msg = @{
                MessageData = ("Unable to get group members for {0}" -f $GroupId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('MonkeyCSOMGroupMemberError');
            }
            Write-Verbose @msg
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Error';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('MonkeyCSOMGroupMemberError');
            }
            Write-Error $_
        }
    }
}
