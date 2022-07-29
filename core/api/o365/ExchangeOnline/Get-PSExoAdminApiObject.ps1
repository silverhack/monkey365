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

Function Get-PSExoAdminApiObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-PSExoAdminApiObject
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
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$extraParameters,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$OwnQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json;odata.metadata=minimal",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Data
    )
    Begin{
        $extra_params = $null
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Exchange Online API")
             return
        }
        #Get Authorization Header
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        if($extraParameters){
            $extra_params = ('?{0}' -f $extraParameters)
        }
        if($ObjectType){
            #Construct URI
            $URI = '{0}/adminapi/beta/{1}/{2}' -f $Environment.Outlook, $Authentication.TenantId, $ObjectType
        }
        ElseIf($OwnQuery){
            $URI = $OwnQuery
        }
        Else{
            return $null
        }
        if($extra_params){
            $URI = ("{0}{1}" -f $URI,$extra_params)
        }
        $SessionID = (New-Guid).ToString().Replace("-","")
    }
    Process{
        $requestHeader = @{
            "client-request-id" = $SessionID
            "Prefer" = 'odata.maxpagesize=1000;'
            "Authorization" = $AuthHeader
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
                            Content_Type = $ContentType;
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
            elseIf($Objects -is [System.Array]){
                $AllObjects+= $Objects
            }
            Else{
                $AllObjects+= $Objects
            }
            if ($Objects.PsObject.Properties.Item('@odata.nextLink')){
                $NextLink = $Objects.'@odata.nextLink'
                #Search for paging objects
                while($null -ne $NextLink){
                    #New Request Header
                    $requestHeader = @{
                        "client-request-id" = $SessionID
                        "Prefer" = 'odata.maxpagesize=1000;'
                        "Authorization" = $AuthHeader
                    }
                    If($Method.ToUpper() -eq "GET"){
                        $param = @{
                            Url = $NextLink;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                        }
                        $Objects = Invoke-UrlRequest @param
                        If($Objects.PsObject.Properties.Item('@odata.nextLink')){
                            $NextLink = $Objects.'@odata.nextLink'
                        }
                        else{
                            $NextLink = $null
                        }
                        if($Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                            $AllObjects+= $Objects.value
                        }
                        else{
                            $AllObjects+= $Objects
                        }
                    }
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
        if($AllObjects){
            return $AllObjects
        }
    }
}
