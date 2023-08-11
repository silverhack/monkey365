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

Function Invoke-MonkeyCSOMDefaultRequest{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeyCSOMDefaultRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$Endpoint,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$ContentType = "text/xml",

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [string]$Data,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [System.Collections.Hashtable]$ObjectMetadata
    )
    Begin{
        #set null
        $raw_response = $null
        #Set False
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
            Write-Warning -Message ($message.NullAuthenticationDetected -f "Sharepoint Online")
            break
        }
        #Get Authorization Header
        $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        #Set Endpoint
        if($Endpoint){
            $Server = [System.Uri]::new($Endpoint)
        }
        else{
            $Server = [System.Uri]::new($Authentication.resource)
        }
        #Set site path
        if($Server.Segments.Contains('sites/')){
            $sitePath = ("{0}/_vti_bin/client.svc/ProcessQuery" -f $Server.AbsolutePath)
            #Remove double slashes
            $sitePath = [regex]::Replace($sitePath,"/+","/")
        }
        else{
            $sitePath = ("/_vti_bin/client.svc/ProcessQuery")
        }
        #Get Url
        $url = [System.Uri]::new($Server,$sitePath)
        $url = $url.ToString()
        #Construct Request Header
        $requestHeader = @{"Authorization" = $AuthHeader}
    }
    Process{
        if($null -ne $url){
            #Get Data
            if($Data){
                $param = @{
                    Url = $url;
                    Headers = $requestHeader;
                    Method = "POST";
                    ContentType = $ContentType;
                    Data = $Data;
                    UserAgent = $O365Object.UserAgent;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
            }
            else{
                $param = @{
                    Url = $url;
                    Headers = $requestHeader;
                    Method = "POST";
                    ContentType = $ContentType;
                    UserAgent = $O365Object.UserAgent;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
            }
            #Execute Query
            $tmp_response = Invoke-MonkeyWebRequest @param
            try{
                if($ObjectMetadata){
                    #Verify return data
                    if($tmp_response -is [object] -and $tmp_response.GetValue($ObjectMetadata.CheckValue) -eq $ObjectMetadata.isEqualTo `
                       -and ($tmp_response.GetValue($ObjectMetadata.GetValue)).GetType().Name -eq "PsCustomObject"){

                       $raw_response = $tmp_response.GetValue($ObjectMetadata.GetValue)
                       #check if return ChildItems
                       if($ObjectMetadata.keys -contains "ChildItems"){
                        $childObject = $ObjectMetadata.ChildItems
                        if([string]::IsNullOrEmpty($childObject)){
                            $raw_response = $raw_response
                        }
                        else{
                            $raw_response = $raw_response.$($ObjectMetadata.ChildItems)
                        }
                        #check if ChildItems
                        if([bool]($raw_response.PSobject.Properties.name -match "_Child_Items_")){
                            $raw_response = $raw_response._Child_Items_
                        }
                       }
                    }
                    elseif($tmp_response -is [object] -and $tmp_response.GetValue($ObjectMetadata.CheckValue) -eq $ObjectMetadata.isEqualTo `
                       -and ($tmp_response.GetValue($ObjectMetadata.GetValue)).GetType().Name -eq "String"){

                       $raw_response = $tmp_response.GetValue($ObjectMetadata.GetValue)
                    }
                }
                else{
                    #Get all properties
                    $raw_response = $tmp_response
                }
            }
            catch{
                $msg = @{
                    MessageData = ($message.UnableToProcessQuery -f $Endpoint);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('SPSRequestError');
                }
                Write-Warning @msg
                $msg = @{
                    MessageData = ($_);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'verbose';
                    Verbose = $Verbose;
                    Tags = @('SPSRequestError');
                }
                Write-Verbose @msg
                if($tmp_response -is [object]){
                    $errorData = $tmp_response[0]
                    if($null -ne $errorData -and $null -ne $errorData.psobject.properties.Item('ErrorInfo') -and $null -ne $errorData.ErrorInfo){
                        $errorMessage = "{0} in {1}. {2} {3}" -f $errorData.ErrorInfo.ErrorTypeName, $Server.AbsoluteUri, $errorData.ErrorInfo.ErrorCode, $errorData.ErrorInfo.ErrorMessage
                        $msg = @{
                            MessageData = ($message.SPSDetailedErrorMessage -f $errorMessage);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'verbose';
                            InformationAction = $InformationAction;
                            Verbose = $O365Object.verbose;
                            Tags = @('CSOMRequestError');
                        }
                        Write-Verbose @msg
                    }
                }
            }
        }
    }
    End{
        if($raw_response){
            return $raw_response
        }
    }
}
