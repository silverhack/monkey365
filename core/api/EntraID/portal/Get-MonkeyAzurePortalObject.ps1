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

Function Get-MonkeyAzurePortalObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyAzurePortalObject
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
        [String]$Query,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$OwnQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$PostData,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [Switch]$EncodeGet
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
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Azure AAD Portal")
             break
        }
        #Get Authorization Header
        $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        if($Query){
            #Construct URI
            $URI = '{0}/{1}' -f $Environment.AADPortal, $Query
        }
        ElseIf($OwnQuery){
            $URI = $OwnQuery
        }
        Else{
            return $null
        }
        $SessionID = (New-Guid).ToString().Replace("-","")
    }
    Process{
        $requestHeader = @{
            "X-Requested-With" = "XMLHttpRequest"
            "X-Ms-Client-Request-Id" = (New-Guid).ToString()
            "X-Ms-Client-Session-Id" = $SessionID
            "x-ms-version" = '2018-03-28'
            "Authorization" = $AuthHeader
        }
        #Perform query
        try{
            switch ($Method) {
                'GET'
                {
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
                    $Objects = Invoke-MonkeyWebRequest @param
                }
                'POST'
                {
                    if($PostData){
                        if($PostData -isnot [System.String]){
                            try{
                                $PostData = $PostData | ConvertTo-Json -Depth 100
                            }
                            catch{
                                Write-Error $_
                            }
                        }
                        $param = @{
                            Url = $URI;
                            Headers = $requestHeader;
                            Method = $Method;
                            ContentType = $ContentType;
                            Data = $PostData;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                    }
                    else{
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
                    }
                    #Launch request
                    $Objects = Invoke-MonkeyWebRequest @param
                }
            }
            if($null -ne $Objects){
                If($Objects -is [System.Array]){
                    #return array
                    $Objects
                }
                ElseIf($null -ne $Objects.psobject.Properties.Item('value') -and ($Objects.value)){
                    #return value
                    $Objects.value
                }
                ElseIf($null -ne $Objects.psobject.Properties.Item('items') -and ($Objects.items)){
                    #return items
                    $Objects.items
                }
                ElseIf($null -ne $Objects.psobject.Properties.Item('appList') -and ($Objects.appList)){
                    #return appList
                    $Objects.appList
                }
                Else{
                    $Objects
                }
                if(($Objects -is [System.Object]) -and ($null -ne $Objects.psobject.Properties.Item('nextLink')) -and ($Objects.nextLink)){
                    $NextLink = $Objects.nextLink
                }
                ElseIf(($Objects -is [System.Object]) -and ($null -ne $Objects.psobject.Properties.Item('@odata.nextLink')) -and ($Objects.'@odata.nextLink')){
                    $NextLink = $Objects.'@odata.nextLink'
                }
                else{
                    $NextLink = $null
                }
                #Search for paging objects
                while($null -ne $NextLink){
                    Write-Verbose -Message ("Working on {0}" -f $NextLink)
                    #New Request Header
                    $requestHeader = @{
                        "X-Requested-With" = "XMLHttpRequest"
                        "X-Ms-Client-Request-Id" = (New-Guid).ToString()
                        "X-Ms-Client-Session-Id" = $SessionID
                        "Authorization" = $AuthHeader
                    }
                    if($Method.ToUpper() -eq "POST"){
                        $NextLink = '"{0}"' -f $NextLink
                        $param = @{
                            Url = $URI;
                            Headers = $requestHeader;
                            Method = $Method;
                            ContentType = $ContentType;
                            UserAgent = $O365Object.UserAgent;
                            Data = $NextLink;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $more_objects = Invoke-MonkeyWebRequest @param
                    }
                    ElseIf($Method.ToUpper() -eq "GET"){
                        if($EncodeGet){
                            $NextLink = [uri]::EscapeDataString($NextLink)
                            $NextLink = $NextLink.Replace("%27","'")
                        }
                        if($URI -like "*nextLink=&*"){
                            $URI = $URI.Replace("nextLink=",("nextLink={0}" -f $NextLink))
                        }
                        ElseIf($URI -like "*nextLink=null*"){
                            $URI = $URI.Replace("nextLink=null",("nextLink={0}" -f $NextLink))
                        }
                        ElseIf($URI -like "*nextLink=*"){
                            $tmpUrl = ($URI -split 'nextLink=')[0]
                            $params = ($URI -split '&') | Select-Object -Last 2
                            $params = $params -join "&"
                            $URI = ("{0}nextLink={1}&{2}" -f $tmpUrl,$NextLink,$params)
                            #$URI = $URI.Replace("*nextLink=*",("nextLink={0}" -f $NextLink))
                        }
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
                        $more_objects = Invoke-MonkeyWebRequest @param
                    }
                    if($null -ne $more_objects){
                        if(($more_objects -is [System.Object]) -and ($null -ne $more_objects.psobject.Properties.Item('nextLink')) -and ($more_objects.nextLink)){
                            $NextLink = $more_objects.nextLink
                        }
                        ElseIf(($more_objects -is [System.Object]) -and ($null -ne $more_objects.psobject.Properties.Item('@odata.nextLink')) -and ($more_objects.'@odata.nextLink')){
                            $NextLink = $more_objects.'@odata.nextLink'
                        }
                        else{
                            $NextLink = $null
                        }
                        If($null -ne $more_objects.psobject.Properties.Item('value') -and ($more_objects.value)){
                            #return Value
                            $more_objects.value
                        }
                        ElseIf($null -ne $more_objects.psobject.Properties.Item('items') -and ($more_objects.items)){
                            #return Items
                            $more_objects.items
                        }
                        ElseIf($null -ne $more_objects.psobject.Properties.Item('appList') -and ($more_objects.appList)){
                            #return appList
                            $more_objects.appList
                        }
                        else{
                            $more_objects
                        }
                    }
                    else{
                        $NextLink = $null
                    }
                }
            }
        }
        catch {
            Write-Verbose $_
        }
    }
    End{
        #Nothing to do here
    }
}
