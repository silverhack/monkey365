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


Function Get-PSGraphUserById{
    <#
        .SYNOPSIS
		Get User

        .DESCRIPTION
		Get User

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSGraphUserById
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$false, HelpMessage="User Id")]
        [string]$user_id,

        [Parameter(Mandatory=$false, HelpMessage="Property to expand")]
        [string]$expand
    )
    try{
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $msg = @{
            MessageData = ($message.ObjectIdMessageInfo -f "user's", $user_id);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'debug';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphUserById');
        }
        Write-Debug @msg
        $params = @{
            Authentication = $graphAuth;
            ObjectType = "users";
            ObjectId = $user_id;
            Environment = $Environment;
            Expand = $expand;
            ContentType = 'application/json';
            Method = "GET";
            APIVersion = 'beta';
        }
        $user = Get-GraphObject @params
        if($null -ne $user){
            return $user
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get user's information from id {0}" -f $user_id);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $InformationAction;
            Tags = @('AzureGraphUserById');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        Write-Verbose @msg
    }
}
