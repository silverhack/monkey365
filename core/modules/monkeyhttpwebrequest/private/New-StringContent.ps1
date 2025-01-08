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

Function New-StringContent{
    <#
        .SYNOPSIS
        Create a new string content

        .DESCRIPTION
        Create a new HTTP client

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-StringContent
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Net.Http.StringContent])]
    Param (
        [parameter(Mandatory=$False, HelpMessage='POST PUT data')]
        [String]$Data,

        [parameter(Mandatory=$False, HelpMessage='Content Type')]
        [String]$ContentType,

        [parameter(Mandatory=$False, HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers
    )
    Begin{
        $Verbose = $False;
        $Debug = $False;
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
    }
    Process{
        #Set body
        if($PSBoundParameters.ContainsKey('Data')){
            $body = [System.Net.Http.StringContent]::new($Data,[System.Text.Encoding]::UTF8)
        }
        else{
            $body = [System.Net.Http.StringContent]::new('',[System.Text.Encoding]::UTF8)
        }
        #Add content type
        if($PSBoundParameters.ContainsKey('ContentType') -and $PSBoundParameters['ContentType']){
            try{
                [System.Net.Http.Headers.MediaTypeHeaderValue]$mediaType = $null
                if([System.Net.Http.Headers.MediaTypeHeaderValue]::TryParse($ContentType.ToString(),[ref]$mediaType)){
                    $body.Headers.ContentType = $mediaType
                }
                else{
                    Write-Verbose ("ContentType {0} not supported. Adding without validation" -f $ContentType)
                    [void]$body.Headers.TryAddWithoutValidation('ContentType',$ContentType)
                }
            }
            catch{
                Write-Error $_
                $param = @{
                    Message = $_.Exception;
                    Verbose = $Verbose;
                    Debug = $Debug;
                    InformationAction = $InformationAction;
                }
                Write-Verbose @param
            }
        }
        #Add headers
        if($PSBoundParameters.ContainsKey('Headers')){
            foreach($header in $PSBoundParameters['Headers'].GetEnumerator()){
                try{
                    if($null -ne $body.Headers.PsObject.Properties.Item($header.Key)){
                        if($body.Headers.($header.key) -is [System.Collections.IEnumerable]){
                            if($header.Value -is [System.Collections.IEnumerable]){
                                foreach($elem in $header.Value){
                                    [void]$body.Headers.Add($header.Key,$elem)
                                }
                            }
                            else{
                                [void]$body.Headers.Add($header.Key,$header.Value)
                            }
                        }
                        else{
                            Switch ($header.Key.ToLower()){
                                'contenttype'
                                {
                                    [System.Net.Http.Headers.MediaTypeHeaderValue]$mediaType = $null
                                    if([System.Net.Http.Headers.MediaTypeHeaderValue]::TryParse($header.Value,[ref]$mediaType)){
                                        $body.Headers.ContentType = $mediaType
                                    }
                                    else{
                                        Write-Verbose ("ContentType {0} not supported" -f $header.Value)
                                    }
                                }
                                'contentlength'
                                {
                                    [long]$contentLength = $null
                                    if([long]::TryParse($header.Value, [ref]$contentLength)){
                                        $body.Headers.ContentLength = $contentLength
                                    }
                                    else{
                                        Write-Verbose ("ContentLength {0} not supported" -f $header.Value)
                                    }
                                }
                                'contentdisposition'
                                {
                                    $body.Headers.ContentDisposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new($header.Value.ToString())
                                }
                                Default
                                {
                                    [void]$body.Headers.Add($header.Key,$header.Value)
                                }
                            }
                        }
                    }
                    else{
                        Switch ($header.Key.ToLower()){
                            'content-type'
                            {
                                [System.Net.Http.Headers.MediaTypeHeaderValue]$mediaType = $null
                                if([System.Net.Http.Headers.MediaTypeHeaderValue]::TryParse($header.Value,[ref]$mediaType)){
                                    $body.Headers.ContentType = $mediaType
                                }
                            }
                            'content-length'
                            {
                                [long]$contentLength = $null
                                if([long]::TryParse($header.Value, [ref]$contentLength)){
                                    $body.Headers.ContentLength = $contentLength
                                }
                            }
                            'content-disposition'
                            {
                                $body.Headers.ContentDisposition = [System.Net.Http.Headers.ContentDispositionHeaderValue]::new($header.Value.ToString())
                            }
                        }
                    }
                }
                catch{
                    Write-Error $_
                    $param = @{
                        Message = $_.Exception;
                        Verbose = $Verbose;
                        Debug = $Debug;
                        InformationAction = $InformationAction;
                    }
                    Write-Verbose @param
                }
            }
        }

    }
    End{
        return $body
    }
}
