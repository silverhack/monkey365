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

Function Invoke-MonkeySPSDefaultUrlRequest{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeySPSDefaultUrlRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$endpoint,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$Content_Type = "text/xml",

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [string]$Data,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [System.Collections.Hashtable]$objectMetadata
    )
    Begin{
        if($null -eq $Authentication){
            Write-Warning -Message ($message.NullAuthenticationDetected -f "Sharepoint Online")
            return
        }
        #Get Authorization Header
        $AuthHeader = ("Bearer {0}" -f $Authentication.AccessToken)
        #Get Url
        if($endpoint){
            $url = ("{0}/_vti_bin/client.svc/ProcessQuery" -f $endpoint)
        }
        else{
            $endpoint = $Authentication.resource
            $url = ("{0}/_vti_bin/client.svc/ProcessQuery" -f $endpoint)
        }
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
                    Content_Type = $Content_Type;
                    Data = $Data;
                    UserAgent = $O365Object.UserAgent
                }
            }
            else{
                $param = @{
                    Url = $url;
                    Headers = $requestHeader;
                    Method = "POST";
                    Content_Type = $Content_Type;
                    UserAgent = $O365Object.UserAgent
                }
            }
            #Execute Query
            $tmp_response = Invoke-UrlRequest @param
            try{
                if($objectMetadata){
                    #Verify return data
                    if($tmp_response -is [object] -and $tmp_response.GetValue($objectMetadata.CheckValue) -eq $objectMetadata.isEqualTo `
                       -and ($tmp_response.GetValue($objectMetadata.GetValue)).GetType().Name -eq "PsCustomObject"){

                       $raw_response = $tmp_response.GetValue($objectMetadata.GetValue)
                       #check if return ChildItems
                       if($objectMetadata.keys -contains "ChildItems"){
                        $childObject = $objectMetadata.ChildItems
                        if([string]::IsNullOrEmpty($childObject)){
                            $raw_response = $raw_response
                        }
                        else{
                            $raw_response = $raw_response.$($objectMetadata.ChildItems)
                        }
                        #check if ChildItems
                        if([bool]($raw_response.PSobject.Properties.name -match "_Child_Items_")){
                            $raw_response = $raw_response._Child_Items_
                        }
                       }
                    }
                    elseif($tmp_response -is [object] -and $tmp_response.GetValue($objectMetadata.CheckValue) -eq $objectMetadata.isEqualTo `
                       -and ($tmp_response.GetValue($objectMetadata.GetValue)).GetType().Name -eq "String"){

                       $raw_response = $tmp_response.GetValue($objectMetadata.GetValue)
                    }
                }
                else{
                    #Get all properties
                    $raw_response = $tmp_response
                }
            }
            catch{
                $msg = @{
                    MessageData = ($message.UnableToProcessQuery -f $endpoint);
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'warning';
                    InformationAction = $InformationAction;
                    Tags = @('SPSRequestError');
                }
                Write-Warning @msg
                if($tmp_response -is [object]){
                    $errorData = $tmp_response[0]
                    if($null -ne $errorData){
                        $errorMessage = "[{0}][{1}]:[{2}]" -f $errorData.ErrorInfo.ErrorTypeName, $errorData.ErrorInfo.ErrorCode, $errorData.ErrorInfo.ErrorMessage
                        $msg = @{
                            MessageData = ($message.SPSDetailedErrorMessage -f $errorMessage);
                            callStack = (Get-PSCallStack | Select-Object -First 1);
                            logLevel = 'warning';
                            InformationAction = $InformationAction;
                            Tags = @('SPSRequestError');
                        }
                        Write-Verbose @msg
                    }
                }
                else{
                    Write-Debug $_
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
