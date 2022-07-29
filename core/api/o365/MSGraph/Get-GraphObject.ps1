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

Function Get-GraphObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-GraphObject
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
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Filter,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Expand,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Top,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$orderBy,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$Select,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$Count,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [switch]$me,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$RawQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Data,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft Graph API")
             return
        }
        #Get Authorization Header
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        #set msgraph uri
        $base_uri = ("{0}/{1}" -f $Environment.Graphv2, $APIVersion)
        $my_filter = $null
        #construct query
        if($Expand){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$expand={1}' -f $my_filter, $Expand)
            }
            else{
                $my_filter = ('?$expand={0}' -f $Expand)
            }
        }
        if($Filter){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$filter={1}' -f $my_filter, [uri]::EscapeDataString($Filter))
            }
            else{
                $my_filter = ('?$filter={0}' -f [uri]::EscapeDataString($Filter))
            }
        }
        if($Select){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$select={1}' -f $my_filter, (@($Select) -join ','))
            }
            else{
                $my_filter = ('?$select={0}' -f (@($Select) -join ','))
            }
        }
        if($orderBy){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$orderby={1}' -f $my_filter, $orderBy)
            }
            else{
                $my_filter = ('?$orderby={0}' -f $orderBy)
            }
        }
        if($Top){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$top={1}' -f $my_filter, $Top)
            }
            else{
                $my_filter = ('?$top={0}' -f $Top)
            }
        }
        if($Count){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$count=true' -f $my_filter)
            }
            else{
                $my_filter = ('?$count=true' -f $Top)
            }
        }
        if($me){
            $base_uri = ("{0}/me" -f $base_uri)
        }
        if($ObjectType){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectType)
        }
        if($ObjectId){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectId)
        }
        #construct final URI
        if($my_filter){
            $final_uri = ("{0}{1}" -f $base_uri,$my_filter)
        }
        else{
            $final_uri = $base_uri
        }
        if($RawQuery){
            if($my_filter){
                $final_uri = ("{0}{1}" -f $RawQuery,$my_filter)
            }
            else{
                $final_uri = ("{0}" -f $RawQuery)
            }
        }
    }
    Process{
        if($final_uri){$requestHeader = @{"x-ms-version" = "2014-10-01";"Authorization" = $AuthHeader}}
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($final_uri)
        $ServicePoint.ConnectionLimit = 1000;
        $AllObjects = @()
        try{
            switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $final_uri;
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
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                                Data = $Data;
                                UserAgent = $O365Object.UserAgent
                            }
                        }
                        else{
                            $param = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                Content_Type = $ContentType;
                                UserAgent = $O365Object.UserAgent
                            }
                        }
                        #Execute Query request
                        $Objects = Invoke-UrlRequest @param
                    }
            }
            if($ObjectType){
                Write-Verbose ("Getting {0} from microsoft graph" -f $ObjectType)
            }
            else{
                Write-Verbose $final_uri
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
            if ($Objects.PsObject.Properties.Item('@odata.nextLink')){
                $nextLink = $Objects.'@odata.nextLink'
                while ($null -ne $nextLink){
                    ####Workaround for operation timed out ######
                    #https://social.technet.microsoft.com/wiki/contents/articles/29863.powershell-rest-api-invoke-restmethod-gotcha.aspx
                    $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($nextLink)
                    #Make RestAPI call
                    $param = @{
                        Url = $nextLink;
                        Method = "Get";
                        Headers = $requestHeader;
                        UserAgent = $O365Object.UserAgent;
                    }
                    $NextPage = Invoke-UrlRequest @param
                    $AllObjects+= $NextPage.value
                    $nextLink = $nextPage.'@odata.nextLink'
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
