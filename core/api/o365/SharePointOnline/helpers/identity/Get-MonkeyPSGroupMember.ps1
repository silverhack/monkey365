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

Function Get-MonkeyPSGroupMember{
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
        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$endpoint,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$group_id
    )
    Begin{
        $body_data = ('<Request AddExpandoFieldTypeSuffix="true" SchemaVersion="15.0.0.0" LibraryVersion="16.0.0.0" ApplicationName="Monkey365" xmlns="http://schemas.microsoft.com/sharepoint/clientquery/2009"><Actions><Query Id="320" ObjectPathId="276"><Query SelectAllProperties="true"><Properties><Property Name="Id" ScalarProperty="true" /><Property Name="IsHiddenInUI" ScalarProperty="true" /><Property Name="LoginName" ScalarProperty="true" /><Property Name="Title" ScalarProperty="true" /><Property Name="PrincipalType" ScalarProperty="true" /><Property Name="AllowMembersEditMembership" ScalarProperty="true" /><Property Name="AllowRequestToJoinLeave" ScalarProperty="true" /><Property Name="AutoAcceptRequestToJoinLeave" ScalarProperty="true" /><Property Name="Description" ScalarProperty="true" /><Property Name="OnlyAllowMembersViewMembership" ScalarProperty="true" /><Property Name="OwnerTitle" ScalarProperty="true" /><Property Name="RequestToJoinLeaveEmailSetting" ScalarProperty="true" /></Properties></Query></Query><Query Id="321" ObjectPathId="277"><Query SelectAllProperties="true"><Properties /></Query><ChildItemQuery SelectAllProperties="true"><Properties /></ChildItemQuery></Query></Actions><ObjectPaths><Identity Id="276" Name="{0}" /><Property Id="277" ParentId="276" Name="Users" /></ObjectPaths></Request>' -f $group_id)
        $param = @{
            Authentication = $Authentication;
            endpoint = $endpoint;
            Data = $body_data
        }
        $raw_data = Invoke-MonkeySPSUrlRequest @param
    }
    Process{
        if($raw_data){
            if($raw_data.psobject.Properties.Item('_Child_Items_')){
                $out_obj = $raw_data._Child_Items_
            }
            else{
                $out_obj = $raw_data
            }
        }
    }
    End{
        if($null -ne $out_obj){
            return $out_obj
        }
    }
}
