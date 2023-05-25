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


Function Get-MonkeyCSOMWebPermission{
    <#
        .SYNOPSIS
		Get Sharepoint Online web permissions

        .DESCRIPTION
		Get Sharepoint Online web permissions

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMWebPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName  = $true, HelpMessage="SharePoint Web Object")]
        [Object]$Web,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Begin{
        #Set generic list
        $webPermissions = New-Object System.Collections.Generic.List[System.Object]
        #Get Access Token for Sharepoint
        $sps_auth = $O365Object.auth_tokens.SharePointOnline
    }
    Process{
        #Check for objectType
        if ($Web.psobject.properties.Item('_ObjectType_') -and $Web._ObjectType_ -eq 'SP.Web'){
            $p = @{
                Object = $Web;
                Authentication = $sps_auth;
                Endpoint = $Web.Url;
                IncludeInheritedPermission = $IncludeInheritedPermission;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $perms = Get-MonkeyCSOMObjectPermission @p
            if($perms){
                #Add to list
                foreach($perm in $perms){
                    [void]$webPermissions.Add($perm)
                }
            }

        }
        else{
            $msg = @{
                MessageData = ($message.SPOInvalieWebObjectMessage);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'Warning';
                InformationAction = $InformationAction;
                Tags = @('SPOInvalidWebObject');
            }
            Write-Warning @msg
        }
    }
    End{
        #return permissions
        return $webPermissions
    }
}
