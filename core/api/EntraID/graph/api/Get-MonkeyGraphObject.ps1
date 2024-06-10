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

Function Get-MonkeyGraphObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Environment,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$TenantId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Filter,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Top,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Query,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$OwnQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$APIVersion,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Data,

        [Parameter(Mandatory=$false, HelpMessage="Return raw response")]
        [Switch]
        $returnRawResponse
    )
    Begin{
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
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Graph")
             break
        }
        #Get Authorization Header
        $methods = $Authentication | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
        #Get Authorization Header
        if($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $Authentication.CreateAuthorizationHeader()
        }
        else{
            $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        }
        #set graph uri
        if($TenantId){
            $base_uri = ("/{0}" -f $TenantId)
        }
        elseif($null -ne $Authentication.PsObject.Properties.Item('TenantId')){
            $base_uri = ("/{0}" -f $Authentication.TenantId)
        }
        else{
            $base_uri = ("/myOrganization")
        }
        $my_filter = ("?api-version={0}" -f $APIVersion)
        #Check if filter
        if($Filter){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$filter={1}' -f $my_filter, [uri]::EscapeDataString($Filter))
            }
            else{
                $my_filter = ('?$filter={0}' -f [uri]::EscapeDataString($Filter))
            }
        }
        #Check if Top
        if($Top){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$top={1}' -f $my_filter, $Top)
            }
            else{
                $my_filter = ('?$top={0}' -f $Top)
            }
        }
        if($ObjectType){
            #Set base url
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectType)
        }
        if($ObjectId){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectId)
        }
        #Append filter to query
        if($my_filter){
            $base_uri = ("{0}{1}" -f $base_uri,$my_filter)
        }
        #Remove double slashes
        $base_uri = [regex]::Replace($base_uri,"/+","/")
        #Construct final URI
        $Server = [System.Uri]::new($Environment.Graph)
        $final_uri = [System.Uri]::new($Server,$base_uri)
        $final_uri = $final_uri.ToString()
        #Check if ownQuery
        if($OwnQuery){
            if($my_filter -and -NOT $OwnQuery.Contains('api-version')){
                $final_uri = ("{0}{1}" -f $OwnQuery,$my_filter)
            }
            else{
                $final_uri = ("{0}" -f $OwnQuery)
            }
        }
    }
    Process{
        if($final_uri){
            $all_objects = $null
            try{
                $requestHeader = @{
                    "Authorization" = $AuthHeader
                }
                switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = $Method;
                            ContentType = $ContentType;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $all_objects = Invoke-MonkeyWebRequest @param
                    }
                    'POST'
                    {
                        if($Data){
                            $param = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                ContentType = $ContentType;
                                Data = $Data;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                        }
                        else{
                            $param = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                ContentType = $ContentType;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                        }
                        #Launch request
                        $all_objects = Invoke-MonkeyWebRequest @param
                    }
                }
                #Get data
                if($null -ne $all_objects -and $returnRawResponse){
                    #return all objects
                    $all_objects
                }
                elseif($null -ne $all_objects -and $all_objects.psobject.Properties.Item('value') -and @($all_objects.value).Count -gt 0){
                    #return value
                    $all_objects.value
                }
                elseif($null -ne $all_objects -and $all_objects.psobject.Properties.Item('value') -and $all_objects.value.Count -eq 0){
                    #empty response
                    $all_objects.value
                }
                else{
                    $all_objects
                }
                if ($null -ne $all_objects -AND $null -ne $all_objects.psobject.Properties.Item('odata.nextLink')){
                    $nextLink = $all_objects.'odata.nextLink'
                    while ($null -ne $nextLink -and $nextLink.IndexOf('token=') -gt 0){
                        <#
                        $nextLink = $nextLink.Substring($nextLink.IndexOf('token=') + 6)
                        $URI = '{0}/{1}/{2}?api-version={3}&$top=999&$skiptoken={4}'`
                        -f $Environment.Graph, $Authentication.TenantId, $ObjectType.Trim(), $APIVersion, $nextLink
                        #>

                        if($TenantId){
                            $base_uri = ("/{0}" -f $TenantId)
                        }
                        elseif($null -ne $Authentication.PsObject.Properties.Item('TenantId')){
                            $base_uri = ("/{0}" -f $Authentication.TenantId)
                        }
                        else{
                            $base_uri = ("/myOrganization")
                        }
                        if($Top){
                            $URI = ('{0}{1}/{2}&$top={3}&api-version={4}' -f $Environment.Graph,$base_uri,$nextLink, $Top, $APIVersion)
                        }
                        else{
                            $URI = ("{0}{1}/{2}&api-version={3}" -f $Environment.Graph,$base_uri,$nextLink, $APIVersion)
                        }
                        #Go to nextPage
                        $param = @{
                            Url = $URI;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @param
                        #Get nextLink
                        if($null -ne $NextPage -and $null -ne $NextPage.PSObject.Properties.Item('odata.nextLink')){
                            $nextLink = $NextPage.'odata.nextLink'
                        }
                        else{
                            $nextLink = $null
                        }
                        #return value if any
                        if($null -ne $NextPage -and $NextPage.psobject.Properties.Item('value') -and $NextPage.value.Count -gt 0){
                            $NextPage.value
                        }
                        else{
                            $NextPage
                        }
                    }
                }
            }
            catch{
                Write-Verbose $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}
