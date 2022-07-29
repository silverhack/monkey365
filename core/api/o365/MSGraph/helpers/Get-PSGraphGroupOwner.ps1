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


Function Get-PSGraphGroupOwner{
    <#
        .SYNOPSIS
		Get Group Members

        .DESCRIPTION
		Get Group Members

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSGraphGroupOwner
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$false, HelpMessage="Group Id")]
        [string]$group_id
    )
    try{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $msg = @{
            MessageData = ($message.GroupMembersMessage -f $group_id);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphGroupOwners');
        }
        Write-Debug @msg
        $params = @{
            Authentication = $graphAuth;
            ObjectType = "groups";
            ObjectId = $group_id;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = 'beta';
        }
        $group_exists = Get-GraphObject @params
        if($group_exists){
            #Get members
            $objectType = ('groups/{0}/owners' -f $group_exists.id)
            $params = @{
                Authentication = $graphAuth;
                ObjectType = $objectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = 'beta';
            }
            $group_members = Get-GraphObject @params
            if($group_members){
                return $group_members
            }
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get owners from group id {0}" -f $group_id);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphGroupOwners');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        Write-Verbose @msg
    }
}
