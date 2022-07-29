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

function Get-MonkeyRmObjectById{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRmObjectById
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
            [Parameter(HelpMessage="Object Id")]
            [String]$objectId,

            [Parameter(HelpMessage="Api version")]
            [String]$resource,

            [Parameter(HelpMessage="Api version")]
            [String]$api_version
    )
    Begin{
        $endpoint = $null
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        $base_uri = ("{0}" -f $Environment.ResourceManager)
    }
    Process{
        #Construct Uri
        if($objectId){
            $base_uri = ("{0}/{1}" -f $base_uri, $objectId)
        }
        if($resource){
            $base_uri = ("{0}/{1}" -f $base_uri, $resource)
        }
        #Add api version
        $endpoint = ("{0}?api-version={1}" -f $base_uri, $api_version)
    }
    End{
        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $endpoint;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = "GET";
        }
        Get-MonkeyRMObject @params
    }
}
