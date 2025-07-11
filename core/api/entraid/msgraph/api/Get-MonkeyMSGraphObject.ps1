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

Function Get-MonkeyMSGraphObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSGraphObject
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

        [parameter(Mandatory=$False, HelpMessage='Filter')]
        [String]$Filter,

        [parameter(Mandatory=$False, HelpMessage='Expand')]
        [String]$Expand,

        [parameter(Mandatory=$False, HelpMessage='Top objects')]
        [String]$Top,

        [parameter(Mandatory=$False, HelpMessage='Order by')]
        [String]$orderBy,

        [parameter(Mandatory=$False, HelpMessage='Select objects')]
        [String[]]$Select,

        [parameter(Mandatory=$False, HelpMessage='Count objects')]
        [Switch]$Count,

        [parameter(Mandatory=$False, HelpMessage='Me')]
        [Switch]$me,

        [parameter(Mandatory=$False, HelpMessage='Add consistency level header')]
        [Switch]$AddConsistencyLevelHeader,

        [parameter(Mandatory=$False, HelpMessage='RAW Query')]
        [String]$RawQuery,

        [parameter(Mandatory=$False, HelpMessage='Method')]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(Mandatory=$False, HelpMessage='Content type')]
        [String]$ContentType = "application/json",

        [parameter(Mandatory=$False, HelpMessage='POST Data object')]
        [Object]$Data,

        [parameter(Mandatory=$False, HelpMessage='Return raw response')]
        [Switch]$RawResponse,

        [parameter(Mandatory=$False, HelpMessage='API Version')]
        [String]$APIVersion = "v1.0"
    )
    Begin{
        $Verbose = $Debug = $False;
        $InformationAction = 'SilentlyContinue'
        If($PSBoundParameters.ContainsKey('Verbose') -and $PSBoundParameters.Verbose){
            $Verbose = $True
        }
        If($PSBoundParameters.ContainsKey('Debug') -and $PSBoundParameters.Debug){
            $Debug = $True
        }
        If($PSBoundParameters.ContainsKey('InformationAction')){
            $InformationAction = $PSBoundParameters['InformationAction']
        }
        If($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft Graph API")
             break
        }
        #Get Authorization Header
        $methods = $Authentication | Get-Member | Where-Object {$_.MemberType -eq 'Method'} | Select-Object -ExpandProperty Name
        #Get Authorization Header
        If($null -ne $methods -and $methods.Contains('CreateAuthorizationHeader')){
            $AuthHeader = $Authentication.CreateAuthorizationHeader()
        }
        Else{
            $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        }
        #$AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        #set msgraph uri
        $base_uri = ("/{0}" -f $APIVersion)
        $my_filter = $null
        #construct query
        If($Expand){
            If($null -ne $my_filter){
                $my_filter = ('{0}&$expand={1}' -f $my_filter, $Expand)
            }
            Else{
                $my_filter = ('?$expand={0}' -f $Expand)
            }
        }
        If($Filter){
            If($null -ne $my_filter){
                $my_filter = ('{0}&$filter={1}' -f $my_filter, [uri]::EscapeDataString($Filter))
            }
            Else{
                $my_filter = ('?$filter={0}' -f [uri]::EscapeDataString($Filter))
            }
        }
        If($Select){
            If($null -ne $my_filter){
                $my_filter = ('{0}&$select={1}' -f $my_filter, (@($Select) -join ','))
            }
            Else{
                $my_filter = ('?$select={0}' -f (@($Select) -join ','))
            }
        }
        If($orderBy){
            If($null -ne $my_filter){
                $my_filter = ('{0}&$orderby={1}' -f $my_filter, $orderBy)
            }
            Else{
                $my_filter = ('?$orderby={0}' -f $orderBy)
            }
        }
        If($Top){
            If($null -ne $my_filter){
                $my_filter = ('{0}&$top={1}' -f $my_filter, $Top)
            }
            Else{
                $my_filter = ('?$top={0}' -f $Top)
            }
        }
        If($Count){
            If($null -ne $my_filter){
                $my_filter = ('{0}&$count=true' -f $my_filter)
            }
            Else{
                $my_filter = ('?$count=true' -f $Top)
            }
        }
        If($me){
            $base_uri = ("{0}/me" -f $base_uri)
        }
        If($ObjectType){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectType)
        }
        If($ObjectId){
            $base_uri = ("{0}/{1}" -f $base_uri, $ObjectId)
        }
        #Append filter to query
        If($my_filter){
            $base_uri = ("{0}{1}" -f $base_uri,$my_filter)
        }
        #Construct final URI
        $Server = ("{0}" -f $Environment.Graphv2.Replace('https://',''))
        $final_uri = ("{0}{1}" -f $Server,$base_uri)
        $final_uri = [regex]::Replace($final_uri,"/+","/")
        $final_uri = ("https://{0}" -f $final_uri.ToString())
        If($RawQuery){
            If($my_filter){
                $final_uri = ("{0}{1}" -f $RawQuery,$my_filter)
            }
            Else{
                $final_uri = ("{0}" -f $RawQuery)
            }
        }
    }
    Process{
        If($final_uri){
            #Create Request Header
            $requestHeader = @{
                Authorization = $AuthHeader
            }
            If($PSBoundParameters.ContainsKey('AddConsistencyLevelHeader') -and $PSBoundParameters['AddConsistencyLevelHeader'].IsPresent){
                [void]$requestHeader.Add('ConsistencyLevel','eventual')
            }
            #set count
            $countObjects = 0;
            #Perform query
            try{
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
                        If($PSBoundParameters.ContainsKey('RawResponse') -and $PSBoundParameters['RawResponse'].IsPresent){
                            [void]$param.Add('RawResponse',$true)
                        }
                        #Execute query
                        $Objects = Invoke-MonkeyWebRequest @param
                    }
                    'POST'
                    {
                        If($Data){
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
                        Else{
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
                        #Execute Query request
                        $Objects = Invoke-MonkeyWebRequest @param
                    }
                }
                #Writes URL to verbose stream
                Write-Verbose $final_uri
                #Check objects
                If($null -ne $Objects -and $Objects -is [System.Net.Http.HttpResponseMessage]){
                    $Objects
                    return
                }
                ElseIf($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and @($Objects.value).Count -gt 0){
                    #Count objects
                    $countObjects += @($Objects.value).Count
                    #return Value
                    $Objects.value
                }
                ElseIf($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                    #empty response
                    $Objects.value
                }
                Else{
                    #Count objects
                    $countObjects += @($Objects).Count
                    $Objects
                }
                If($Top -and $Top -ge $countObjects){
                    return
                }
                #Search for paging objects
                If ($Objects.PsObject.Properties.Item('@odata.nextLink')){
                    $nextLink = $Objects.'@odata.nextLink'
                    while ($null -ne $nextLink){
                        #Make RestAPI call
                        $p = @{
                            Url = $nextLink;
                            Method = "Get";
                            Headers = $requestHeader;
                            UserAgent = $O365Object.UserAgent;
                            Verbose = $Verbose;
                            Debug = $Debug;
                            InformationAction = $InformationAction;
                        }
                        $NextPage = Invoke-MonkeyWebRequest @p
                        $nextLink = $NextPage | Select-Object -ExpandProperty '@odata.nextLink' -ErrorAction Ignore
                        $NextPage.value
                        #Sleep to avoid throttling
                        Start-Sleep -Milliseconds 500
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

