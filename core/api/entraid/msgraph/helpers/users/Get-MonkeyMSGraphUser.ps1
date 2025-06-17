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

Function Get-MonkeyMSGraphUser {
    <#
        .SYNOPSIS
		Get Azure AD user

        .DESCRIPTION
		Get Azure AD user

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId,

        [Parameter(Mandatory=$false, ParameterSetName = 'UserPrincipalName')]
        [String]$UserPrincipalName,

        [Parameter(Mandatory=$false)]
        [String[]]$Select,

        [Parameter(Mandatory=$false)]
        [String]$Expand,

        [Parameter(Mandatory=$false)]
        [Switch]$Count,

        [parameter(Mandatory=$false)]
        [String]$Top,

        [Parameter(Mandatory=$false, HelpMessage="Bypass MFA check")]
        [Switch]$BypassMFACheck,

        [parameter(Mandatory=$false,HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'UserId'){
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'users';
                ObjectId = $UserId;
                Environment = $Environment;
                Select = $Select;
                Expand = $Expand;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $user = Get-MonkeyMSGraphObject @params
        }
        elseif($PSCmdlet.ParameterSetName -eq 'UserPrincipalName'){
            #Set filter
            $filter = ("startswith(userPrincipalName,'{0}')" -f $UserPrincipalName)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'users';
                Filter = $filter;
                Environment = $Environment;
                ContentType = 'application/json';
                Expand = $Expand;
                Select = $Select;
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $user = Get-MonkeyMSGraphObject @params
        }
        else{
            $params = @{
                Authentication = $graphAuth;
                ObjectType = 'users';
                Environment = $Environment;
                Select = $Select;
                Expand = $Expand;
                Count = $Count;
                Top = $Top;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $user = Get-MonkeyMSGraphObject @params
        }
        #return data
        if($user -and $BypassMFACheck.IsPresent -eq $false){
            #Get user's MFA details
            $user | Get-MonkeyMsGraphMFAUserDetail
        }
        else{
            $user
        }
    }
    End{
        #Nothing to do here
    }
}
