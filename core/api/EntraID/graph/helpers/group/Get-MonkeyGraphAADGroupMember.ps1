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


Function Get-MonkeyGraphAADGroupMember{
    <#
        .SYNOPSIS
		Get Group Members

        .DESCRIPTION
		Get Group Members

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADGroupMember
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Group,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$GroupId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [array]$all_groups
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        $my_grp = $group_members = $my_grp_id = $null
        #Get Configuration
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.graph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.Verbose;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
        $all_users = New-Object System.Collections.Generic.List[System.Object]
        if($PSBoundParameters.ContainsKey('Group') -and $PSBoundParameters.Group){
            $my_grp = $PSBoundParameters.Group
            $my_grp_id = $PSBoundParameters.Group.GroupId
        }
        elseif($PSBoundParameters.ContainsKey('GroupId') -and $PSBoundParameters.GroupId){
            #Get group by Id
            $my_grp = Get-MonkeyGraphAADObjectById -ObjectId $PSBoundParameters.GroupId
            $my_grp_id = $PSBoundParameters.GroupId
        }
        if(-NOT $PSBoundParameters.ContainsKey('all_groups') -and $null -ne $my_grp){
            #Set array and add groupId
            $all_groups = @()
            $all_groups+=$my_grp.objectId
        }
    }
    Process{
        if($null -ne $my_grp){
            $msg = @{
                MessageData = ($message.GroupMembersMessage -f $my_grp.objectId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $O365Object.InformationAction;
			    Debug = $O365Object.Debug;
                Tags = @('AzureGraphGroupMember');
            }
            Write-Debug @msg
            $params = @{
                Authentication = $AADAuth;
                ObjectType = "groups";
                ObjectId = $my_grp.objectId;
                Relationship = 'members';
                ObjectDisplayName = $my_grp.displayName;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $aadConf.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.Verbose;
			    Debug = $O365Object.Debug;
            }
            $group_members = Get-MonkeyGraphLinkedObject @params
        }
        else{
            $msg = @{
                MessageData = ($message.AzureOrphanedIdentityMessage -f $my_grp_id, $O365Object.current_subscription.subscriptionId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureOrphanedIdentity');
            }
            Write-Warning @msg
        }
        #Get All users
        if($null -ne $group_members){
            foreach($member in $group_members){
                try{
                    if($member.objectType -eq "User"){
                        [void]$all_users.Add($member)
                    }
                    elseif($member.objectType -eq "Group"){
                        $msg = @{
                            MessageData = ($message.NestedGroupMessageInfo -f $member.displayName, $my_grp.displayName);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'debug';
                            InformationAction = $O365Object.InformationAction;
			                Debug = $O365Object.Debug;
                            Tags = @('AzureGraphGroupMembers');
                        }
                        Write-Debug @msg
                        if($member.objectId -notin $all_groups){
                            #add to array
                            $all_groups +=$member.objectId
                            $p = @{
                                Group = $member;
                                all_groups = $all_groups;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.Verbose;
			                    Debug = $O365Object.Debug;
                            }
                            Get-MonkeyGraphAADGroupMember @p
                        }
                        else{
                            $msg = @{
                                MessageData = ($message.PotentialNestedGroupMessage -f $member.displayName, $my_grp.displayName);
                                callStack = (Get-PSCallStack | Select-Object -First 1);
                                logLevel = 'debug';
                                InformationAction = $O365Object.InformationAction;
			                    Debug = $O365Object.Debug;
                                Tags = @('AzureGraphGroupMember');
                            }
                            Write-Debug @msg
                        }
                    }
                }
                catch{
                    $msg = @{
                        MessageData = ($message.GroupMemberErrorMessage -f $member.objectId);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'debug';
                        InformationAction = $O365Object.InformationAction;
			            Debug = $O365Object.Debug;
                        Tags = @('AzureGraphGroupMember');
                    }
                    Write-Debug @msg
                    $msg = @{
                        MessageData = ($_);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'error';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureGraphGroupMember');
                    }
                    Write-Error @msg
                }
            }
        }
    }
    End{
        if($all_users.Count -gt 0){
            $all_users
        }
    }
}

