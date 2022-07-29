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


Function Get-SASUri{
    <#
        .SYNOPSIS
		Get SAS Uri

        .DESCRIPTION
		Get SAS Uri

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-SASUri
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseOutputTypeCorrectly", "", Scope="Function")]
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$HostName, #test.blob.core.windows.net

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$restype = 'service',

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$comp = 'properties',

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$accessKey,

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$signedPermission="rwdlacup", #all

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$signedVersion="2020-08-04",

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$signedServices ="bqtf", #Blob, File, Queue, Table

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$signedResourceTypes = "sco", #Service, container, object

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$signedIP = "0.0.0.0-255.255.255.255", #Any

        [parameter(ValueFromPipeline = $True,ValueFromPipeLineByPropertyName = $True)]
        [String]$signedProtocol = "https"
    )
    Begin{
        $sasUri = $null
        if(-NOT $HostName){
            $msg = @{
                MessageData = "Empty hostname";
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'warning';
                InformationAction = $InformationAction;
                Tags = @('AzureSASUriEmptyHostname');
            }
            Write-Warning @msg
            return $false
        }
        else{
            [uri]$URL = $HostName
            $accountName = $URL.Host.Split('.')[0]
            $msg = @{
                MessageData = ($message.SharedAccessUri -f $HostName);
                callStack = (Get-PSCallStack | Select-Object -First 1);
                logLevel = 'debug';
                InformationAction = $InformationAction;
                Tags = @('AzureSASUriHostname');
            }
            Write-Debug @msg
        }
    }
    Process{
        #Get start and expiry dates
        $start = [datetime]::UtcNow.AddMinutes(-1).ToString("yyyy-MM-ddTHH:mm:ssZ") # (now)
        $expiry = [DateTime]::UtcNow.AddHours(1).ToString("yyyy-MM-ddTHH:mm:ssZ") #1 hour
        #End Datetime
        $signatureString = ("{0}`n{1}`n{2}`n{3}`n{4}`n{5}`n{6}`n{7}`n{8}`n" -f $accountName,`
                                                                                $signedPermission,`
                                                                                $signedServices,`
                                                                                $signedResourceTypes, `
                                                                                $start, `
                                                                                $expiry, `
                                                                                $signedIP, `
                                                                                $signedProtocol,`
                                                                                $signedVersion)

        #Get signature
        $encodedSignatureString = [text.encoding]::UTF8.GetBytes($signatureString)
        $hmacsha = New-Object System.Security.Cryptography.HMACSHA256
        $hmacsha.key = [Convert]::FromBase64String($accessKey)
        $signature = $hmacsha.ComputeHash($encodedSignatureString)

        $signature = [Convert]::ToBase64String($signature)
        $signature = [uri]::EscapeDataString($signature)
        #Get ACL
        #comp=acl&restype=container
        #Construct URL
        $sasUri = $URL.AbsoluteUri `
                    + '?restype=' + $restype `
                    + '&comp=' + $comp `
                    + '&sv=' + $signedVersion `
                    + '&ss=' + $signedServices `
                    + '&srt=' + $signedResourceTypes `
                    + '&sp=' + $signedPermission `
                    + '&st=' + $start `
                    + '&se=' + $expiry `
                    + '&sip=' + $signedIP `
                    + '&spr=' + $signedProtocol `
                    + '&sig=' + $signature
    }
    End{
        $sasUri
    }
}
