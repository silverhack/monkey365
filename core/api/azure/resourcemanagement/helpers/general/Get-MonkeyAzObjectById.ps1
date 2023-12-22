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
        [Parameter(Mandatory=$false, HelpMessage="Object Id")]
        [String]$Id,

        [Parameter(Mandatory=$false, HelpMessage="Resource")]
        [String]$Resource,

        [Parameter(Mandatory=$false, HelpMessage="Filter")]
        [String]$Filter,

        [parameter(Mandatory=$false, HelpMessage="Expand")]
        [String[]]$Expand,

        [parameter(Mandatory=$false, HelpMessage="Method")]
        [ValidateSet("GET","POST")]
        [String]$Method = "GET",

        [Parameter(Mandatory=$true, HelpMessage="Api version")]
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
        #Set filter
        $my_filter = [String]::Empty
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
        if($Filter){
            If($Filter.Contains(' ')){
                $my_filter = ('&$filter={0}' -f [uri]::EscapeDataString($Filter))
            }
            else{
                $my_filter = ('&$filter={0}' -f $Filter)
            }
        }
        #add Expand
        if($Expand){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$expand={1}' -f $my_filter, (@($Expand) -join ','))
            }
            else{
                $my_filter = ('?$expand={0}' -f (@($Expand) -join ','))
            }
        }
        #Add api version
        $my_filter = ("?api-version={0}{1}" -f $ApiVersion,$my_filter)
        $base_uri = ("{0}{1}" -f $base_uri, $my_filter)
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
