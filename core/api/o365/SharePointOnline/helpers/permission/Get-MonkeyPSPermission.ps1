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


Function Get-MonkeyPSPermission{
    <#
        .SYNOPSIS
		Function to Get permissions applied on a particular object, such as: Web, List, Folder or List Item

        .DESCRIPTION
		Function to Get permissions applied on a particular object, such as: Web, List, Folder or List Item

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPSPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(Mandatory= $True)]
        [Object]$object,

        [parameter(Mandatory= $True)]
        [Object]$Authentication,

        [parameter(Mandatory= $false)]
        [String]$Endpoint
    )
    Begin{
        $regexGuid = '\{?(([0-9a-f]){8}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){4}-([0-9a-f]){12})\}?'
        $PermissionCollection = $roleAssignments = $HasUniquePermissions = $ObjectTitle = $ObjectURL = $null
        if($Endpoint){
            [uri]$sps_uri = $Endpoint
        }
        else{
            [uri]$sps_uri = $Authentication.resource
        }
        #Get Guid of object Element
        try{
            if($object.UniqueId){
                if($object.UniqueId -match $regexGuid){
                    $ObjectTitle = $Matches[1]
                }
            }
        }
        catch{
            $ObjectTitle = $null
        }
        #Determine the type of the object
        try{
            Switch($object._ObjectType_.ToString()){
                "SP.Web"{
                    $ObjectType = "Web";
                    $ObjectURL = $object.URL;
                    $ObjectTitle = $object.Title;
                    #Verbose message
                    $msg = @{
                        MessageData = ($message.SPSWorkingMessage -f $ObjectTitle, "Web");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $InformationAction;
                        Tags = @('SPSWebPermissionInfo');
                    }
                    Write-Verbose @msg
                }
                "SP.ListItem"{
                    if($object.FileSystemObjectType -eq [FileSystemObjectType]::Folder){
                        $ObjectType = "Folder";
                        if($null -eq $ObjectTitle){
                            if($object.Title){
                                $ObjectTitle = $object.Title
                            }
                            elseif($object.FileLeafRef){
                                $ObjectTitle = $object.FileLeafRef
                            }
                            else{
                                #Get Folder name
                                $param = @{
                                    clientObject = $object;
                                    properties = "Folder";
                                    Authentication = $Authentication;
                                    endpoint = $sps_uri.AbsoluteUri;
                                    executeQuery = $True;
                                }
                                $Folder = Get-MonkeySPSProperty @param
                                $ObjectTitle = $Folder.Folder.Name
                                $ObjectURL = ("{0}://{1}/{2}" -f $sps_uri.Scheme, $sps_uri.DnsSafeHost,$Folder.Folder.ServerRelativeUrl)
                            }
                        }
                        $ObjectURL = ("{0}://{1}/{2}" -f $sps_uri.Scheme, $sps_uri.DnsSafeHost,$object.FileRef)
                        #Verbose message
                        $msg = @{
                            MessageData = ($message.SPSWorkingMessage -f $ObjectTitle, "folder");
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Tags = @('SPSFolderPermissionInfo');
                        }
                        Write-Verbose @msg
                    }
                    elseif($object.FileSystemObjectType -eq [FileSystemObjectType]::File){
                        #Set object type
                        $ObjectType = "File"
                        #Set object url
                        $ObjectURL = ("{0}://{1}/{2}" -f $sps_uri.Scheme, $sps_uri.DnsSafeHost,$object.FileRef)
                        if($null -eq $ObjectTitle){
                            if($null -ne $object.Title){
                                $ObjectTitle = $object.Title
                            }
                            elseif($object.FileLeafRef){
                                $ObjectTitle = $object.FileLeafRef
                            }
                            else{
                                #Get File name
                                $param = @{
                                    clientObject = $object;
                                    properties = "File", "ParentList";
                                    Authentication = $Authentication;
                                    endpoint = $sps_uri.AbsoluteUri;
                                    executeQuery = $True;
                                }
                                $File = Get-MonkeySPSProperty @param
                                if($null -ne $File){
                                    try{
                                        $ObjectTitle = $File.File.Name
                                    }
                                    catch{
                                        $ObjectTitle = $null
                                    }
                                }
                            }
                        }
                        #Verbose message
                        $msg = @{
                            MessageData = ($message.SPSWorkingMessage -f $ObjectTitle, "file");
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Tags = @('SPSFilePermissionInfo');
                        }
                        Write-Verbose @msg
                    }
                    else{#Invalid?
                        #Set object type
                        $ObjectType = $object._ObjectType_
                        if($null -eq $ObjectTitle){
                            $ObjectTitle = $object.FileLeafRef
                        }
                        #Verbose message
                        $msg = @{
                            MessageData = ($message.SPSWorkingMessage -f $ObjectTitle, $ObjectType);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Tags = @('SPSFilePermissionInfo');
                        }
                        Write-Verbose @msg
                        #Set object url
                        $ObjectURL = ("{0}://{1}/{2}" -f $sps_uri.Scheme, $sps_uri.DnsSafeHost,$object.FileRef)
                    }
                }
                Default{
                    $ObjectType = ([BaseType]$object.BaseType).Value #List, DocumentLibrary, etc
                    if($null -eq $ObjectTitle){
                        $ObjectTitle = $object.Title
                    }
                    $ObjectURL = ("{0}://{1}/{2}" -f $sps_uri.Scheme, $sps_uri.DnsSafeHost,$object.FileRef)
                    #Verbose message
                    $msg = @{
                        MessageData = ($message.SPSWorkingMessage -f $ObjectTitle, $ObjectType);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $InformationAction;
                        Tags = @('SPSFilePermissionInfo');
                    }
                    Write-Verbose @msg
                }
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $InformationAction;
                Tags = @('SPSUnableToGetInfoType');
            }
            Write-Verbose @msg
        }
        #Clean object
        $_object = New-Object -TypeName PSCustomObject
        foreach($elem in $object.psobject.properties){
            if($elem.Name.Contains("$")){
                $_object | Add-Member NoteProperty -name $elem.Name.Split('$')[0] -value $elem.Value -Force
            }
            else{
                $_object | Add-Member NoteProperty -name $elem.Name -value $elem.Value -Force
            }
        }
        if($_object){$object = $_object}
        #Get permissions assigned to the object
        $param = @{
            clientObject = $object;
            properties = "HasUniqueRoleAssignments", "RoleAssignments";
            Authentication = $Authentication;
            endpoint = $sps_uri.AbsoluteUri;
            executeQuery = $True;
        }
        $permissions = Get-MonkeySPSProperty @param
        if($null -ne $permissions){
            #End get permissions assigned to the object
            #Check if Object has unique permissions
            $HasUniquePermissions = $permissions.HasUniqueRoleAssignments
            #Check if role assignments
            $roleAssignments = $permissions.RoleAssignments
            #Loop through each permission assigned and extract details
            $PermissionCollection = @()
        }
        else{
            $msg = @{
                MessageData = ("Unable to get permissions for {0}" -f $ObjectURL);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('GetPsPSPermission');
            }
            Write-Warning @msg
        }
    }
    Process{
        if($roleAssignments){
            foreach($role in $roleAssignments){
                #Get the Permission Levels assigned and Member
                $param = @{
                    clientObject = $role;
                    properties = "Member", "RoleDefinitionBindings";
                    Authentication = $Authentication;
                    endpoint = $sps_uri.AbsoluteUri;
                    executeQuery = $True;
                }
                $role_assignment = Get-MonkeySPSProperty @param
                if($role_assignment){
                    #Get the Principal Type: User, SP Group, AD Group
                    $PermissionType = [PrincipalType]$role_assignment.Member.PrincipalType
                    #Get the Permission Levels assigned
                    $PermissionLevels = $role_assignment.RoleDefinitionBindings | Select-Object Name, Description
                    #Remove Limited Access
                    $PermissionLevels = ($PermissionLevels | Where-Object { $_.Name -ne "Limited Access"})
                    #Leave Principals with no Permissions assigned
                    if(@($PermissionLevels).Count -eq 0) {Continue}
                    #Check if the Principal is SharePoint group
                    if($PermissionType -eq "SharePointGroup"){
                        $param = @{
                            group_id = $role_assignment.Member._ObjectIdentity_;
                            Authentication = $Authentication;
                            endpoint = $sps_uri.AbsoluteUri;
                        }
                        $groupMembers = Get-MonkeyPSGroupMember @param
                        #Leave Empty Groups
                        if($groupMembers.count -eq 0){Continue}
                        $GroupUsers = ($groupMembers | Select-Object -ExpandProperty Title | Where-Object { $_ -ne "System Account"}) -join "; "
                        if($GroupUsers.Length -eq 0) {Continue}
                        #Add elements to Object
                        $Permissions = New-Object PSObject
                        $Permissions | Add-Member NoteProperty -name Object -value $ObjectType
                        $Permissions | Add-Member NoteProperty -name Title -value $ObjectTitle
                        $Permissions | Add-Member NoteProperty -name URL -value $ObjectURL
                        $Permissions | Add-Member NoteProperty -name HasUniquePermissions -value $HasUniquePermissions
                        $Permissions | Add-Member NoteProperty -name Users -value $GroupUsers
                        $Permissions | Add-Member NoteProperty -name Type -value $PermissionType
                        $Permissions | Add-Member NoteProperty -name Permissions -value $PermissionLevels
                        $Permissions | Add-Member NoteProperty -name GrantedThrough -value ("SharePoint Group: {0}"-f $role_assignment.Member.LoginName)
                        $Permissions | Add-Member NoteProperty -name role_assignment -value $role_assignment
                        $Permissions | Add-Member NoteProperty -name Description -value $role_assignment.Member.Description
                        $Permissions | Add-Member NoteProperty -name group_members -value $groupMembers
                        $Permissions | Add-Member NoteProperty -name raw_element -value $object
                        $PermissionCollection += $Permissions
                    }
                    else{ #User detected
                        #Add elements to Object
                        $Permissions = New-Object PSObject
                        $Permissions | Add-Member NoteProperty -name Object -value $ObjectType
                        $Permissions | Add-Member NoteProperty -name Title -value $ObjectTitle
                        $Permissions | Add-Member NoteProperty -name URL -value $ObjectURL
                        $Permissions | Add-Member NoteProperty -name HasUniquePermissions -value $HasUniquePermissions
                        $Permissions | Add-Member NoteProperty -name Users -value $role_assignment.Member.Title
                        $Permissions | Add-Member NoteProperty -name Type -value $PermissionType
                        $Permissions | Add-Member NoteProperty -name Permissions -value $PermissionLevels
                        $Permissions | Add-Member NoteProperty -name GrantedThrough -value "Direct Permissions"
                        $Permissions | Add-Member NoteProperty -name raw_object -value $role_assignment
                        $Permissions | Add-Member NoteProperty -name raw_element -value $object
                        $PermissionCollection += $Permissions
                    }
                }
                else{
                    $msg = @{
                        MessageData = ("Empty role assignment for {0}" -f $role);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        InformationAction = $InformationAction;
                        Tags = @('SPSEmptyRoleAssignment');
                    }
                    Write-Verbose @msg
                }
            }
        }
    }
    End{
        if($null -ne $PermissionCollection){
            return $PermissionCollection
        }
    }
}
