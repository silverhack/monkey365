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

        [parameter(Mandatory=$false, HelpMessage="Extra parameters")]
        [System.Collections.Hashtable]$ExtraParameters,

        [parameter(Mandatory=$false, HelpMessage="Method")]
        [ValidateSet("GET","POST")]
        [String]$Method = "GET",

        [Parameter(Mandatory=$false, HelpMessage="POST data")]
        [Object]$Data,

        [Parameter(Mandatory=$true, HelpMessage="Api version")]
        [String]$ApiVersion
    )
    Begin{
        #Get Environment
        $Environment = $O365Object.Environment
        #Get Auth object
        $authObject = $O365Object.auth_tokens.ResourceManager
        #set base uri
        $base_uri = [String]::Empty
        $Server = ("{0}" -f $Environment.ResourceManager.Replace('https://',''))
        #Set filter
        $my_filter = [System.Text.StringBuilder]::new()
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
        [void]$my_filter.Append(("?api-version={0}" -f $ApiVersion))
        #Add extra params to query
        If($ExtraParameters){
            Foreach($extraParam in $ExtraParameters.GetEnumerator()){
                [void]$my_filter.Append(('&{0}={1}' -f $extraParam.Name,$extraParam.Value ))
            }
        }
        #add Expand
        If($Expand){
            [void]$my_filter.Append(('&$expand={0}' -f (@($Expand) -join ',')))
        }
        If($Filter){
            If($Filter.Contains(' ')){
                [void]$my_filter.Append(('&$filter={0}' -f [uri]::EscapeDataString($Filter)))
            }
            else{
                [void]$my_filter.Append(('&$filter={0}' -f $Filter))
            }
        }
        $base_uri = ("{0}{1}" -f $base_uri, $my_filter.ToString())
        #Remove double slashes
        $final_uri = ("{0}{1}" -f $Server,$base_uri)
        $final_uri = [regex]::Replace($final_uri,"/+","/")
        $final_uri = ("https://{0}" -f $final_uri.ToString())
    }
    End{
        $p = @{
            Authentication = $authObject;
            OwnQuery = $final_uri;
            Environment = $Environment;
            ContentType = 'application/json';
            Method = $Method;
            Data = $Data;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        Get-MonkeyRMObject @p
    }
}
