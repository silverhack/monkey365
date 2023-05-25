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
        Get objects from Azure subscription

        .DESCRIPTION
        Get objects from Azure subscription

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
    [CmdletBinding()]
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
        [String]$Filter,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$Expand,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String[]]$Select,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$Top,

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
        $final_uri = $null;
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
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Azure Resource Management API")
             break
        }
        #Get Authorization Header
        $methods = $Authentication | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
        if($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $Authentication.CreateAuthorizationHeader()
        }
        else{
            $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        }
        #set rm uri
        if($null -ne $Authentication.Psobject.Properties.Item('subscriptionId')){
            $base_uri = ("subscriptions/{0}" -f $Authentication.subscriptionId)
        }
        else{
            $base_uri = [String]::Empty
        }
        #Set filter
        $my_filter = ('?api-version={0}' -f $APIVersion)
        #Check if query
        if($Query){
            if($null -ne $my_filter){
                $my_filter = ('{0}{1}' -f $my_filter, $Query)
            }
            else{
                $my_filter = ('?{0}' -f $Query)
            }
        }
        #add Expand
        if($Expand){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$expand={1}' -f $my_filter, (@($Expand) -join ','))
            }
            else{
                $my_filter = ('?$expand={0}' -f (@($Expand) -join ','))
            }
        }
        #add Filter
        if($Filter){
            if($null -ne $my_filter){
                if($Filter.Contains(' ')){
                    $my_filter = ('{0}&$filter={1}' -f $my_filter, [uri]::EscapeDataString($Filter))
                }
                else{
                    $my_filter = ('{0}&$filter={1}' -f $my_filter, $Filter)
                }
            }
            else{
                if($Filter.Contains(' ')){
                    $my_filter = ('?$filter={0}' -f [uri]::EscapeDataString($Filter))
                }
                else{
                    $my_filter = ('?$filter={0}' -f $Filter)
                }
            }
        }
        #add select
        if($Select){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$select={1}' -f $my_filter, (@($Select) -join ','))
            }
            else{
                $my_filter = ('?$select={0}' -f (@($Select) -join ','))
            }
        }
        #add top
        if($Top){
            if($null -ne $my_filter){
                $my_filter = ('{0}&$top={1}' -f $my_filter, $Top)
            }
            else{
                $my_filter = ('?$top={0}' -f $Top)
            }
        }
        #Add provider and resource group
        if($ResourceGroup){
            $base_uri = ("{0}/resourceGroups/{1}" -f $base_uri,$ResourceGroup)
        }
        if($Provider -and $ObjectType){
            $base_uri = ("{0}/providers/{1}/{2}" -f $base_uri,$Provider, $ObjectType.Trim())
        }
        if($ObjectId){
            if(-NOT $ResourceGroup -and -NOT $Provider){
                #Probably direct object reference
                $base_uri = ("{0}" -f $ObjectId)
            }
            elseif($ObjectId -like '*subscriptions*' -and ($Provider -and $ObjectType)){
                $base_uri = ("{0}/providers/{1}/{2}" -f $ObjectId,$Provider,$ObjectType.Trim())
            }
            else{
                $base_uri = ("{0}/{1}" -f $base_uri,$ObjectId)
            }
        }
        if(-NOT $ResourceGroup -and -NOT $Provider -and $ObjectType){
            $base_uri = ("{0}/{1}" -f $base_uri,$ObjectType.Trim())
        }
        #Remove double slashes
        $base_uri = [regex]::Replace($base_uri,"/+","/")
        #Add filter
        if($my_filter){
            $base_uri = ("{0}{1}" -f $base_uri,$my_filter)
        }
        #Construct URL
        if($Environment){
            $Server = ("{0}" -f $Environment.ResourceManager.Replace('https://',''))
            $final_uri = ("{0}{1}" -f $Server,$base_uri)
            $final_uri = [regex]::Replace($final_uri,"/+","/")
            $final_uri = ("https://{0}" -f $final_uri.ToString())
        }
        #Check if own query
        if($OwnQuery){
            $final_uri = $OwnQuery
        }
    }
    Process{
        if($final_uri -and $AuthHeader){
            $requestHeader = @{"Authorization" = $AuthHeader}
            if($Headers){
                foreach($header in $Headers.GetEnumerator()){
                    $requestHeader.Add($header.Key, $header.Value)
                }
            }
        }
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($final_uri)
        $ServicePoint.ConnectionLimit = 1000;
        try{
            switch ($Method) {
                'GET'
                {
                    $p = @{
                        Url = $final_uri;
                        Headers = $requestHeader;
                        Method = $Method;
                        Content_Type = "application/json";
                        UserAgent = $O365Object.UserAgent;
                        Verbose = $Verbose;
                        Debug = $Debug;
                        InformationAction = $InformationAction;
                    }
                    $return_objects = Invoke-UrlRequest @p
                }
                'POST'
                {
                    if($Data){
                        $p = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = $Method;
                            Content_Type = $ContentType;
                            Data = $Data;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                    }
                    else{
                        $p = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = $Method;
                            Content_Type = $ContentType;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                    }
                    #send request
                    $return_objects = Invoke-UrlRequest @p
                }
            }
            if($null -ne $return_objects -and $null -ne $return_objects.PSObject.Properties.Item('value') -and $return_objects.value.Count -gt 0){
                #return Value
                $return_objects.value
            }
            elseif($null -ne $return_objects -and $null -ne $return_objects.PSObject.Properties.Item('value') -and $return_objects.value.Count -eq 0){
                #empty response
                $return_objects.value
            }
            else{
                $return_objects
            }
            #Check for paging objects
            if($null -ne $return_objects.PSObject.Properties.Item('odata.nextLink')){
                $nextLink = $return_objects.'odata.nextLink'
            }
            elseif($null -ne $return_objects.PSObject.Properties.Item('nextLink')){
                $nextLink = $return_objects.nextLink
            }
            else{
                $nextLink = $null;
            }
            if ($null -ne $nextLink){
                while ($null -ne $nextLink){
                    #Go to nextPage
                    $p = @{
                        Url = $nextLink;
                        Method = "Get";
                        Headers = $requestHeader;
                        UserAgent = $O365Object.UserAgent;
                        Verbose = $Verbose;
                        Debug = $Debug;
                        InformationAction = $InformationAction;
                    }
                    $NextPage = Invoke-UrlRequest @p
                    if($null -ne $NextPage.PSObject.Properties.Item('odata.nextLink')){
                        $nextLink = $nextPage.'odata.nextLink'
                    }
                    elseif($null -ne $NextPage.PSObject.Properties.Item('nextLink')){
                        $nextLink = $NextPage.nextLink
                    }
                    else{
                        $nextLink = $null
                    }
                    #return object
                    $NextPage.value
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
        ####close all the connections made to the host####
        [void]$ServicePoint.CloseConnectionGroup("")
    }
}
