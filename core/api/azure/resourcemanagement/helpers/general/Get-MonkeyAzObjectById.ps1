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

function Get-MonkeyAzObjectById{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzObjectById
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(HelpMessage="Object Id")]
        [String]$Id,

        [Parameter(HelpMessage="Api version")]
        [String]$Resource,

        [parameter(HelpMessage="Method")]
        [ValidateSet("GET","POST")]
        [String]$Method = "GET",

        [Parameter(HelpMessage="Api version")]
        [String]$ApiVersion
    )
    Begin{
        #Import Localized data
        $LocalizedDataParams = $O365Object.LocalizedDataParams
        Import-LocalizedData @LocalizedDataParams;
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Azure Active Directory Auth
        $rm_auth = $O365Object.auth_tokens.ResourceManager
        $base_uri = [String]::Empty
        $Server = ("{0}" -f $Environment.ResourceManager.Replace('https://',''))
    }
    Process{
        #Add objectId
        if($Id){
            $base_uri = ("{0}/{1}" -f $base_uri, $Id)
        }
        #Add resource
        if($Resource){
            $base_uri = ("{0}/{1}" -f $base_uri, $Resource)
        }
        #Add api version
        $base_uri = ("{0}?api-version={1}" -f $base_uri, $ApiVersion)
        #Remove double slashes
        $final_uri = ("{0}{1}" -f $Server,$base_uri)
        $final_uri = [regex]::Replace($final_uri,"/+","/")
        $final_uri = ("https://{0}" -f $final_uri.ToString())
    }
    End{
        $params = @{
            Authentication = $rm_auth;
            OwnQuery = $final_uri;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = $Method;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        Get-MonkeyRMObject @params
    }
}
