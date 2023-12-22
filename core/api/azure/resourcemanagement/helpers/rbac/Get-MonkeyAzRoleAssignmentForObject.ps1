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

Function Get-MonkeyAzRoleAssignmentForObject{
    <#
        .SYNOPSIS

        Get Azure IAM permission for an specific object, such as userId, groupId, service principal, subscription, etc..

        .DESCRIPTION

        Get Azure IAM permission for an specific object, such as userId, groupId, service principal, subscription, etc..

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRoleAssignmentForObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseDeclaredVarsMoreThanAssignments","",Scope = "Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter","",Scope = "Function")]
    [CmdletBinding(DefaultParameterSetName='All')]
    Param (
        [parameter(Mandatory=$true, ParameterSetName = 'PrincipalId', HelpMessage="Principal Id")]
        [String]$PrincipalId,

        [parameter(Mandatory=$true, ParameterSetName = 'Group', HelpMessage="Group Id")]
        [String]$GroupId,

        [parameter(Mandatory=$true, ParameterSetName = 'User', HelpMessage="User Id")]
        [String]$UserId,

        [parameter(Mandatory=$true, ParameterSetName = 'CurrentUser', HelpMessage="CurrentUser")]
        [Switch]$CurrentUser,

        [parameter(Mandatory=$true, ParameterSetName = 'ResourceGroup', HelpMessage="Resource group")]
        [String]$ResourceGroup,

        [parameter(Mandatory=$true, ParameterSetName = 'Subscription', HelpMessage="Subscription")]
        [String]$Subscription,

        [parameter(Mandatory=$false, HelpMessage="At scope query")]
        [Switch]$AtScope
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get resource management Auth
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'roleAssignments'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
        if($null -eq $apiDetails){
            $msg = @{
                MessageData = ($message.MonkeyInternalConfigError);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'verbose';
                InformationAction = $O365Object.InformationAction;
                Tags = @('Monkey365ConfigError');
            }
            Write-Verbose @msg
            break
        }
    }
    Process{
        switch ($PSCmdlet.ParameterSetName.ToLower()){
            "CurrentUser"{
                if($O365Object.userPrincipalName){
                    $msg = @{
                        MessageData = ($message.RbacPermissionsMessage -f $O365Object.userPrincipalName, "user");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureRbacInfo');
                    }
                    Write-Information @msg
                    #Get current Id
                    $objectId = $O365Object.userId
                }
                elseif($O365Object.isConfidentialApp){
                    $msg = @{
                        MessageData = ($message.RbacPermissionsMessage -f $O365Object.clientApplicationId, "client application");
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'info';
                        InformationAction = $O365Object.InformationAction;
                        Tags = @('AzureRbacInfo');
                    }
                    Write-Information @msg
                    #Get current Id
                    $objectId = $O365Object.clientApplicationId
                }
                #Set filter
                if($AtScope.IsPresent){
                    $filter = ("atScope() and assignedTo('{0}')" -f $objectId)
                }
                else{
                    $filter = ("assignedTo('{0}')" -f $objectId)
                }
                #Construct query
                $p = @{
		            Authentication = $rmAuth;
			        Provider = $apiDetails.provider;
                    ObjectType = 'roleAssignments';
                    Filter = $filter;
			        Environment = $Environment;
			        ContentType = 'application/json';
			        Method = "GET";
                    APIVersion = $apiDetails.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
            }
            "PrincipalId"{
                #Set filter
                if($AtScope.IsPresent){
                    $filter = ("atScope() and assignedTo('{0}')" -f $PrincipalId)
                }
                else{
                    $filter = ("assignedTo('{0}')" -f $PrincipalId)
                }
                #Construct query
                $p = @{
		            Authentication = $rmAuth;
			        Provider = $apiDetails.provider;
                    ObjectType = 'roleAssignments';
                    Filter = $filter;
			        Environment = $Environment;
			        ContentType = 'application/json';
			        Method = "GET";
                    APIVersion = $apiDetails.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
            }
            "UserId"{
                #Set filter
                if($AtScope.IsPresent){
                    $filter = ("atScope() and assignedTo('{0}')" -f $UserId)
                }
                else{
                    $filter = ("assignedTo('{0}')" -f $UserId)
                }
                #Construct query
                $p = @{
		            Authentication = $rmAuth;
			        Provider = $apiDetails.provider;
                    ObjectType = 'roleAssignments';
                    Filter = $filter;
			        Environment = $Environment;
			        ContentType = 'application/json';
			        Method = "GET";
                    APIVersion = $apiDetails.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
		        }
            }
            "ResourceGroup"{
                if($AtScope.IsPresent){
                    $p = @{
	                    Authentication = $rmAuth;
                        ResourceGroup = $ResourceGroup;
	                    Provider = $apiDetails.provider;
                        ObjectType = 'roleAssignments';
                        Filter = "atScope()";
	                    Environment = $Environment;
	                    ContentType = 'application/json';
	                    Method = "GET";
                        APIVersion = $apiDetails.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                }
                else{
                    $p = @{
	                    Authentication = $rmAuth;
                        ResourceGroup = $ResourceGroup;
	                    Provider = $apiDetails.provider;
                        ObjectType = 'roleAssignments';
	                    Environment = $Environment;
	                    ContentType = 'application/json';
	                    Method = "GET";
                        APIVersion = $apiDetails.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                }
            }
            "Subscription"{
                if($AtScope.IsPresent){
                    $p = @{
	                    Authentication = $rmAuth;
	                    Provider = $apiDetails.provider;
                        ObjectType = 'roleAssignments';
                        Filter = "atScope()";
	                    Environment = $Environment;
	                    ContentType = 'application/json';
	                    Method = "GET";
                        APIVersion = $apiDetails.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                }
                else{
                    $p = @{
	                    Authentication = $rmAuth;
	                    Provider = $apiDetails.provider;
                        ObjectType = 'roleAssignments';
	                    Environment = $Environment;
	                    ContentType = 'application/json';
	                    Method = "GET";
                        APIVersion = $apiDetails.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                }
            }
            "Group"{
                $filter = ("principalId eq '{0}'" -f $GroupId)
                $p = @{
	                Authentication = $rmAuth;
	                Provider = $apiDetails.provider;
                    ObjectType = 'roleAssignments';
                    Filter = $filter;
	                Environment = $Environment;
	                ContentType = 'application/json';
	                Method = "GET";
                    APIVersion = $apiDetails.api_version;
                    InformationAction = $O365Object.InformationAction;
                    Verbose = $O365Object.verbose;
                    Debug = $O365Object.debug;
                }
            }
            Default{
                if($AtScope.IsPresent){
                    $p = @{
	                    Authentication = $rmAuth;
	                    Provider = $apiDetails.provider;
                        ObjectType = 'roleAssignments';
                        Filter = "atScope()";
	                    Environment = $Environment;
	                    ContentType = 'application/json';
	                    Method = "GET";
                        APIVersion = $apiDetails.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                }
                else{
                    $p = @{
	                    Authentication = $rmAuth;
	                    Provider = $apiDetails.provider;
                        ObjectType = 'roleAssignments';
	                    Environment = $Environment;
	                    ContentType = 'application/json';
	                    Method = "GET";
                        APIVersion = $apiDetails.api_version;
                        InformationAction = $O365Object.InformationAction;
                        Verbose = $O365Object.verbose;
                        Debug = $O365Object.debug;
                    }
                }
            }
        }
    }
    End{
        Get-MonkeyRMObject @p
    }
}