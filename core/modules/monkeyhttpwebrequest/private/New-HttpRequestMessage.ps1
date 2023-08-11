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

Function New-HttpRequestMessage{
    <#
        .SYNOPSIS
        Create a new HTTP request message

        .DESCRIPTION
        Create a new HTTP request message

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: New-HttpRequestMessage
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Net.Http.HttpRequestMessage])]
    Param (
        [Parameter(Mandatory=$True, ValueFromPipeline=$true, position=0,ParameterSetName='Url')]
        [System.Uri]$Url,

        [parameter(Mandatory=$False, HelpMessage='Request method')]
        [ValidateSet("GET","POST","PUT","HEAD")]
        [String]$Method = "GET",

        [parameter(Mandatory=$False, HelpMessage='Headers as hashtable')]
        [System.Collections.Hashtable]$Headers,

        [parameter(Mandatory=$False, HelpMessage='Referer')]
        [String]$Referer
    )
    Begin{
        $_method = Get-HttpMethod -Method $Method
        #New request message
        $request = [System.Net.Http.HttpRequestMessage]::new($_method,$Url);
    }
    Process{
        $UncommonHeaders = @{}
        try{
            #Add headers
            if($PSBoundParameters.ContainsKey('Headers')){
                foreach($header in $PSBoundParameters['Headers'].GetEnumerator()){
                    try{
                        if($null -ne $request.Headers.PsObject.Properties.Item($header.Key) -and $null -ne $header.Value){
                            [void]$request.Headers.Add($header.Key,$header.Value)
                        }
                        else{
                            [void]$UncommonHeaders.Add($header.Key,$header.Value)
                        }
                    }
                    catch{
                        Write-Error $_
                    }
                }
                #Check if expect is present
                $exists = $PSBoundParameters['Headers'].GetEnumerator() | Where-Object {$_.Key.ToString().ToLower() -eq 'expect'} -ErrorAction Ignore
                if($null -eq $exists){
                    $request.Headers.ExpectContinue = $False
                }
            }
            else{
                #Remove expect 100-continue
                $request.Headers.ExpectContinue = $False
            }
            #Add referer
            if($PSBoundParameters.ContainsKey('Referer') -and $PSBoundParameters['Referer']){
                $request.Headers.Referrer = $PSBoundParameters['Referer']
            }
            #Check if uncommon headers present
            if($UncommonHeaders.Count -gt 0){
                foreach($header in $UncommonHeaders.GetEnumerator()){
                    Write-Debug ($script:messages.AddUncommonHeaderInfo -f $header.Key)
                    [void]$request.Headers.TryAddWithoutValidation($header.Key,$header.Value)
                }
            }
        }
        catch{
            Write-Error $_
        }
    }
    End{
        return $request
    }
}