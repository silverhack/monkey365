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

Function Get-MonkeyAzRoleDefinitionObject {
    <#
        .SYNOPSIS
		Get role definition from Azure

        .DESCRIPTION
		Get role definition from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRoleDefinitionObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [parameter(Mandatory=$false, ParameterSetName = 'RoleObjectId', ValueFromPipeline = $True)]
        [String]$RoleObjectId, #= "acdd72a7-3385-48ef-bd42-f606fba81ae7",

        [parameter(Mandatory=$false, ParameterSetName = 'RoleObjectName', ValueFromPipeline = $True)]
        [String]$RoleObjectName, #= "Reader",

        [parameter(Mandatory=$false, ParameterSetName = 'Id', ValueFromPipeline = $True)]
        [String]$Id
    )
    Begin{
        $Environment = $O365Object.Environment
        #Get resource management Auth
        $rmAuth = $O365Object.auth_tokens.ResourceManager
        #Get API version
        $apiDetails = $O365Object.internal_config.resourceManager | Where-Object {$_.Name -eq 'roleDefinition'} | Select-Object -ExpandProperty resource -ErrorAction Ignore
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
        #Get RoleAssignments at the specified scope and any of its child scopes
		#https://docs.microsoft.com/en-us/azure/active-directory/role-based-access-control-manage-access-rest
		#$URI = ('{0}subscriptions/{1}/providers/Microsoft.Authorization/roleDefinitions?$filter=atScopeAndBelow()&api-version=2015-07-01' -f $O365Object.Environment.ResourceManager,$rmAuth.subscriptionId)
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'RoleObjectId'){
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
                ObjectType = 'roleDefinitions';
                ObjectId = $RoleObjectId;
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleDefinition = Get-MonkeyRMObject @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'RoleObjectName'){
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
                ObjectType = 'roleDefinitions';
                Filter = ("roleName eq '{0}'" -f $RoleObjectName)
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleDefinition = Get-MonkeyRMObject @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'Id'){
            $p = @{
		        Authentication = $rmAuth;
                ObjectId = $Id;
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleDefinition = Get-MonkeyRMObject @p
        }
        else{
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
                ObjectType = 'roleDefinitions';
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleDefinition = Get-MonkeyRMObject @p
        }
        #Get results
        if($null -ne $roleDefinition){
            #Return role definition
            return $roleDefinition
        }
    }
    End{
        #Nothing to do here
    }
}