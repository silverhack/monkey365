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


Function Get-MonkeyMSGraphObjectDirectoryRole{
    <#
        .SYNOPSIS
		Get user or service principal directory role

        .DESCRIPTION
		Get user or service principal directory role

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphObjectDirectoryRole
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Object Id")]
        [string]$ObjectId,

        [parameter(Mandatory=$false)]
        [ValidateSet("user","servicePrincipal")]
        [String]$ObjectType = "user",

        [parameter(Mandatory=$false)]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "v1.0"
    )
    try{
        $myObjectType = $null;
        $Environment = $O365Object.Environment
        #Get Graph Auth
        $graphAuth = $O365Object.auth_tokens.MSGraph
        $msg = @{
            MessageData = ($message.ObjectIdMessageInfo -f "object's", $ObjectId);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'verbose';
            InformationAction = $O365Object.InformationAction;
            Tags = @('AzureMSGraphDirectoryRoleByObjectId');
        }
        Write-Verbose @msg
        #Check ObjectType
        Switch($ObjectType.ToLower()){
            'user'{
                $myObjectType = ('users/{0}/transitiveMemberOf' -f $ObjectId)
            }
            'servicePrincipal'{
                $myObjectType = ('servicePrincipals/{0}/transitiveMemberOf' -f $ObjectId)
            }
        }
        if($null -ne $myObjectType){
            $p = @{
                Authentication = $graphAuth;
                ObjectType = $myObjectType;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                APIVersion = $APIVersion;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            Get-MonkeyMSGraphObject @p | Where-Object {$_.'@odata.type' -eq '#microsoft.graph.directoryRole'}
        }
    }
    catch{
        $msg = @{
            MessageData = ("Unable to get object's directory role information from id {0}" -f $ObjectId);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $O365Object.InformationAction;
            Tags = @('AzureMSGraphObjectDirectoryRoleError');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        $msg.Add('Verbose',$O365Object.verbose)
        Write-Verbose @msg
    }
}

