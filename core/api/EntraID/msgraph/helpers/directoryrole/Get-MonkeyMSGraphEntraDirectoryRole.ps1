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


Function Get-MonkeyMSGraphEntraDirectoryRole{
    <#
        .SYNOPSIS
		Get EntraID directory role information

        .DESCRIPTION
		Get EntraID directory role information

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphEntraDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param (
        [Parameter(Mandatory=$True, ParameterSetName = 'User', HelpMessage="User Id")]
        [String]$UserId,

        [parameter(Mandatory=$True, ParameterSetName = 'CurrentUser', HelpMessage="Current user")]
        [Switch]$CurrentUser,

        [Parameter(Mandatory=$True, ParameterSetName = 'PrincipalId', HelpMessage="Principal Id")]
        [String]$PrincipalId,

        [Parameter(Mandatory=$True, ParameterSetName = 'Group', HelpMessage="Group Id")]
        [String]$GroupId,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.entraId.provider.msgraph
        }
        catch{
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            throw ("[ConfigError] {0}: {1}" -f $message.MonkeyInternalConfigError,$_.Exception.Message)
        }
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'UserId'){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $UserId, "user");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('MonkeyEntraIDRoleInfo');
            }
            Write-Information @msg
            $p = @{
                ObjectId = $UserId;
                ObjectType = "user";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                APIVersion = $aadConf.api_version;
            }
            Get-MonkeyMSGraphObjectDirectoryRole @p
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'PrincipalId'){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $PrincipalId, "Service principal");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('MonkeyEntraIDRoleInfo');
            }
            Write-Information @msg
            $p = @{
                ObjectId = $PrincipalId;
                ObjectType = "servicePrincipal";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                APIVersion = $aadConf.api_version;
            }
            Get-MonkeyMSGraphObjectDirectoryRole @p
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'GroupId'){
            $msg = @{
                MessageData = ($message.RbacPermissionsMessage -f $GroupId, "Group");
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('MonkeyEntraIDRoleInfo');
            }
            Write-Information @msg
            $p = @{
                GroupId = $GroupId;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                APIVersion = $aadConf.api_version;
            }
            Get-MonkeyMSGraphGroupDirectoryRoleMemberOf @p
        }
        Elseif($PSCmdlet.ParameterSetName -eq 'CurrentUser'){
            $objectType = $objectId = $null;
            if($O365Object.userId){
                $msg = @{
                    MessageData = ($message.RbacPermissionsMessage -f $O365Object.userPrincipalName, "user");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyEntraIDRoleInfo');
                }
                Write-Information @msg
                $objectType = "user";
                $objectId = $O365Object.userId;
            }
            ElseIf($O365Object.isConfidentialApp){
                $msg = @{
                    MessageData = ($message.RbacPermissionsMessage -f $O365Object.clientApplicationId, "client application");
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('MonkeyEntraIDRoleInfo');
                }
                Write-Information @msg
                $objectType = "servicePrincipal";
                $objectId = $O365Object.clientApplicationId;
            }
            Else{
                $objectType = $null;
            }
            If($null -ne $objectType -and $null -ne $objectId){
                $p = @{
                    ObjectId = $objectId;
                    ObjectType = $objectType;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                    APIVersion = $aadConf.api_version;
                }
                Get-MonkeyMSGraphObjectDirectoryRole @p
            }
        }
        Else{#All members
            $p = @{
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
                APIVersion = $aadConf.api_version;
            }
            Get-MonkeyMSGraphEntraRoleAssignment @p
        }
    }
    End{
        #Nothing to do here
    }
}
