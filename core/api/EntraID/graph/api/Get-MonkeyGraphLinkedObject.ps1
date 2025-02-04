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

Function Get-MonkeyGraphLinkedObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyGraphLinkedObject
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
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Switch]$GetLinks,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectDisplayName,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Relationship,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$APIVersion
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
        #Set null
        $graphObjects = $null
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Graph")
             break
        }
        if($ObjectId -AND $ObjectDisplayName){
            #Get Auth Header and create URI
            #$AuthHeader = $Authentication.Result.CreateAuthorizationHeader()
            $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
            if($GetLinks){
                $URI = '{0}/{1}/{2}/{3}/$links/{4}?api-version={5}'`
                       -f $Environment.Graph, $Authentication.TenantId, `
                          $ObjectType.Trim(), $ObjectId, `
                          $Relationship, $APIVersion
            }
            else{
                $URI = '{0}/{1}/{2}/{3}/{4}?api-version={5}'`
                       -f $Environment.Graph, $Authentication.TenantId, `
                          $ObjectType.Trim(), $ObjectId, `
                          $Relationship, $APIVersion
            }
        }
        else{
            $URI = $false;
        }
    }
    Process{
        if($URI){
            $all_objects = $null
            $graphObjects = @()
            $requestHeader = @{
                "x-ms-version" = "2014-10-01";
                "Authorization" = $AuthHeader
            }
            ####Workaround for operation timed out ######
            $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($URI)
            $ServicePoint.ConnectionLimit = 1000
            try{
                $param = @{
                    Url = $URI;
                    Headers = $requestHeader;
                    Method = $Method;
                    ContentType = $ContentType;
                    UserAgent = $O365Object.UserAgent;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                $all_objects = Invoke-MonkeyWebRequest @param
                #Get data
                if($null -ne $all_objects -and $all_objects.psobject.Properties.Item('value') -and $all_objects.value.Count -gt 0){
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
                        $nextLink = $nextLink.Substring($nextLink.IndexOf('token=') + 6)
                        if($GetLinks){
                            $URI = '{0}/{1}/{2}/{3}/$links/{4}?api-version={5}&$top=999&$skiptoken={6}'`
                           -f $Environment.Graph, $Authentication.TenantId, `
                              $ObjectType.Trim(), $ObjectId, `
                              $Relationship, $APIVersion, $nextLink
                        }
                        else{
                            $URI = '{0}/{1}/{2}/{3}/{4}?api-version={5}&$top=999&$skiptoken={6}'`
                           -f $Environment.Graph, $Authentication.TenantId, `
                              $ObjectType.Trim(), $ObjectId, $Relationship, `
                              $APIVersion, $nextLink
                        }
                        #Go to NextPage
                        $param = @{
                            Url = $URI;
                            Headers = $requestHeader;
                            Encoding = "application/json";
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @param
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
        #Nothing to do here
    }
}


