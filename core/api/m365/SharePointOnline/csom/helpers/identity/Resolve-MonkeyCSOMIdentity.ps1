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

Function Resolve-MonkeyCSOMIdentity{
    <#
        .SYNOPSIS
        Get users and group members from Microsoft 365

        .DESCRIPTION

        Get users and group members from Microsoft 365

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Resolve-MonkeyCSOMIdentity
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Sharepoint Identity object")]
        [Object]$InputObject,

        [parameter(Mandatory= $false, HelpMessage="Authentication object")]
        [Object]$Authentication,

        [parameter(Mandatory= $false, HelpMessage="SharePoint url")]
        [String]$Endpoint
    )
    Process{
        if($InputObject.PrincipalType -eq [principaltype]::User){
            if($O365Object.canRequestUsersFromMsGraph){
                $obj = $InputObject.loginName.Split('|')[-1]
                $msg = @{
                    MessageData = ("Getting user details for {0}" -f $obj);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMIdentityInfo');
                }
                Write-Information @msg
                $p = @{
                    UserId = $obj;
                    BypassMFACheck = $True;
                    APIVersion = 'beta';
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $user = Get-MonkeyMSGraphUser @p
                if($user){
                    $user
                }
                else{
                    $msg = @{
                        MessageData = ("Potentially orphaned object {0}" -f $obj);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('MonkeyCSOMIdentityOrphanedObjectInfo');
                    }
                    Write-Verbose @msg
                    $InputObject | Add-Member NoteProperty -name Orphaned -value $True -Force
                    #return object
                    $InputObject
                }
            }
            Else{
                $msg = @{
                    MessageData = ("User is not allowed to request users");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMIdentityInfo');
                }
                Write-Warning @msg
                #return InputObject
                $InputObject
            }
        }
        ElseIf($InputObject.PrincipalType -eq [principalType]::SharePointGroup){
            #Get Members
            #Set command parameters
            $p = Set-CommandParameter -Command "Get-MonkeyCSOMGroupMember" -Params $PSBoundParameters
            #Add ClientObject
            [void]$p.Add('GroupId',$InputObject._ObjectIdentity_);
            #Execute query
            $members = Get-MonkeyCSOMGroupMember @p
            if($members){
                #Set command parameters
                $p = Set-CommandParameter -Command "Resolve-MonkeyCSOMIdentity" -Params $PSBoundParameters
                #remove InputObject
                [void]$p.Remove('InputObject')
                $members._Child_Items_ | Resolve-MonkeyCSOMIdentity @p
            }
        }
        ElseIf($InputObject.PrincipalType -eq [principalType]::SecurityGroup){
            #Set reference
            [ref]$guid = [System.Guid]::Empty
            if($O365Object.canRequestGroupsFromMsGraph){
                $obj = $InputObject.loginName.Split('|')[-1]
                if($obj.Length -gt 36 -and $obj.Substring(36, 2) -eq "_o"){
                    $obj = $obj.Split('_')[0]
                    $msg = @{
                        MessageData = ("Getting group owners from {0}" -f $obj);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('MonkeyCSOMIdentityInfo');
                    }
                    Write-Information @msg
                    $p = @{
                        GroupId = $obj;
                        Expand = 'Owners';
                        ApiVersion = 'beta';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $grp = Get-MonkeyMSGraphGroup @p
                    if($null -ne $grp){
                        $grp.owners
                    }
                    else{
                        $msg = @{
                            MessageData = ("Potentially orphaned object {0}" -f $obj);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('MonkeyCSOMIdentityOrphanedObjectInfo');
                        }
                        Write-Verbose @msg
                        $InputObject | Add-Member NoteProperty -name Orphaned -value $True -Force
                        #return object
                        $InputObject
                    }
                }
                ElseIf([System.Guid]::TryParse($obj,$guid)){
                    #Check if group exists
                    $p = @{
                        GroupId = $obj;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $grp = Get-MonkeyMSGraphGroup @p
                    if($grp){
                        $p = @{
                            GroupId = $obj;
                            Parents = @(('{0}') -f $obj);
                            APIVersion = 'beta';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                        }
                        Get-MonkeyMSGraphGroupTransitiveMember @p
                    }
                    Else{
                        $msg = @{
                            MessageData = ("Potentially orphaned object {0}" -f $obj);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $O365Object.InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('MonkeyCSOMIdentityOrphanedObjectInfo');
                        }
                        Write-Verbose @msg
                        $InputObject | Add-Member NoteProperty -name Orphaned -value $True -Force
                        #return object
                        $InputObject
                    }
                }
                ElseIf($InputObject.loginName -match ("c:0-.f|rolemanager|spo-grid-all-users/{0}" -f $O365Object.TenantId)){
                    $msg = @{
                        MessageData = ("{0} group detected" -f $InputObject.Title);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'Verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('MonkeyCSOMIdentityInfo');
                    }
                    Write-Verbose @msg
                    #return InputObject
                    $InputObject
                }
                ElseIf($InputObject.loginName -match "c:0\(.s|true"){
                    $msg = @{
                        MessageData = ("{0} group detected" -f $InputObject.Title);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('MonkeyCSOMIdentityInfo');
                    }
                    Write-Verbose @msg
                    #return InputObject
                    $InputObject
                }
                Else{
                    $obj = $InputObject.loginName.Split('|')[-1]
                    $msg = @{
                        MessageData = ("Object {0} detected" -f $obj);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('SPOIdentityInfo');
                    }
                    Write-Verbose @msg
                    #return InputObject
                    $InputObject
                }
            }
            Else{
                $msg = @{
                    MessageData = ("User is not allowed to request groups");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyCSOMIdentityInfo');
                }
                Write-Warning @msg
                #return InputObject
                $InputObject
            }
        }
    }
}
