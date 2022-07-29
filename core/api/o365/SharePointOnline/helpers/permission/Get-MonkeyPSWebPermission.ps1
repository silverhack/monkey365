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


Function Get-MonkeyPSWebPermission{
    <#
        .SYNOPSIS
		Plugin to get information about O365 Sharepoint Online web permissions

        .DESCRIPTION
		Plugin to get information about O365 Sharepoint Online web permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPSWebPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Sharepoint Web Object")]
        [Object]$Web
    )
    Begin{
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharepointOnline
        #Get switchs
        $inherited = [System.Convert]::ToBoolean($O365Object.internal_config.o365.SharePointOnline.SitePermissions.IncludeInheritedPermissions)
        #Get Web object
        if($null -ne $Web){
            #Set array
            $all_permissions = [ordered]@{
                Url = $Web.Url;
            }
        }
    }
    Process{
        if($null -ne $Web -and $null -ne $Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            if($Inherited){
                $msg = @{
                    MessageData = ($message.SPSGetPermissions -f $Web.Url);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $InformationAction;
                    Tags = @('SPSWebPermission');
                }
                Write-Information @msg
                $param = @{
                    Authentication = $sps_auth;
                    endpoint = $Web.Url;
                    object = $Web;
                }
                $perms = Get-MonkeyPSPermission @param
                if($null -ne $perms){
                    $all_permissions.Add('WebPermissions',$perms)
                }
                else{
                    $all_permissions.Add('WebPermissions',$null)
                }
            }
            else{
                #Check if the Web has unique permissions
                $param = @{
                    clientObject = $Web;
                    properties = "HasUniqueRoleAssignments", "RoleAssignments";
                    Authentication = $sps_auth;
                    endpoint = $Web.Url;
                    executeQuery = $True;
                }
                $permissions = Get-MonkeySPSProperty @param
                #End get permissions assigned to the object
                #Check if Object has unique permissions
                if($permissions.HasUniqueRoleAssignments){
                    $msg = @{
                        MessageData = ($message.SPSGetPermissions -f $Web.Url);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $InformationAction;
                        Tags = @('SPSWebPermission');
                    }
                    Write-Information @msg
                    $param = @{
                        Authentication = $sps_auth;
                        endpoint = $Web.Url;
                        object = $Web;
                    }
                    $perms = Get-MonkeyPSPermission @param
                    if($null -ne $perms){
                        $all_permissions.Add('WebPermissions',$perms)
                    }
                    else{
                        $all_permissions.Add('WebPermissions',$null)
                    }
                }
            }
            #Get list permissions
            $param = @{
                Authentication = $sps_auth;
                Web = $Web;
            }
            $perms = Get-MonkeyPSListPermission @param
            if($null -ne $perms){
                $all_permissions.Add('Permissions',$perms)
            }
            else{
                $all_permissions.Add('Permissions',$null)
            }
        }
    }
    End{
        if($null -ne $all_permissions){
            #return custom object
            $perm_obj = New-Object PSObject -Property $all_permissions
            return $perm_obj
        }
    }
}
