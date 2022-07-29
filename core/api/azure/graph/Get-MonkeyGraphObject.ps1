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

    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Object]$Environment,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

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
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Graph")
             return
        }
        #Write Progress information
        $statusBar=@{
                Activity = "Azure Graph Query"
                CurrentOperation=""
                Status="Script started"
        }
        #$AuthHeader = $Authentication.Result.CreateAuthorizationHeader()
        $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        if($OwnQuery){
            [String]$startCon = ("Starting Azure rest query on {0}" -f $OwnQuery)
            $URI = $OwnQuery
        }
        elseif ($ObjectType){
            $URI = '{0}/{1}/{2}?api-version={3}{4}' -f $Environment.Graph, `
                                                       $Authentication.TenantId, `
                                                       $ObjectType.Trim(), `
                                                       $APIVersion, $Query

            [String]$startCon = ("Starting Azure rest query on {0} to get {1}" -f $Environment.Graph, $ObjectType.Trim())
        }
        else{
            $URI = $false;
        }
    }
    Process{
        if($URI){
            #Set statusBar
            $statusBar.Status = $startCon
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($URI)
            $ServicePoint.ConnectionLimit = 1000;
            $all_objects = $null
            $graphObjects = @()
            try{
                $requestHeader = @{
                    "x-ms-version" = "2014-10-01";
                    "Authorization" = $AuthHeader
                }
                Write-Progress @statusBar
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
                        $all_objects = Invoke-UrlRequest @param
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
                        $all_objects = Invoke-UrlRequest @param
                    }
                }
                #Get data
                if($null -ne $all_objects -and $returnRawResponse){
                    return $all_objects
                }
                elseif($null -ne $all_objects -and $all_objects.psobject.Properties.Item('value') -and $all_objects.value.Count -gt 0){
                    $graphObjects+= $all_objects.value
                }
                elseif($null -ne $all_objects -and $all_objects.psobject.Properties.Item('value') -and $all_objects.value.Count -eq 0){
                    #empty response
                    return $all_objects.value
                }
                else{
                    $graphObjects+= $all_objects
                }
                if ($null -ne $all_objects -AND $null -ne $all_objects.psobject.Properties.Item('odata.nextLink')){
                    $nextLink = $all_objects.'odata.nextLink'
                    while ($null -ne $nextLink -and $nextLink.IndexOf('token=') -gt 0){
                        $statusBar.CurrentOperation = ("Getting {0}" -f $ObjectType.Trim())
                        $statusBar.Status = $graphObjects.Count
                        Write-Progress @statusBar
                        $nextLink = $nextLink.Substring($nextLink.IndexOf('token=') + 6)
                        $URI = '{0}/{1}/{2}?api-version={3}&$top=999&$skiptoken={4}'`
                        -f $Environment.Graph, $Authentication.TenantId, $ObjectType.Trim(), $APIVersion, $nextLink
                        #Go to nextPage
                        $param = @{
                            Url = $URI;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                        }
                        $NextPage = Invoke-UrlRequest @param
                        #Get Value and nextLink if any
                        if($null -ne $NextPage -and $NextPage.psobject.Properties.Item('value') -and $NextPage.value.Count -gt 0){
                            $graphObjects+= $NextPage.value
                        }
                        else{
                            $graphObjects+= $NextPage
                        }
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
    }
    End{
        if($graphObjects){
            Write-Progress -Activity ("Azure request for object type {0}" -f $ObjectType.Trim()) -Completed -Status "Status: Completed"
            return $graphObjects
        }
    }
}
