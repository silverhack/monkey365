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

        [Parameter(Mandatory=$false, HelpMessage="Get Per-User MFA")]
        [Switch]$PerUserMFA,

        [parameter(Mandatory=$false,HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $monkeyJob = $null -ne (Get-Command -Name Invoke-MonkeyJob -ErrorAction Ignore)
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'UserId'){
            $p = @{
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
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'UserPrincipalName'){
            #Set filter
            $filter = ("startswith(userPrincipalName,'{0}')" -f $UserPrincipalName)
            $p = @{
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
        }
        Else{
            $p = @{
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
        }
        $user = Get-MonkeyMSGraphObject @p
        #Get Per-User MFA if present
        If($PerUserMFA.IsPresent){
            #Set null
            $PerUserMFASettings = $null;
            #Check if MonkeyJob is present
            If($monkeyJob -and $null -ne $O365Object.monkey_runspacePool -and @($user).Count -gt 1){
                $new_arg = @{
				    APIVersion = 'beta';
			    }
			    $p = @{
				    ScriptBlock = { Get-MonkeyMSGraphPerUserMFA -User $_ };
				    Arguments = $new_arg;
				    Runspacepool = $O365Object.monkey_runspacePool;
				    ReuseRunspacePool = $true;
				    Debug = $O365Object.VerboseOptions.Debug;
				    Verbose = $O365Object.VerboseOptions.Verbose;
				    MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				    BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				    BatchSize = $O365Object.nestedRunspaces.BatchSize;
			    }
			    $PerUserMFASettings = $user | Invoke-MonkeyJob @p | ForEach-Object {
                    $uid = $_.'@odata.context'.Split('()')[1].Replace("'",'').Trim()
                    If($uid){
                        $_ | Add-Member -MemberType NoteProperty -Name id -Value $uid
                    }
                    $_
                }
            }
            Else{
                #Get per-user's MFA details
                $PerUserMFASettings = $user | Get-MonkeyMSGraphPerUserMFA -APIVersion beta | ForEach-Object {
                    $uid = $_.'@odata.context'.Split('()')[1].Replace("'",'').Trim()
                    If($uid){
                        $_ | Add-Member -MemberType NoteProperty -Name id -Value $uid
                    }
                    $_
                }
            }
            If($null -ne $PerUserMFASettings){
                ForEach($u in @($user).GetEnumerator()){
                    $uid = @($PerUserMFASettings).Where({$_.id -match $u.id});
                    $perUserMfaState = ($uid | Select-Object -ExpandProperty perUserMfaState -ErrorAction Ignore)
                    If($uid.count -gt 0){
                        $u | Add-Member -MemberType NoteProperty -Name perUserMfaState -Value $perUserMfaState
                    }
                    Else{
                        $u | Add-Member -MemberType NoteProperty -Name perUserMfaState -Value "Unknown"
                    }
                }
            }
        }
        #Azure PowerShell client is not able to get details about user's MFA
        If($user -and $BypassMFACheck.IsPresent -eq $false -and $graphAuth.clientId -ne (Get-WellKnownAzureService -AzureService AzurePowerShell)){
            If($monkeyJob -and $null -ne $O365Object.monkey_runspacePool -and @($user).Count -gt 1){
                $new_arg = @{
				    APIVersion = $APIVersion;
			    }
			    $p = @{
				    ScriptBlock = { Get-MonkeyMsGraphMFAUserDetail -User $_ };
				    Arguments = $new_arg;
				    Runspacepool = $O365Object.monkey_runspacePool;
				    ReuseRunspacePool = $true;
				    Debug = $O365Object.VerboseOptions.Debug;
				    Verbose = $O365Object.VerboseOptions.Verbose;
				    MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
				    BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
				    BatchSize = $O365Object.nestedRunspaces.BatchSize;
			    }
			    $user | Invoke-MonkeyJob @p
            }
            Else{
                #Get user's MFA details
                $user | Get-MonkeyMsGraphMFAUserDetail
            }
        }
        Else{
            $user
        }
    }
    End{
        #Nothing to do here
    }
}
