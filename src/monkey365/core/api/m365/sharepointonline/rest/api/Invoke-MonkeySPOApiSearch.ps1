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

Function Invoke-MonkeySPOApiSearch{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeySPOApiSearch
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$QueryText,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$Endpoint,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("GET")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json, text/plain, */*"
    )
    Begin{
        $Path = $URL = $Objects = $null
        #Set False
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        if($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        if($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        if($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online Web API")
             break
        }
        #Get Authorization Header
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        if($Endpoint){
            $Server = [System.Uri]::new($Endpoint)
        }
        else{
            $Server = [System.Uri]::new($Authentication.resource)
        }
        #Set site path
        if($QueryText){
            #Construct URI
            if($Server.Segments.Contains('sites/')){
                $Path = "{0}/_api/search/query?querytext='{0}'&trimduplicates=false" -f $Server.AbsolutePath, [uri]::EscapeDataString($QueryText)
                #Remove double slashes
                $Path = [regex]::Replace($Path,"/+","/")
            }
            else{
                $Path = "/_api/search/query?querytext='{0}'&trimduplicates=false" -f [uri]::EscapeDataString($QueryText)
            }
        }
        if($null -ne $Path){
            $URL = [System.Uri]::new($Server,$Path)
            $URL = $URL.ToString()
        }
        #Create new Session Id
        $SessionID = (New-Guid).ToString().Replace("-","")
    }
    Process{
        if($null -ne $URL){
            $requestHeader = @{
                "client-request-id" = $SessionID
                "Authorization" = $AuthHeader
            }
            #Perform query
            try{
                switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $URL;
                            Headers = $requestHeader;
                            Method = $Method;
                            ContentType = $ContentType;
                            Accept = $ContentType;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $Objects = Invoke-MonkeyWebRequest @param
                        If($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('PrimaryQueryResult')){
                            return $Objects
                        }
                    }
                }
            }
            catch {
                Write-Error $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}

