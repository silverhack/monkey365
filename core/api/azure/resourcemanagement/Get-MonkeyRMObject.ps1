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

Function Get-MonkeyRMObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyRMObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Environment,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ResourceGroup,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Provider,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Query,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.Collections.Hashtable]$Headers,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Data,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$OwnQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$APIVersion
    )
    Begin{
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Resource Management API")
             return
        }
        #Get Authorization Header
        #$AuthHeader = $Authentication.Result.CreateAuthorizationHeader()
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        if($Provider -and $ResourceGroup){
            $URI = '{0}/subscriptions/{1}/resourceGroups/{2}/providers/{3}/{4}?api-version={5}{6}' `
                   -f $Environment.ResourceManager, $Authentication.subscriptionId,`
                      $ResourceGroup, $Provider, $ObjectType.Trim(), $APIVersion, $Query
        }
        elseif($Provider -and -NOT $ResourceGroup){
            $URI = '{0}/subscriptions/{1}/providers/{2}/{3}?api-version={4}{5}' `
                   -f $Environment.ResourceManager, $Authentication.subscriptionId,`
                      $Provider, $ObjectType.Trim(), $APIVersion, $Query
        }
        elseif($OwnQuery){
            $URI = $OwnQuery
        }
        elseif($ObjectId){
            $URI = '{0}/{1}?api-version={2}{3}' -f $Environment.ResourceManager, `
                                                       $ObjectId.Trim(), `
                                                       $APIVersion, $Query
        }
        else{
            $URI = '{0}/subscriptions/{1}/{2}?api-version={3}{4}' -f $Environment.ResourceManager, `
                                                                     $Authentication.subscriptionId, `
                                                                     $ObjectType.Trim(), `
                                                                     $APIVersion, $Query
        }
    }
    Process{
        if($URI){
            $requestHeader = @{"Authorization" = $AuthHeader}
            if($Headers){
                foreach($header in $Headers.GetEnumerator()){
                    $requestHeader.Add($header.Key, $header.Value)
                }
            }
        }
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($URI)
        $ServicePoint.ConnectionLimit = 1000;
        $AllObjects = @()
        try{
            switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $URI;
                            Headers = $requestHeader;
                            Method = $Method;
                            Content_Type = "application/json";
                            UserAgent = $O365Object.UserAgent
                        }
                        $Objects = Invoke-UrlRequest @param
                    }
                    'POST'
                    {
                        if($Data){
                            $param = @{
                                Url = $URI;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                                Data = $Data;
                                UserAgent = $O365Object.UserAgent
                            }
                        }
                        else{
                            $param = @{
                                Url = $URI;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                                UserAgent = $O365Object.UserAgent
                            }
                        }
                        #Launch request
                        $Objects = Invoke-UrlRequest @param
                    }
            }
            if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                $AllObjects+= $Objects.value
            }
            elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                #empty response
                return $Objects.value
            }
            else{
                $AllObjects+= $Objects
            }
            #Search for paging objects
            if ($null -ne $Objects.PSObject.Properties.Item('odata.nextLink')){
                $nextLink = $Objects.'odata.nextLink'
                while ($null -ne $nextLink -and $nextLink.IndexOf('token=') -gt 0){
                    $nextLink = $nextLink.Substring($nextLink.IndexOf('token=') + 6)
                    #Construct URI
                    $URI = '{0}/subscriptions/{1}/{2}?api-version={3}&$top=999&$skiptoken={4}'`
                           -f $Environment.ResourceManager, `
                              $Authentication.subscriptionId, `
                              $ObjectType.Trim(), `
                              $APIVersion, $nextLink
                    #Go to nextPage
                    $param = @{
                        Url = $URI;
                        Method = "Get";
                        Headers = $requestHeader;
                        UserAgent = $O365Object.UserAgent;
                    }
                    $NextPage = Invoke-UrlRequest @param
                    $AllObjects+= $NextPage.value
                    $nextLink = $nextPage.'odata.nextLink'
                }
            }
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
        catch{
            Write-Verbose $_
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
    }
    End{
        if($AllObjects){
            return $AllObjects
        }
    }
}
