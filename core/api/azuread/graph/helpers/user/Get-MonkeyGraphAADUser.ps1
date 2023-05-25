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

Function Get-MonkeyGraphAADUser {
    <#
        .SYNOPSIS
        Get detailed user from AzureAD

        .DESCRIPTION
        Get detailed user from AzureAD

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphAADUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [Parameter(Mandatory=$false, ParameterSetName = 'UserId', ValueFromPipeline = $True)]
        [String]$UserId
    )
    Begin{
        #Get instance
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $AADAuth = $O365Object.auth_tokens.Graph
        #Get Config
        try{
            $aadConf = $O365Object.internal_config.azuread.provider.graph
        }
        catch{
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
        if($PSCmdlet.ParameterSetName -eq 'UserId'){
            $uri = ("{0}/myorganization/users('{1}')?api-version={2}" `
                    -f $Environment.Graph, $UserId,$aadConf.internal_api_version)

            $params = @{
                Authentication = $AADAuth;
                OwnQuery = $uri;
                Environment = $Environment;
                ContentType = 'application/json';
                Method = "GET";
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
            }
            $User = Get-MonkeyGraphObject @params
        }
        else{
            #Get users
		    $params = @{
			    Authentication = $AADAuth;
			    ObjectType = "users";
			    Environment = $Environment;
			    ContentType = 'application/json';
			    Method = "GET";
			    APIVersion = $aadConf.internal_api_version;
                InformationAction = $O365Object.InformationAction;
                Verbose = $O365Object.verbose;
                Debug = $O365Object.debug;
		    }
		    $User = Get-MonkeyGraphObject @params
        }
    }
    End{
        if($User){
            #Create new id property
            foreach($u in @($user)){
                $u | Add-Member -type NoteProperty -name id -value $u.objectId -Force
            }
            $User | Get-MonkeyGraphAADUserMFA
        }
    }
}
