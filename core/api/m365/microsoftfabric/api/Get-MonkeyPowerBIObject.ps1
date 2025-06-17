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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function Get-MonkeyPowerBIObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyPowerBIObject
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage='Authentication Object')]
        [Object]$Authentication,

        [parameter(Mandatory=$true, HelpMessage='Environment')]
        [Object]$Environment,

        [Parameter(Mandatory = $false, HelpMessage='Object Type')]
        [String]$ObjectType,

        [Parameter(Mandatory = $false, HelpMessage = 'Object ID')]
        [String]$ObjectId,

        [Parameter(Mandatory = $false, HelpMessage='Object Path')]
        [String]$ObjectPath,

        [parameter(Mandatory=$False, HelpMessage='Filter')]
        [String]$Filter,

        [parameter(Mandatory=$False, HelpMessage='Expand')]
        [String[]]$Expand,

        [parameter(Mandatory=$False, HelpMessage='Top objects')]
        [String]$Top,

        [parameter(Mandatory=$False, HelpMessage='Skip objects')]
        [String]$Skip,

        [parameter(Mandatory=$False, HelpMessage='Scope')]
        [ValidateSet("Individual","Organization")]
        [String]$Scope = "Individual",

        [parameter(Mandatory=$False, HelpMessage='Order by')]
        [String]$orderBy,

        [parameter(Mandatory=$False, HelpMessage='Select objects')]
        [String[]]$Select,

        [parameter(Mandatory=$False, HelpMessage='Count')]
        [switch]$Count,

        [parameter(Mandatory=$False, HelpMessage='RAW query')]
        [String]$RawQuery,

        [parameter(Mandatory=$False, HelpMessage='Method')]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(Mandatory=$False, HelpMessage='Content Type')]
        [String]$ContentType = "application/json",

        [parameter(Mandatory=$False, HelpMessage='POST Data')]
        [Object]$Data,

        [parameter(Mandatory=$False, HelpMessage='API version')]
        [String]$APIVersion = "v1.0",

        [parameter(Mandatory=$False, HelpMessage='Use Expect headers')]
        [switch]$useExpect
    )
    Begin{
        #Set null
        $AuthHeader = $my_filter = $final_uri = $null
        #set count
        $countObjects = 0;
        #Get Authorization Header
        $methods = $Authentication | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name -ErrorAction Ignore
        #Get Authorization Header
        If($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $Authentication.CreateAuthorizationHeader()
        }
        Else{
            #Get Access token
            $at = $Authentication | Select-Object -ExpandProperty AccessToken -ErrorAction Ignore
            If($null -ne $at){
                $AuthHeader = ("Bearer {0}" -f $at)
            }
            Else{
                Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft PowerBI API")
                break
            }
        }
        If($RawQuery){
            $final_uri = $RawQuery
        }
        Else{
            #set msgraph uri
            If($PSBoundParameters.ContainsKey('scope') -and $PSBoundParameters.scope -eq 'Organization'){
                $base_uri = ("/{0}/myorg/admin" -f $APIVersion)
            }
            Else{
                $base_uri = ("/{0}/myorg" -f $APIVersion)
            }
            #Set expand
            If($Expand){
                $_expand = (@($Expand) -join ',')
                If($null -ne $my_filter){
                    $my_filter = ('{0}&$expand={1}' -f $my_filter, [uri]::EscapeDataString($_expand))
                }
                Else{
                    $my_filter = ('?$expand={0}' -f [uri]::EscapeDataString($_expand))
                }
            }
            #Set filter
            If($Filter){
                If($null -ne $my_filter){
                    $my_filter = ('{0}&$filter={1}' -f $my_filter, [uri]::EscapeDataString($Filter))
                }
                Else{
                    $my_filter = ('?$filter={0}' -f [uri]::EscapeDataString($Filter))
                }
            }
            #Set select option
            If($Select){
                If($null -ne $my_filter){
                    $my_filter = ('{0}&$select={1}' -f $my_filter, (@($Select) -join ','))
                }
                Else{
                    $my_filter = ('?$select={0}' -f (@($Select) -join ','))
                }
            }
            #Set Order by
            If($orderBy){
                If($null -ne $my_filter){
                    $my_filter = ('{0}&$orderby={1}' -f $my_filter, $orderBy)
                }
                Else{
                    $my_filter = ('?$orderby={0}' -f $orderBy)
                }
            }
            #Set top
            If($Top){
                If($null -ne $my_filter){
                    $my_filter = ('{0}&$top={1}' -f $my_filter, $Top)
                }
                Else{
                    $my_filter = ('?$top={0}' -f $Top)
                }
            }
            #Set count
            If($Count){
                If($null -ne $my_filter){
                    $my_filter = ('{0}&$count=true' -f $my_filter)
                }
                Else{
                    $my_filter = ('?$count=true' -f $Top)
                }
            }
            #Set object type
            If($ObjectType){
                $base_uri = ("{0}/{1}" -f $base_uri, $ObjectType)
                #Check If also ObjectId is present
                If($ObjectId){
                    $base_uri = ("{0}/{1}" -f $base_uri, $ObjectId)
                }
                #Check If also ObjectPath is present
                If($ObjectPath){
                    $base_uri = ("{0}/{1}" -f $base_uri, $ObjectPath)
                }
            }
            #Append filter to query
            If($my_filter){
                $base_uri = ("{0}{1}" -f $base_uri,$my_filter)
            }
            #Construct final URI
            $Server = ("{0}" -f $Environment.PowerBIAPI.Replace('https://',''))
            $final_uri = ("{0}{1}" -f $Server,$base_uri)
            $final_uri = [regex]::Replace($final_uri,"/+","/")
            $final_uri = ("https://{0}" -f $final_uri.ToString())
        }
    }
    Process{
        If($null -ne $final_uri){
            #Create Request Header
            $requestHeader = @{
                Authorization = $AuthHeader
            }
            #Set Expect 100 continue
            If($useExpect){
                [void]$requestHeader.Add('Expect','100-continue');
            }
            #Perform query
            Try{
                switch ($Method) {
                    'GET'
                    {
                        $p = @{
                            Url = $final_uri;
                            Headers = $requestHeader;
                            Method = $Method;
                            ContentType = $ContentType;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $Objects = Invoke-MonkeyWebRequest @p
                    }
                    'POST'
                    {
                        If($Data){
                            $p = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                ContentType = $ContentType;
                                Data = $Data;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
                            }
                        }
                        Else{
                            $p = @{
                                Url = $final_uri;
                                Headers = $requestHeader;
                                Method = $Method;
                                ContentType = $ContentType;
                                UserAgent = $O365Object.UserAgent;
                                Verbose = $O365Object.verbose;
                                Debug = $O365Object.debug;
                                InformationAction = $O365Object.InformationAction;
                            }
                        }
                        #Execute Query request
                        $Objects = Invoke-MonkeyWebRequest @p
                    }
                }
                If($null -ne $Objects){
                    If($null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                        #Count objects
                        $countObjects += @($Objects.value).Count
                        $Objects.value
                    }
                    ElseIf($null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                        #empty response
                        $Objects.value
                    }
                    Else{
                        #Count objects
                        $countObjects += @($Objects).Count
                        $Objects
                    }
                }
                If($Top -and $Top -ge $countObjects){
                    return
                }
                #Search for nextLink paging objects
                If ($Objects.PsObject.Properties.Item('@odata.nextLink')){
                    $nextLink = $Objects.'@odata.nextLink'
                    while ($null -ne $nextLink){
                        #Make RestAPI call
                        $p = @{
                            Url = $nextLink;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @param
                        #Count objects
                        $countObjects += @($NextPage.value).Count
                        #Return object
                        $NextPage.value;
                        #Get NextLink
                        $nextLink = $nextPage | Select-Object -ExpandProperty '@odata.nextLink' -ErrorAction Ignore
                        If($Top -and $Top -ge $countObjects){
                            $nextLink = $null
                        }
                        #Sleep between queries
                        Start-Sleep -Milliseconds 100
                    }
                }
                #Search for odata.count objects
                ElseIf ($Objects.PsObject.Properties.Item('@odata.count')){
                    $maxObjects = $Objects.'@odata.count'
                    while($maxObjects -gt $countObjects){
                        $uri = [System.Uri]$final_uri
                        $TokenizedQueryString = [System.Web.HttpUtility]::ParseQueryString($uri.Query)
                        $new_filter = $null
                        If($null -ne $TokenizedQueryString.Item('$top')){
                            $oldTop = $TokenizedQueryString.Item('$top')
                            $newTop = 4000+[int]$TokenizedQueryString.Item('$top');
                            If($newTop -gt 5000){
                                $newTop = 5000;
                            }
                            $TokenizedQueryString.Item('$top') = $newTop
                        }
                        Else{
                            $oldTop = 100;
                        }
                        If($null -ne $TokenizedQueryString.Item('$skip')){
                            $newSkip = [int]$oldTop +[int]$TokenizedQueryString.Item('$skip')
                            $TokenizedQueryString.Item('$skip') = $newSkip;
                        }
                        Else{
                            $TokenizedQueryString.Add('$skip',$oldTop)
                        }
                        foreach($key in $TokenizedQueryString.AllKeys){
                            If($null -ne $new_filter){
                                $new_filter = ('{0}&{1}={2}' -f $new_filter, $key,$TokenizedQueryString[$key])
                            }
                            Else{
                                $new_filter = ('?{0}={1}' -f $key,$TokenizedQueryString[$key])
                            }
                        }
                        #Construct new query
                        $final_uri = ('https://{0}{1}{2}' -f $uri.Authority,$uri.AbsolutePath,$new_filter)
                        #Make RestAPI call
                        $param = @{
                            Url = $final_uri;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $O365Object.verbose;
                            Debug = $O365Object.debug;
                            InformationAction = $O365Object.InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @param
                        #Count objects
                        $countObjects += @($NextPage.value).Count
                        #return object
                        $NextPage.value
                        If($Top -and $Top -ge $countObjects){
                            return
                        }
                        #Sleep between queries
                        Start-Sleep -Milliseconds 100
                    }
                }
            }
            Catch{
                Write-Verbose $_
            }
        }
    }
    End{
        #Nothing to do here
    }
}

