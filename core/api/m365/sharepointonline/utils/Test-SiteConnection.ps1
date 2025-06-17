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

Function Test-SiteConnection{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Test-SiteConnection
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [Parameter(Mandatory=$true, HelpMessage="Authentication Object")]
        [object]$Authentication,

        [Parameter(Mandatory=$true, HelpMessage="SharePoint url")]
        [String]$Site
    )
    try{
        $post_data = '<?xml version="1.0" encoding="utf-8"?><soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"><soap:Body><GetUpdatedFormDigestInformation xmlns="http://schemas.microsoft.com/sharepoint/soap/" /></soap:Body></soap:Envelope>'
        if($null -eq $Authentication){
            Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online Web API")
            return
        }
        $sps_web_auth = $Authentication.CreateAuthorizationHeader()
        $headers = @{
            Authorization=$sps_web_auth;
        }
        $uri = ("{0}/_vti_bin/sites.asmx" -f $Site)
        $param = @{
            url = $uri;
            headers = $headers;
            Method = "POST";
            Data = $post_data;
            ContentType = "text/xml";
            UserAgent = $O365Object.userAgent;
            InformationAction = $O365Object.InformationAction;
            Verbose = $O365Object.verbose;
            Debug = $O365Object.debug;
        }
        #Execute query
        [xml]$raw_data = Invoke-MonkeyWebRequest @param
        if($null -ne $raw_data){
            $site_availability = $raw_data.Envelope.Body.GetUpdatedFormDigestInformationResponse.GetUpdatedFormDigestInformationResult.WebFullUrl
        }
        else{
            $site_availability = $null
        }
        return $site_availability
    }
    catch{
        $msg = @{
            MessageData = ("Unable to check {0} for connection" -f $site);
            callStack = (Get-PSCallStack | Select-Object -First 1);
            logLevel = 'warning';
            InformationAction = $O365Object.InformationAction;
            Tags = @('TestSiteConnection');
        }
        Write-Warning @msg
        #Set verbose
        $msg.MessageData = $_
        $msg.logLevel = 'Verbose'
        [void]$msg.Add('Verbose',$O365Object.verbose)
        Write-Verbose @msg
        return $null
    }
}

