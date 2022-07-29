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

Function Get-LegacyO365Object{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-LegacyO365Object
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
        [String]$ContentType = "application/soap+xml; charset=utf-8",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [System.xml.XmlDocument]$Envelope
    )
    Begin{
        if($null -eq $Authentication){
             Write-Warning -Message ($message.NullAuthenticationDetected -f "Legacy Office 365 API")
             return
        }
        #Get Bearer token from Active Directory
        $auth_header = $Authentication.CreateAuthorizationHeader()
        #Get Legacy url
        $final_uri = $Environment.LegacyO365API
        #XPath on the file
        $namespace = $Envelope.DocumentElement.NamespaceURI
        $ns = New-Object System.Xml.XmlNamespaceManager($Envelope.NameTable)
        $ns.AddNamespace("s", $namespace)
        #Create GUID
        $client_uuid = [System.Guid]::NewGuid().Guid
        $tracking_uuid = [System.Guid]::NewGuid().Guid
        $message_uuid = [System.Guid]::NewGuid().Guid
        #Get header and set envelope values
        $header = $Envelope.SelectSingleNode('//s:Header',$ns)
        #Set bearer token
        $header.UserIdentityHeader.BearerToken.InnerText = $auth_header.ToString()
        #Set client uuid
        $header.ClientVersionHeader.ClientId.InnerText = $client_uuid.ToString()
        #Set message uuid
        $header.MessageID = ("urn:uuid:{0}" -f $message_uuid.ToString())
        #Set tracking uuid
        $header.TrackingHeader.InnerText = $tracking_uuid
        #Set null
        $Objects = $null

    }
    Process{
        #Perform query
        $ServicePoint = [System.Net.ServicePointManager]::FindServicePoint($final_uri)
        $ServicePoint.ConnectionLimit = 1000;
        try{
            $param = @{
                Url = $final_uri;
                Method = "POST";
                Content_Type = $ContentType;
                Data = $Envelope.OuterXml;
                UserAgent = $O365Object.UserAgent
            }
            [xml]$Objects = Invoke-UrlRequest @param
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
        if($null -ne $Objects){
            if($Objects.Envelope.Body.Fault){
                $errorText = $Objects.Envelope.Body.Fault.Detail.InternalServiceException.Message
                if($errorText){
                    $msg = @{
                        MessageData = $errorText;
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'warning';
                        InformationAction = $InformationAction;
                        Tags = @('LegacyAPIQueryError');
                    }
                    Write-Warning @msg
                }
            }
            else{
                return $Objects
            }
        }
    }
}
