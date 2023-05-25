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


Function Get-MonkeyCSOMObjectPermission{
    <#
        .SYNOPSIS
		Get Sharepoint Online object permissions, such as: Web, List, Folder or List Item

        .DESCRIPTION
		Get Sharepoint Online object permissions, such as: Web, List, Folder or List Item

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyCSOMObjectPermission
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory= $true, HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [Parameter(Mandatory= $false, HelpMessage="Sharepoint Endpoint")]
        [String]$Endpoint,

        [Parameter(Mandatory= $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName  = $true, HelpMessage="SharePoint Object")]
        [Object]$Object,

        [Parameter(Mandatory= $false, HelpMessage="Include inherited permissions")]
        [Switch]$IncludeInheritedPermission
    )
    Process{
        try{
            if($Endpoint){
                [uri]$sps_uri = $Endpoint
            }
            else{
                [uri]$sps_uri = $Authentication.resource
            }
            $p = @{
                Object = $Object;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $objectType =  Get-MonkeyCSOMObjectType @p
            if($null -ne $objectType){
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
            }
            else{
                $msg = @{
                    MessageData = ($message.SPSObjectErrorMessage);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('SPSPermissionMessage');
                }
                Write-Warning @msg
                return
            }
            if($PSBoundParameters.ContainsKey('IncludeInheritedPermission') -and $PSBoundParameters.IncludeInheritedPermission){
                $msg = @{
                    MessageData = ($message.SPSInheritedPermissionInfo -f $objectType.Url, $objectType.ObjectType);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('SPSInheritedPermissionMessage');
                }
                Write-Information @msg
                $p = @{
                    Object = $Object;
                    Authentication = $Authentication;
                    Endpoint = $Endpoint;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                #return object
                Invoke-MonkeyCSOMPermission @p
            }
            else{
                #Check if object has direct permissions
                $p = @{
                    ClientObject = $Object;
                    Properties = "HasUniqueRoleAssignments";
                    Authentication = $Authentication;
                    Endpoint = $Endpoint;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $role = Get-MonkeyCSOMProperty @p
                if($null -ne $role -and $role.HasUniqueRoleAssignments){
                    $msg = @{
                        MessageData = ($message.SPSPermissionInfoMessage -f $objectType.Url, $objectType.ObjectType);
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('SPSPermissionMessage');
                    }
                    Write-Information @msg
                    $p = @{
                        Object = $Object;
                        Authentication = $Authentication;
                        Endpoint = $Endpoint;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                    #return permission
                    Invoke-MonkeyCSOMPermission @p
                }
            }
        }
        catch{
            $msg = @{
                MessageData = $_;
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Tags = @('SPSPermissionMessage');
            }
            Write-Verbose @msg
        }
    }
}
