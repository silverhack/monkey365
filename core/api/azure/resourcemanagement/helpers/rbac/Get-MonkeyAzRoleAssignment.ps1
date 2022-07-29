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

Function Get-MonkeyAzRoleAssignment{
    <#
        .SYNOPSIS
        Get role assignments from Azure subscription

        .DESCRIPTION
        Get role assignments from Azure subscription

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzRoleAssignment
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$RoleObjectId #= "acdd72a7-3385-48ef-bd42-f606fba81ae7"
    )
    Begin{
        #Set Array
        $raw_data = New-Object System.Collections.Generic.List[System.Object]
        #Get auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        $url = $unique_ra = $null
        if($null -ne $O365Object.current_subscription -and $null -ne $O365Object.current_subscription.Psobject.Properties.Item('subscriptionId')){
            if($RoleObjectId){
                $msg = @{
                    MessageData = ($message.RoleBasedPermissionsMessage -f $RoleObjectId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'info';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureRbacInfo');
                }
                Write-Information @msg
                $url = ("{0}subscriptions/{1}/providers/Microsoft.Authorization/roleAssignments?$filter=principalId%20eq%20'{2}'&api-version=2018-01-01-preview" -f $O365Object.Environment.ResourceManager, $O365Object.current_subscription.subscriptionId, $RoleObjectId)
            }
            else{
                $url = ("{0}subscriptions/{1}/providers/Microsoft.Authorization/roleAssignments?&api-version=2018-01-01-preview" -f $O365Object.Environment.ResourceManager, $O365Object.current_subscription.subscriptionId)
            }
        }
        #Get Role Assignments
        if($null -ne $url -and $null -ne $rm_auth){
            $AuthHeader = $rm_auth.CreateAuthorizationHeader()
            $requestHeader = @{
                "x-ms-version" = "2014-10-01";
                "Authorization" = $AuthHeader
            }
            $ra_params = @{
                Url = $url;
                Headers = $requestHeader;
                Method = 'Get';
                Content_Type = 'application/json';
                UserAgent = $O365Object.userAgent;
            }
            $AllObjects = Invoke-UrlRequest @ra_params
            if($null -ne $AllObjects){
                #Get unique roleAssignments
                $unique_ra = $AllObjects.value.Properties | Select-Object -ExpandProperty roleDefinitionId -Unique -ErrorAction Ignore
            }
        }
    }
    Process{
        try{
            if($null -ne $unique_ra){
                foreach($roleAssignment in $unique_ra){
                    $params = @{
                        Authentication = $rm_auth;
                        ObjectId = $roleAssignment;
                        Environment = $O365Object.Environment;
                        ContentType = 'application/json';
                        Method = "GET";
                        APIVersion = '2018-01-01-preview';
                    }
                    $raw_role = Get-MonkeyRMObject @params
                    if($raw_role){
                        #Get members
                        $members = $AllObjects.value.Properties | Where-Object {$_.roleDefinitionId -eq $roleAssignment}
                        $raw_role | Add-Member -type NoteProperty -name members -value $members
                        #Add to array
                        [void]$raw_data.Add($raw_role)
                    }
                }
            }
            else{
                $msg = @{
                    MessageData = ($message.RoleAssignmentWarningMessage -f $O365Object.current_subscription.subscriptionId);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $O365Object.InformationAction;
                    Tags = @('AzureRBACInfoWarning');
                }
                Write-Warning @msg
            }
        }
        catch{
            $msg = @{
                MessageData = ($_);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRBACInfoError');
            }
            Write-Error @msg
            $msg = @{
                MessageData = ($_.Exception.StackTrace);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'error';
                InformationAction = $O365Object.InformationAction;
                Tags = @('AzureRBACInfoError');
            }
            Write-Debug @msg
        }
    }
    End{
        if($raw_data.Count -gt 0){
            Group-MonkeyAZRBACMember -role_assignments $raw_data
        }
    }
}