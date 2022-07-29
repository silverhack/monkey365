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

Function Get-TeamsObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-TeamsObject
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
        [ValidateSet("PowerShell","SkypeNetwork","SkypePolicy","TeamsUser","TeamsTenant")]
        [String]$InternalPath = 'PowerShell',

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ObjectId,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ResultSize,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$AdminDomain,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$Select,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$RawQuery,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$pageSize,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "application/json",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [object]$Data
    )
    Begin{
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft 365 Teams")
             return
        }
        #Get internal Path
        switch ($InternalPath) {
            'PowerShell'{$path = 'OcsPowershellWebservice'}
            'SkypeNetwork'{$path = 'Skype.Ncs'}
            'SkypePolicy'{$path = 'Skype.Policy'}
            'TeamsUser'{$path = 'Teams.User'}
            'TeamsTenant'{$path = 'Teams.Tenant'}
        }
        #Get Authorization Header
        $AuthHeader = $Authentication.CreateAuthorizationHeader()
        #set msgraph uri
        $base_uri = ("{0}/{1}" -f $Environment.Teams, $path)
        $my_filter = $null
        #construct query
        if($AdminDomain){
            if($null -ne $my_filter){
                $my_filter = ('{0}&adminDomain={1}' -f $my_filter, $AdminDomain)
            }
            else{
                $my_filter = ('?adminDomain={0}' -f $AdminDomain)
            }
        }
        if($pageSize){
            if($null -ne $my_filter){
                $my_filter = ('{0}&pageSize={1}' -f $my_filter, $pageSize)
            }
            else{
                $my_filter = ('?pageSize={0}' -f $pageSize)
            }
        }
        if($Select){
            if($null -ne $my_filter){
                $my_filter = ('{0}&select={1}' -f $my_filter, (@($Select) -join ','))
            }
            else{
                $my_filter = ('?select={0}' -f (@($Select) -join ','))
            }
        }
        if($ResultSize){
            if($null -ne $my_filter){
                $my_filter = ('{0}&ResultSize={1}' -f $my_filter, $ResultSize)
            }
            else{
                $my_filter = ('?ResultSize={0}' -f $ResultSize)
            }
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
                $final_uri = ("{0}/{1}{2}" -f $base_uri,$RawQuery,$my_filter)
            }
            else{
                $final_uri = ("{0}/{1}" -f $base_uri,$RawQuery)
            }
        }
    }
    Process{
        $requestHeader = @{
            "x-ms-correlation-id" = (New-Guid).ToString()
            "x-ms-tenant-id" = $Authentication.TenantId
            "Authorization" = $AuthHeader
        }
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($final_uri)
        $ServicePoint.ConnectionLimit = 1000;
        try{
            $AllObjects = @()
            switch ($Method) {
                    'GET'
                    {
                        $param = @{
                            Url = $final_uri;
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
            if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                $AllObjects+= $Objects.value
            }
            elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                #empty response
                return $Objects.value
            }
            #Search by object
            elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item($ObjectType)){
                #custom object response
                $AllObjects+= $Objects.$($ObjectType)
            }
            else{
                $AllObjects+= $Objects
            }
            #Search for paging objects
            if ($Objects.PsObject.Properties.Item('@nextLink')){
                $nextLink = $Objects.'@nextLink'
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
                    if($null -ne $NextPage -and $null -ne $NextPage.PSObject.Properties.Item('value') -and $NextPage.value.Count -gt 0){
                        $AllObjects+= $NextPage.value
                    }
                    #Search by object
                    elseif($null -ne $NextPage -and $null -ne $NextPage.PSObject.Properties.Item($ObjectType)){
                        #custom object response
                        $AllObjects+= $NextPage.$($ObjectType)
                    }
                    else{
                        $AllObjects+= $NextPage
                    }
                    If($NextPage.PsObject.Properties.Item('@nextLink')){
                        $nextLink = $nextPage.'@nextLink'
                    }
                    else{
                        $nextLink = $null
                    }
                }
            }
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
        }
        catch{
            Write-Verbose $_
            ####close all the connections made to the host####
            [void]$ServicePoint.CloseConnectionGroup("")
            return $null
        }
    }
    End{
        if($AllObjects){
            return $AllObjects
        }
    }
}
