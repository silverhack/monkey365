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

Function Get-MonkeySPSApiSearch{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeySPSApiSearch
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$QueryText,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$endpoint,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("GET")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json, text/plain, */*"
    )
    Begin{
        $URI = $Objects = $null
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online Web API")
             return
        }
        #Get Authorization Header
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        if($endpoint){
            $URI = ("{0}" -f $endpoint)
        }
        else{
            $URI = ("{0}" -f $Authentication.resource)
        }
        if($QueryText){
            #Construct URI
            $URI = "{0}/_api/search/query?querytext='{1}'&trimduplicates=false" -f $URI, [uri]::EscapeDataString($QueryText)
        }
        #Create new Session Id
        $SessionID = (New-Guid).ToString().Replace("-","")
    }
    Process{
        $requestHeader = @{
            "client-request-id" = $SessionID
            "Authorization" = $AuthHeader
        }
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($URI)
        $ServicePoint.ConnectionLimit = 1000;
        try{
            switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $URI;
                            Headers = $requestHeader;
                            Method = $Method;
                            Content_Type = $ContentType;
                            Encoding = $ContentType;
                            UserAgent = $O365Object.UserAgent
                        }
                        $Objects = Invoke-UrlRequest @param
                    }
            }
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
        catch {
            Write-Verbose $_
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
    }
    End{
        if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('PrimaryQueryResult')){
            return $Objects
        }
    }
}
