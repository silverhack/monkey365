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


Function Invoke-MonkeyCSOMPermission{
    <#
        .SYNOPSIS
		Get permissions applied on a particular object, such as: Web, List, Folder or List Item

        .DESCRIPTION
		Get permissions applied on a particular object, such as: Web, List, Folder or List Item

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyCSOMPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    [OutputType([System.Collections.Generic.List[System.Management.Automation.PSObject]])]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True, HelpMessage="SharePoint Object: Web, List, Folder or List Item")]
        [Object]$Object,

        [parameter(Mandatory= $True)]
        [Object]$Authentication,

        [parameter(Mandatory= $false)]
        [String]$Endpoint
    )
    Begin{
        if($Endpoint){
            [uri]$sps_uri = $Endpoint
        }
        else{
            [uri]$sps_uri = $Authentication.resource
        }
    }
    Process{
        #Set nulls
        $roleAssignments = $HasUniquePermissions = $null
        #Set generic list
        $PermissionCollection = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
        #Cast object
        $p = @{
            Object = $Object;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $objectType =  Get-MonkeyCSOMObjectType @p
        if($null -ne $objectType){
            #Add url to objectType
            if($null -ne $objectType.Path){
                $fullObjectPath = [System.Uri]::new($sps_uri,$objectType.Path)
                $objectType.Url = $fullObjectPath.ToString()
            }
            else{
                $objectType.Url = $sps_uri.ToString()
            }
        }
        #Clean object
        $Object = Update-MonkeyCSOMObject -Object $Object
        try{
            #Get role assignment assigned to the object
            $param = @{
                ClientObject = $Object;
                Properties = "RoleAssignments","HasUniqueRoleAssignments";
                Authentication = $Authentication;
                Endpoint = $sps_uri.AbsoluteUri;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $RoleAssignments = Get-MonkeyCSOMProperty @param
            #Get unique permissions
            $HasUniquePermissions = $RoleAssignments.HasUniqueRoleAssignments
            #Get role assignments
            $role_assignments = $RoleAssignments.RoleAssignments
        }
        catch{
            $msg = @{
                MessageData = ("Unable to get role assignments for {0}" -f $objectType.Url);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('GetPsPSPermission');
            }
            Write-Verbose @msg
            $HasUniquePermissions = $null
            $role_assignments = $null
        }
        if($null -ne $role_assignments){
            foreach($role in @($role_assignments)){
                #Get permission levels assigned to object and Member
                $p = @{
                    ClientObject = $role;
                    Properties = "Member","RoleDefinitionBindings";
                    Authentication = $Authentication;
                    Endpoint = $sps_uri.AbsoluteUri;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $uniquerole = Get-MonkeyCSOMProperty @p
                if($uniquerole){
                    $PermissionType = $PermissionLevels = $groupMembers = $GrantedThrough = $GroupUsers = $null
                    #Get the Principal Type: User, SP Group, AD Group
                    if($null -ne $uniquerole.Member){
                        $PermissionType = [PrincipalType]$uniquerole.Member.PrincipalType
                        #Check if the Principal is SharePoint group
                        if($PermissionType -eq "SharePointGroup"){
                            $p = @{
                                GroupId = $uniquerole.Member._ObjectIdentity_;
                                Authentication = $Authentication;
                                Endpoint = $sps_uri.AbsoluteUri;
                                InformationAction = $O365Object.InformationAction;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                            }
                            $groupMembers = Get-MonkeyCSOMGroupMember @p
                            #Leave Empty Groups
                            if(@($groupMembers).count -eq 0){
                                Continue
                            }
                            #$GroupUsers = ($groupMembers | Select-Object -ExpandProperty Title | Where-Object { $_ -ne "System Account"}) -join "; "
                            $GroupUsers = $groupMembers.Where({$_.Title -ne "System Account"})
                            if($GroupUsers.Length -eq 0) {
                                Continue
                            }
                            $GroupUsers = New-Object System.Collections.Generic.List[System.Management.Automation.PSObject]
                            #Get Real users
                            $grpmembers = $groupMembers.Where({$_.PrincipalType -eq 4}) | Select-Object -ExpandProperty Members -ErrorAction Ignore
                            if($grpmembers){
                                foreach($usr in @($grpmembers)){
                                    [void]$GroupUsers.Add($usr)
                                }
                            }
                            $tusers = $groupMembers.Where({$_.PrincipalType -eq 1})
                            if($tusers){
                                if($tusers){
                                    foreach($usr in @($tusers)){
                                        [void]$GroupUsers.Add($usr)
                                    }
                                }
                            }
                            #Granted through
                            $GrantedThrough = ("SharePoint Group: {0}"-f $uniquerole.Member.LoginName)
                        }
                        else{
                            $GrantedThrough = "Direct Permissions"
                            #Get UPN
                            try{
                                $userMember = $uniquerole.Member
                                $upn = $uniquerole.Member.LoginName.Split('|')[2]
                                $p = @{
                                    UserPrincipalName = $upn;
                                    BypassMFACheck = $True;
                                    APIVersion = 'beta';
                                    InformationAction = $O365Object.InformationAction;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                }
                                $User = Get-MonkeyMSGraphUser @p
                                #Populate metadata
                                foreach($elem in $userMember.PsObject.Properties){
                                    if($elem.Name -eq 'UserPrincipalName'){
                                        continue;
                                    }
                                    if($elem.Name -eq 'Id'){
                                        $User | Add-Member NoteProperty -name spoId -value $elem.Value -Force
                                    }
                                    else{
                                        $User | Add-Member NoteProperty -name $elem.Name -value $elem.Value -Force
                                    }
                                }
                                $GroupUsers = $User;
                            }
                            catch{
                                Write-Verbose $_
                                $GroupUsers = $uniquerole.Member;
                            }
                        }
                    }
                    #Get Permission level
                    if($null -ne $uniquerole.RoleDefinitionBindings){
                        $PermissionLevels = $uniquerole.RoleDefinitionBindings | Select-Object Name, Description
                        #Remove Limited Access
                        $PermissionLevels = $PermissionLevels | Where-Object { $_.Name -ne "Limited Access"}
                        #Leave Principals with no Permissions assigned
                        if(@($PermissionLevels).Count -eq 0) {
                            Continue
                        }
                    }
                    #Get PermissionObject
                    $PermObject = New-MonkeyCSOMPermissionObject -Object $objectType
                    if($null -ne $PermObject){
                        $PermObject.HasUniquePermissions = $HasUniquePermissions;
                        $PermObject.Users = $GroupUsers;
                        $PermObject.AppliedTo = $PermissionType;
                        $PermObject.Permissions = $PermissionLevels;
                        $PermObject.GrantedThrough = $GrantedThrough;
                        $PermObject.RoleAssignment = $uniquerole;
                        $PermObject.Description = ($PermissionLevels | Select-Object -ExpandProperty Description) -join  "; ";
                        $PermObject.Members = $groupMembers;
                        $PermObject.raw_object = $Object;
                        #Add to list
                        [void]$PermissionCollection.Add($PermObject);
                    }
                }
                else{
                    $msg = @{
                        MessageData = ($message.SPOPermissionObjectError -f $role._ObjectIdentity_);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Tags = @('SPSEmptyRoleAssignment');
                    }
                    Write-Verbose @msg
                }
            }
        }
        #return permissions
        #return , $PermissionCollection
        Write-Output $PermissionCollection -NoEnumerate
    }
    End{
        #Nothing to do here
    }
}