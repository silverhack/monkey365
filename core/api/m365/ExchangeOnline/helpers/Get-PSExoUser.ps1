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

Function Get-PSExoUser{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSExoUser
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [Parameter(Mandatory=$True, HelpMessage="user")]
        [String]$user,

        [Parameter(Mandatory=$false, HelpMessage="Authentication object")]
        [Object]$AuthenticationObject
    )
    Begin{
        #Getting environment
        $Environment = $O365Object.Environment
        if($PSBoundParameters.ContainsKey('AuthenticationObject')){
            $exo_auth = $AuthenticationObject
        }
        else{
            #Get Exo authentication
            $exo_auth = $O365Object.auth_tokens.ExchangeOnline
        }
        #Set var with null
        $exo_user = $null
    }
    Process{
        #Get role group members
        $objectType = ("User('{0}')" -f $user)
        $param = @{
            Authentication = $exo_auth;
            Environment = $Environment;
            ObjectType = $objectType;
            ExtraParameters = "PropertySet=All";
            Method = "GET";
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        $exo_user = Get-PSExoAdminApiObject @param
    }
    End{
        if($null -ne $exo_user){
            return $exo_user
        }
    }
}
