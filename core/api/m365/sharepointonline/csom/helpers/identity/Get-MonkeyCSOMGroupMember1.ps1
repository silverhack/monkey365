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

Function Get-MonkeyCSOMGroupMemberOld{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPSGroupMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$True, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory=$False, HelpMessage="Endpoint")]
        [String]$Endpoint,

        [parameter(Mandatory=$True, HelpMessage="Group Id")]
        [String]$GroupId
    )
    Begin{
        $out_obj = $null
        $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="320" ObjectPathId="276"><Query SelectAllProperties="true"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="IsHiddenInUI" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="PrincipalType" ScalarProperty="true" /><Property Name="AllowMembersEditMembership" ScalarProperty="true" /><Property Name="AllowRequestToJoinLeave" ScalarProperty="true" /><Property Name="AutoAcceptRequestToJoinLeave" ScalarProperty="true" /><Property Name="Description" ScalarProperty="true" /><Property Name="OnlyAllowMembersViewMembership" ScalarProperty="true" /><Property Name="OwnerTitle" ScalarProperty="true" /><Property Name="RequestToJoinLeaveEmailSetting" ScalarProperty="true" /></Properties></Query></Query><Query Id="321" ObjectPathId="277"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Identity Id="276" Name="{0}" /><Property Id="277" ParentId="276" Name="Users" /></ObjectPaths></Request>' -f $GroupId)
        $p = @{
            Authentication = $Authentication;
            Endpoint = $Endpoint;
            Data = $body_data;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $raw_data = Invoke-MonkeyCSOMRequest @p
    }
    Process{
        if($raw_data){
            if($null -ne $raw_data.psobject.Properties.Item('_Child_Items_')){
                $out_obj = $raw_data._Child_Items_
            }
            else{
                $out_obj = $raw_data
            }
        }
        #Remove System Account
        $out_obj = $out_obj | Where-Object {$null -ne $_ -and $_.Title -ne "System Account"} -ErrorAction Ignore
        foreach($obj in @($out_obj)){
            #Check if Admin group
            try{
                $GroupId = $obj.LoginName.Split('|')[2]
            }
            catch{
                $GroupId = $null
            }
            try{
                if($null -ne $GroupId -and $GroupId.Length -gt 37 -and $GroupId.Substring(36, 2) -eq "_o"){
                    $GroupId = $GroupId.Split('_')[0]
                    #Get group owners
                    if($O365Object.canRequestGroupsFromMsGraph){
                        $p = @{
                            GroupId = $GroupId;
                            Expand = 'Owners';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $Group = Get-MonkeyMSGraphGroup @p
                        if($null -ne $Group){
                            $obj | Add-Member NoteProperty -name Members -value $Group.owners
                        }
                    }
                    else{
                        $obj | Add-Member NoteProperty -name Members -value $null
                    }
                }
                elseIf ($null -ne $GroupId -and $obj.PrincipalType -eq 4 -and ($obj.LoginName -like '*federateddirectoryclaimprovider*')){
                    #Get group members
                    if($O365Object.canRequestGroupsFromMsGraph){
                        $p = @{
                            GroupId = $GroupId;
                            Expand = 'members';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $Group = Get-MonkeyMSGraphGroup @p
                        if($null -ne $Group){
                            $obj | Add-Member NoteProperty -name Members -value $Group.members
                        }
                    }
                    else{
                        $obj | Add-Member NoteProperty -name Members -value $null
                    }
                }
                elseIf ($null -ne $GroupId -and $obj.PrincipalType -eq 1){
                    #User detected
                    if($O365Object.canRequestUsersFromMsGraph){
                        $p = @{
                            UserPrincipalName = $GroupId;
                            BypassMFACheck = $True;
                            APIVersion = 'beta';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        $User = Get-MonkeyMSGraphUser @p
                        if($null -ne $User){
                            #Populate metadata
                            foreach($elem in $User.PsObject.Properties){
                                if($elem.Name -eq 'UserPrincipalName'){
                                    continue;
                                }
                                if($elem.Name -eq 'Id'){
                                    $obj | Add-Member NoteProperty -name spoId -value $elem.Value -Force
                                }
                                else{
                                    $obj | Add-Member NoteProperty -name $elem.Name -value $elem.Value -Force
                                }
                            }
                        }
                    }
                }
            }
            Catch{
                Write-Verbose $_
            }
        }
    }
    End{
        if($null -ne $out_obj){
            return $out_obj
        }
    }
}

