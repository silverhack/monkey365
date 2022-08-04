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

Function Invoke-MonkeySPSUrlRequest{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Invoke-MonkeySPSUrlRequest
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Object]$Authentication,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$endpoint,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [String]$Content_Type = "text/xml",

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [xml]$Data,

        [parameter(ValueFromPipeline = $True, ValueFromPipeLineByPropertyName = $True)]
        [Switch]$childItems
    )
    Begin{
        if($null -eq $Authentication){
            Write-Warning -Message ($message.NullAuthenticationDetected -f "SharePoint Online")
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
            $url = ("{0}/_vti_bin/client.svc/ProcessQuery" -f $Authentication.resource)
        }
        #Construct Request Header
        $requestHeader = @{"Authorization" = $AuthHeader}
        #Set new IDs
        $objectId = Get-Random -Minimum 20000 -Maximum 50000
        $objectPathID = Get-Random -Minimum 20000 -Maximum 50000
        $nestedObjectId = $objectId
        $nestedObjectPathId = $objectPathID
        foreach ($elem in $Data.Request.Actions.GetEnumerator()){
            if($elem.Name -eq 'ObjectPath'){
                #Set Ids
                $elem.id = $nestedObjectId.ToString()
                $elem.ObjectPathId = $nestedObjectPathId.ToString()
                #Increment ObjectId
                $nestedObjectId+=1
                $nestedObjectPathId += 1
            }
            if($elem.Name -eq 'Query'){
                if($elem.ParentNode.FirstChild.Name -eq 'ObjectPath'){
                    #Set Ids
                    $elem.id = $nestedObjectId.ToString()
                    $elem.ObjectPathId = ($nestedObjectPathId-1).ToString()
                    #Increment ObjectId
                    $nestedObjectId+=1
                }
                else{
                    #Set Ids
                    $elem.id = $nestedObjectId.ToString()
                    $elem.ObjectPathId = ($nestedObjectPathId).ToString()
                    #Increment ObjectId
                    $nestedObjectId+=1
                    $nestedObjectPathId += 1
                }
            }
        }
        #Set method
        if($Data.Request.ObjectPaths.Method.Id){
            $Data.Request.ObjectPaths.Method.Id = $objectPathID.ToString()
        }
        #Set Identity
        foreach($elem in $Data.Request.ObjectPaths.GetEnumerator()){
            if($elem.Id){
                #Set Ids
                $elem.id = $objectPathID.ToString()
            }
            if($elem.ParentId){
                $elem.ParentId = ($objectPathID -1).ToString()
            }
            #Increment ObjectId
            $objectPathID+=1
        }
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
                    Data = $Data.OuterXml.ToString();
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
                if($null -eq $tmp_response.Length){
                    if($tmp_response -is [object]){
                        $errorData = $tmp_response[0]
                        if($null -ne $errorData -and $null -ne $errorData.psobject.properties.Item('ErrorInfo')){
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
                }
                else{
                    for($i=1;$i -le $tmp_response.Length;$i++){
                        if($tmp_response[$i] -is [psobject]){
                            #Get object
                            $raw_response = $tmp_response[$i]
                            #check if childItems
                            if($childItems){
                                if($null -ne $raw_response.PSObject.Properties.Item('_Child_Items_')){
                                    $raw_response = $raw_response._Child_Items_
                                }
                            }
                        }
                        elseif($tmp_response[$i] -is [string]){
                            #Get object
                            $raw_response = $tmp_response[$i]
                        }
                    }
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
