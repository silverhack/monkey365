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

Function Get-MonkeyMSGraphLatestRBACSignInLog {
    <#
        .SYNOPSIS
		Get Microsoft Entra sign-in events for potentially users with role assignment

        .DESCRIPTION
		Get Microsoft Entra sign-in events for potentially users with role assignment

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphLatestRBACSignInLog
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

	[CmdletBinding(DefaultParameterSetName = 'IT')]
	Param (
        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("24H","7Days","lastMonth")]
        [String]$DataRange = "24H",

        [Parameter(Mandatory=$false, ParameterSetName = 'NonIT', HelpMessage="Non Interactive Sign-In")]
        [Switch]$NonInteractive,

        [Parameter(Mandatory=$false, ParameterSetName = 'sp', HelpMessage="Service Principal Sign-In")]
        [Switch]$ServicePrincipal,

        [parameter(Mandatory=$false, HelpMessage="Order By")]
        [String]$OrderBy,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        #Set generic list
        $all_sign_in_role_assignment = [System.Collections.Generic.List[System.Management.Automation.PSObject]]::new()
        #set null
        $signInLog = $null
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        If($APIVersion.ToLower() -eq 'v1.0'){
            #We need to switch to beta endpoint
            $APIVersion = 'beta';
        }
        If($PSCmdlet.ParameterSetName.ToLower() -match ('it|nonit')){
            $new_arg = @{
                ObjectType = "user"
                ApiVersion = $APIVersion
            }
        }
        ElseIf($PSCmdlet.ParameterSetName.ToLower() -match ('sp')){
            $new_arg = @{
                ObjectType = "servicePrincipal"
                ApiVersion = $APIVersion
            }
        }
        #Set job param
        $jobParam = @{
	        ScriptBlock = { Get-MonkeyMSGraphObjectDirectoryRole -ObjectId $_};
            Arguments = $new_arg;
	        Runspacepool = $O365Object.monkey_runspacePool;
	        ReuseRunspacePool = $true;
	        Debug = $O365Object.VerboseOptions.Debug;
	        Verbose = $O365Object.VerboseOptions.Verbose;
	        MaxQueue = $O365Object.nestedRunspaces.MaxQueue;
	        BatchSleep = $O365Object.nestedRunspaces.BatchSleep;
	        BatchSize = $O365Object.nestedRunspaces.BatchSize;
        }
    }
    Process{
        Switch($PSCmdlet.ParameterSetName.ToLower()){
            'it'
            {
                $p = @{
                    DataRange = $DataRange;
                    OrderBy = 'createdDateTime desc';
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $signInLog = Get-MonkeyMSGraphSignInLog @p
                If($null -ne $signInLog){
                    $signInLog = $signInLog | Select-Object userDisplayName,userPrincipalName,createdDateTime,UserId -ErrorAction Ignore
                }
            }
            'nonit'
            {
                $p = @{
                    DataRange = $DataRange;
                    NonInteractive = $true;
                    OrderBy = 'createdDateTime desc';
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $signInLog = Get-MonkeyMSGraphSignInLog @p
                If($null -ne $signInLog){
                    $signInLog = $signInLog | Select-Object userDisplayName,userPrincipalName,createdDateTime,UserId -ErrorAction Ignore
                }
            }
            'sp'
            {
                $p = @{
                    DataRange = $DataRange;
                    ServicePrincipal = $true;
                    OrderBy = 'firstSignInDateTime desc';
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $signInLog = Get-MonkeyMSGraphSummarizedSignInLog @p
                If($null -ne $signInLog){
                    $signInLog = $signInLog | Select-Object servicePrincipalId,servicePrincipalName,firstSignInDateTime -ErrorAction Ignore
                }
            }
            Default
            {
                $p = @{
                    DataRange = $DataRange;
                    OrderBy = 'createdDateTime desc';
                    APIVersion = $APIVersion;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
                $signInLog = Get-MonkeyMSGraphSignInLog @p
                If($null -ne $signInLog){
                    $signInLog = $signInLog | Select-Object userDisplayName,userPrincipalName,createdDateTime,UserId -ErrorAction Ignore
                }
            }
        }
    }
    End{
        If($null -ne $signInLog){
            $signInLog | ForEach-Object {
                $identity = $_;
                If($PSCmdlet.ParameterSetName.ToLower() -match ('sp')){
                    $rbac = $identity.servicePrincipalId | Invoke-MonkeyJob @jobParam
                    If($rbac){
                        ForEach($roleAssignment in @($rbac).GetEnumerator()){
                            $_obj = [PsCustomObject]@{
                                id = $identity.servicePrincipalId;
                                displayName = $identity.servicePrincipalName;
                                createdDateTime = $identity.firstSignInDateTime;
                                roleName = $roleAssignment | Select-Object -ExpandProperty displayName
                                roleDescription = $roleAssignment | Select-Object -ExpandProperty description
                                templateId = $roleAssignment | Select-Object -ExpandProperty roleTemplateId
                            }
                            [void]$all_sign_in_role_assignment.Add($_obj)
                        }
                    }
                }
                Else{
                    $rbac = $identity.UserId | Invoke-MonkeyJob @jobParam
                    If($rbac){
                        ForEach($roleAssignment in @($rbac).GetEnumerator()){
                            $_obj = [PsCustomObject]@{
                                id = $identity.userId;
                                displayName = $identity.userDisplayName;
                                createdDateTime = $identity.createdDateTime;
                                userPrincipalName = $identity.userPrincipalName;
                                roleName = $roleAssignment | Select-Object -ExpandProperty displayName
                                roleDescription = $roleAssignment | Select-Object -ExpandProperty description
                                templateId = $roleAssignment | Select-Object -ExpandProperty roleTemplateId
                            }
                            [void]$all_sign_in_role_assignment.Add($_obj)
                        }
                    }
                }
            }
        }
        Write-Output $all_sign_in_role_assignment -NoEnumerate
    }
}
