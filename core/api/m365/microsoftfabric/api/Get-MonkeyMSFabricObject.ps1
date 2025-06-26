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

Function Get-MonkeyMSFabricObject{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyMSFabricObject
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

        [Parameter(Mandatory = $false, HelpMessage='Raw Query')]
        [String]$RawQuery,

        [parameter(Mandatory=$False, HelpMessage='Method')]
        [ValidateSet("CONNECT","GET","POST","HEAD","PUT")]
        [String]$Method = "GET",

        [parameter(Mandatory=$False, HelpMessage='Content Type')]
        [String]$ContentType = "application/json",

        [parameter(Mandatory=$False, HelpMessage='POST data')]
        [Object]$Data,

        [parameter(Mandatory=$False, HelpMessage='Admin path')]
        [Switch]$Admin,

        [parameter(Mandatory=$False, HelpMessage='API version')]
        [String]$APIVersion = "v1"
    )
    Begin{
        #Set null
        $AuthHeader = $my_filter = $final_uri = $null
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
                Write-Warning -Message ($message.NullAuthenticationDetected -f "Microsoft Fabric API")
                break
            }
        }
        If($RawQuery){
            $final_uri = $RawQuery
        }
        Else{
            #set Fabric uri
            $base_uri = ("/{0}" -f $APIVersion)
            IF($Admin.IsPresent){
                $base_uri = ("{0}/admin" -f $base_uri)
            }
            If($Filter){
                $my_filter = ('?{0}' -f [uri]::EscapeDataString($Filter))
            }
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
            $Server = ("{0}" -f $Environment.Fabric.Replace('https://',''))
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
                    #Check if continuation uri
                    $continuationUri = $Objects | Select-Object -ExpandProperty continuationUri -ErrorAction Ignore
                    If($null -eq $continuationUri){
                        If($null -ne $Objects.PSObject.Properties.Item('value')){
                            $Objects.value
                        }
                        Else{
                            $Objects
                        }
                    }
                    Else{
                        $firstObject = $Objects.PsObject.Properties | Select-Object -First 1
                        IF(@($firstObject.Value).Count -gt 0){
                            #Return values
                            $firstObject.Value
                            #Iterate until continuationUri returns null
                            while ($null -ne $continuationUri){
                                #Make RestAPI call
                                $p = @{
                                    Url = $continuationUri;
                                    Method = "Get";
                                    Headers = $requestHeader;
                                    UserAgent = $O365Object.UserAgent;
                                    Verbose = $O365Object.verbose;
                                    Debug = $O365Object.debug;
                                    InformationAction = $O365Object.InformationAction;
                                }
                                $Objects = Invoke-MonkeyWebRequest @p
                                If($null -ne $Objects){
                                    $Objects.PsObject.Properties | Select-Object -First 1 | Select-Object -ExpandProperty Value -ErrorAction Ignore
                                }
                                $continuationUri = $Objects | Select-Object -ExpandProperty continuationUri -ErrorAction Ignore
                                #Sleep to avoid throttling
                                Start-Sleep -Milliseconds 500
                            }
                        }
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