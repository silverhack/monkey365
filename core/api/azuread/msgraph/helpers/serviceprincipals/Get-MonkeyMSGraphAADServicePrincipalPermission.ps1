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

Function Get-MonkeyMSGraphAADServicePrincipalPermission {
    <#
        .SYNOPSIS
		Plugin to get service principal permissions from Azure AD

        .DESCRIPTION
		Plugin to get service principal permissions from Azure AD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphAADServicePrincipalPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments", '')]
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$true, ValueFromPipeline = $True)]
        [Object]$ServicePrincipal,

        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
    }
    Process{
        try{
            $msg = @{
			    MessageData = ($message.AzureADServicePrincipalPermInfo -f $ServicePrincipal.id);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'info';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('AzureADServicePrincipalInfo');
		    }
		    Write-Information @msg
            $appRoleAssignment = $all_sp = $null
            $all_sp_permissions = @()
            #Get Service principal role assignments
            $params = @{
                ServicePrincipalId = $ServicePrincipal.id;
                ElementType = "appRoleAssignments";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $appRoleAssignment = Get-MonkeyMSGraphAADServicePrincipal @params
            if($appRoleAssignment){
                #Get unique Service principals
                $all_sp = $appRoleAssignment | Select-Object -ExpandProperty resourceId -Unique
            }
            if($null -ne $all_sp){
                #Get Service principal Object
                foreach($sp in $all_sp){
                    $params = @{
                        ServicePrincipalId = $sp;
                        APIVersion = $APIVersion;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    $raw_sp = Get-MonkeyMSGraphAADServicePrincipal @params
                    if($raw_sp){
                        #Get appRoles
                        $appRoles = $raw_sp.appRoles
                        #Add to array
                        $all_sp_permissions+=$appRoles
                    }
                }
            }
            #Translate permission objects
            foreach($roleAssignment in $appRoleAssignment){
                #Search for permission
                $perm = $all_sp_permissions | Where-Object {$_.id -eq $roleAssignment.appRoleId}
                if($perm){
                    #Add permission to object
                    $roleAssignment | Add-Member -type NoteProperty -name ClaimValue -value $perm.value -Force
                    $roleAssignment | Add-Member -type NoteProperty -name IsEnabled -value $perm.isEnabled -Force
                    $roleAssignment | Add-Member -type NoteProperty -name PermissionDisplayName -value $perm.displayName -Force
                    $roleAssignment | Add-Member -type NoteProperty -name PermissionDescription -value $perm.description -Force
                }
            }
            #Return permissions
            return $appRoleAssignment
        }
        catch{
            Write-Error $_
            $msg = @{
			    MessageData = ($_);
			    callStack = (Get-PSCallStack | Select-Object -First 1);
			    logLevel = 'verbose';
			    InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
			    Tags = @('AzureADServicePrincipalPermissionError');
		    }
		    Write-Verbose @msg
        }
    }
    End{
        #Nothing to do here
    }
}