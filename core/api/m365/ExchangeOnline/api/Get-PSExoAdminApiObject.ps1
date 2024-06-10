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
        [parameter(ValueFromPipeline = $True,HelpMessage="Authentication Object")]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True,HelpMessage="Endpoint")]
        [String]$EndPoint,

        [parameter(ValueFromPipeline = $True,HelpMessage="Environment")]
        [Object]$Environment,

        [parameter(Mandatory=$False, HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers,

        [parameter(ValueFromPipeline = $True,HelpMessage="EXO command to execute")]
        [String]$Command,

        [parameter(ValueFromPipeline = $True,HelpMessage="Timeout")]
        [int32]$TimeOut = 120,

        [parameter(ValueFromPipeline = $True,HelpMessage="Response format")]
        [ValidateSet("clixml","json")]
        [String]$ResponseFormat = 'clixml',

        [parameter(ValueFromPipeline = $True,HelpMessage="ObjectType")]
        [String]$ObjectType,

        [parameter(ValueFromPipeline = $True,HelpMessage="Extra parameters")]
        [String]$ExtraParameters,

        [parameter(ValueFromPipeline = $True,HelpMessage="Own Query")]
        [String]$OwnQuery,

        [parameter(ValueFromPipeline = $True,HelpMessage="Method")]
        [ValidateSet("GET","POST")]
        [String]$Method = "GET",

        [parameter(ValueFromPipeline = $True,HelpMessage="ContentType")]
        [String]$ContentType = "application/json;odata.metadata=minimal",

        [parameter(ValueFromPipeline = $True,HelpMessage="Post Data")]
        [Object]$Data,

        [Parameter(Mandatory=$false, HelpMessage="Remove odata header")]
        [Switch]$RemoveOdataHeader,

        [parameter(Mandatory=$false, HelpMessage="API version")]
        [ValidateSet("v1.0","beta")]
        [String]$APIVersion = "beta"
    )
    Begin{
        $URI = [String]::Empty
        $SessionID = (New-Guid).ToString().Replace("-","")
        $extra_params = $Data = $null
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
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Exchange Online API")
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
    }
    Process{
        #Set URI
        if($extraParameters){
            $extra_params = ('?{0}' -f $extraParameters)
        }
        if($ObjectType){
            #Construct URI
            $URI = 'adminapi/{0}/{1}/{2}' -f $APIVersion, $Authentication.TenantId, $ObjectType
        }
        ElseIf($Command){
            #Construct URI
            $URI = 'adminapi/{0}/{1}/InvokeCommand' -f $APIVersion, $Authentication.TenantId
        }
        if($extra_params){
            $URI = ("{0}{1}" -f $URI,$extra_params)
        }
        if($OwnQuery){
            $URI = $OwnQuery
        }
        elseif($EndPoint){
            $Server = ("{0}" -f $EndPoint.Replace('https://',''))
            $URI = ("{0}/{1}" -f $Server,$URI)
            $URI = [regex]::Replace($URI,"/+","/")
            $URI = ("https://{0}" -f $URI.ToString())
        }
        elseif($Environment){
            $Server = ("{0}" -f $Environment.Outlook.Replace('https://',''))
            $URI = ("{0}/{1}" -f $Server,$URI)
            $URI = [regex]::Replace($URI,"/+","/")
            $URI = ("https://{0}" -f $URI.ToString())
        }
        else{
            break
        }
    }
    End{
        if($URI -and $AuthHeader){
            #Set headers
            $requestHeader = @{
                "client-request-id" = $SessionID
                "Prefer" = 'odata.maxpagesize=1000;'
                "Authorization" = $AuthHeader
            }
            if($PSBoundParameters.ContainsKey('RemoveOdataHeader') -and $PSBoundParameters.RemoveOdataHeader.IsPresent){
                #Remove Prefer header
                [void]$requestHeader.Remove('Prefer')
            }
            if($PSBoundParameters.ContainsKey('Headers') -and $PSBoundParameters['Headers']){
                #Add extra header
                foreach($header in $PSBoundParameters['Headers'].GetEnumerator()){
                    if(!$requestHeader.ContainsKey($header.Key)){
                        [void]$requestHeader.Add($header.Key,$header.Value)
                    }
                }
            }
            if($Command){
                #Add response format
                [void]$requestHeader.Add('X-ResponseFormat',$ResponseFormat);
                #Add serialization level
                [void]$requestHeader.Add('X-SerializationLevel','Full');
                #Convert command
                $Data = ConvertTo-ExoRestCommand -Command $Command
                #Support for warning/Error action
                if($Data){
                    $jsonData = $Data | ConvertFrom-Json
                    if($jsonData.CmdletInput.Parameters){
                        #Get WarningAction
                        $wa = $jsonData.CmdletInput.Parameters | Select-Object -ExpandProperty WarningAction -ErrorAction Ignore
                        if($wa){
                            #Add Warning action header
                            [void]$requestHeader.Add('WarningAction',$wa);
                        }
                        #Get ErrorAction
                        $ea = $jsonData.CmdletInput.Parameters | Select-Object -ExpandProperty ErrorAction -ErrorAction Ignore
                        if($ea){
                            #Add ErrorAction header
                            [void]$requestHeader.Add('ErrorAction',$ea);
                        }
                    }
                }
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
                                TimeOut = $TimeOut;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                            $Objects = Invoke-MonkeyWebRequest @param
                        }
                        'POST'
                        {
                            if($Data){
                                $param = @{
                                    Url = $URI;
                                    Headers = $requestHeader;
                                    Method = $Method;
                                    ContentType = $ContentType;
                                    Data = $Data;
                                    UserAgent = $O365Object.UserAgent;
                                    TimeOut = $TimeOut;
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
                                    TimeOut = $TimeOut;
                                    Verbose = $Verbose;
                                    Debug = $Debug;
                                    InformationAction = $InformationAction;
                                }
                            }
                            #Launch request
                            $Objects = Invoke-MonkeyWebRequest @param
                        }
                }
                if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                    if(($PSBoundParameters.ContainsKey('ResponseFormat') -and $PSBoundParameters['ResponseFormat'] -eq 'clixml') -and $PSBoundParameters.ContainsKey('Command')){
                        $value = $Objects.value | Select-Object -ExpandProperty _clixml -ErrorAction Ignore
                        if($null -ne $value){
                             If($null -ne (Get-Command -Name "Import-MonkeyCliXml" -ErrorAction Ignore)){
                                Import-MonkeyCliXml -RawData $value
                             }
                             else{
                                Write-Warning -Message "Command Import-MonkeyCliXml not found"
                             }
                        }
                    }
                    else{
                        $Objects.value
                    }
                }
                elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                    #empty response
                    $Objects.value
                }
                elseIf($Objects -is [System.Array]){
                    $Objects
                }
                Else{
                    $Objects
                }
                #Get potential warnings
                if($null -ne $Objects -and $null -ne $Objects.PsObject.Properties.Item('@adminapi.warnings')){
                    $warningData = $Objects.'@adminapi.warnings'
                    if(@($warningData).Count -gt 0){
                        foreach($elem in @($warningData)){
                            Write-Warning $elem
                        }
                    }
                }
                if ($Objects.PsObject.Properties.Item('@odata.nextLink')){
                    $NextLink = $Objects.'@odata.nextLink'
                    #Search for paging objects
                    while($null -ne $NextLink){
                        if($Data){
                            $param = @{
                                Url = $NextLink;
                                Headers = $requestHeader;
                                Method = $Method;
                                ContentType = $ContentType;
                                Data = $Data;
                                UserAgent = $O365Object.UserAgent;
                                TimeOut = $TimeOut;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                        }
                        else{
                            $param = @{
                                Url = $NextLink;
                                Headers = $requestHeader;
                                Method = $Method;
                                ContentType = $ContentType;
                                UserAgent = $O365Object.UserAgent;
                                TimeOut = $TimeOut;
                                Verbose = $Verbose;
                                Debug = $Debug;
                                InformationAction = $InformationAction;
                            }
                        }
                        $Objects = Invoke-MonkeyWebRequest @param
                        #Get potential warnings
                        if($null -ne $Objects -and $null -ne $Objects.PsObject.Properties.Item('@adminapi.warnings')){
                            $warningData = $Objects.'@adminapi.warnings'
                            if(@($warningData).Count -gt 0){
                                foreach($elem in @($warningData)){
                                    Write-Warning $elem
                                }
                            }
                        }
                        #Get results
                        if($null -ne $Objects){
                            $NextLink = $Objects | Select-Object -ExpandProperty '@odata.nextLink' -ErrorAction Ignore
                            if($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -gt 0){
                                if(($PSBoundParameters.ContainsKey('ResponseFormat') -and $PSBoundParameters['ResponseFormat'] -eq 'clixml') -and $PSBoundParameters.ContainsKey('Command')){
                                    $value = $Objects.value | Select-Object -ExpandProperty _clixml -ErrorAction Ignore
                                    if($null -ne $value){
                                         If($null -ne (Get-Command -Name "Import-MonkeyCliXml" -ErrorAction Ignore)){
                                            Import-MonkeyCliXml -RawData $value
                                         }
                                         else{
                                            Write-Warning -Message "Command Import-MonkeyCliXml not found"
                                         }
                                    }
                                }
                                else{
                                    $Objects.value
                                }
                            }
                            elseif($null -ne $Objects -and $null -ne $Objects.PSObject.Properties.Item('value') -and $Objects.value.Count -eq 0){
                                #empty response
                                $Objects.value
                            }
                            elseIf($Objects -is [System.Array]){
                                $Objects
                            }
                            Else{
                                $Objects
                            }
                        }
                        Else{
                            $NextLink = $null
                        }
                    }
                }
            }
            catch {
                Write-Verbose $_
            }
        }
    }
}
