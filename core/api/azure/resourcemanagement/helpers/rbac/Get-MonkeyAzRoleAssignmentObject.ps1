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

Function Get-MonkeyAzRoleAssignmentObject {
    <#
        .SYNOPSIS
		Get role assignment from Azure

        .DESCRIPTION
		Get role assignment from Azure

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRoleAssignmentObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding(DefaultParameterSetName = 'All')]
	Param (
        [parameter(Mandatory=$false, ParameterSetName = 'RoleId', ValueFromPipeline = $True)]
        [String]$RoleId, #= "3d99284f-94a5-4fe4-a41a-9601cc520abd",

        [parameter(Mandatory=$false, ParameterSetName = 'ObjectId', ValueFromPipeline = $True)]
        [String]$ObjectId,

        [parameter(Mandatory=$false, ParameterSetName = 'AssignedTo', ValueFromPipeline = $True)]
        [String]$AssignedTo,

        [parameter(Mandatory=$false, ValueFromPipeline = $True)]
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
        #set var
        $roleAssignment = $null
    }
    Process{
        if($PSCmdlet.ParameterSetName -eq 'RoleId'){
            $msg = @{
                MessageData = ($message.RoleAssignmentIdInfoMessage -f $RoleId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureIAMInfo');
            }
            Write-Information @msg
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
                ObjectType = 'roleAssignments';
                ObjectId = $RoleId;
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleAssignment = Get-MonkeyRMObject @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'ObjectId'){
            $msg = @{
                MessageData = ($message.RoleAssignmentIdInfoMessage -f $ObjectId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureIAMInfo');
            }
            Write-Information @msg
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
                ObjectType = 'roleAssignments';
                ObjectId = $ObjectId;
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleAssignment = Get-MonkeyRMObject @p
        }
        elseif($PSCmdlet.ParameterSetName -eq 'AssignedTo'){
            $msg = @{
                MessageData = ($message.RoleAssignmentIdInfoMessage -f $AssignedTo);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureIAMInfo');
            }
            Write-Information @msg
            #Set filter
            if($AtScope){
                $filter = ("atScope() and assignedTo('{0}')" -f $AssignedTo)
            }
            else{
                $filter = ("assignedTo('{0}')" -f $AssignedTo)
            }
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
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
            $roleAssignment = Get-MonkeyRMObject @p
        }
        else{
            $msg = @{
                MessageData = ($message.RoleAssignmentInfoMessage -f $O365Object.current_subscription.subscriptionId);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'info';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureIAMInfo');
            }
            Write-Information @msg
            $p = @{
		        Authentication = $rmAuth;
			    Provider = 'Microsoft.Authorization';
                ObjectType = 'roleAssignments';
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
                APIVersion = $apiDetails.api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
            $roleAssignment = Get-MonkeyRMObject @p
        }
        #Get results
        if($null -ne $roleAssignment){
            #Return role assignment
            return $roleAssignment
        }
    }
    End{
        #Nothing to do here
    }
}