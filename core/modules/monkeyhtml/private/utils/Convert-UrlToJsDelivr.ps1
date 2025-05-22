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

Function Convert-UrlToJsDelivr{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-UrlToJsDelivr
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.Uri])]
    Param (
        [parameter(Mandatory= $True, HelpMessage= "Url")]
        [String]$Url,

        [parameter(Mandatory= $false, HelpMessage= "Branch")]
        [String]$Branch = "main",

        [parameter(Mandatory= $false, HelpMessage= "Use latest version")]
        [Switch]$Latest
    )
    Process{
        Try{
            $user = ($Url -split "github.com")[1].Split('/')[1]
            $repository = ($Url -split "github.com")[1].Split('/')[2]
            $absolutePath = ($Url -split $repository)[1]
            #Convert to jsDelivr URL
            If($Latest.IsPresent){
                $jsDelivr = ("https://cdn.jsdelivr.net/gh/{0}/{1}@{2}/{3}" -f $user,$repository,"latest",$absolutePath)
            }
            Else{
                $jsDelivr = ("https://cdn.jsdelivr.net/gh/{0}/{1}@{2}/{3}" -f $user,$repository,$Branch,$absolutePath)
            }
            Write-Verbose ($Script:messages.JsDelivrInfoMessage -f $jsDelivr)
            #return URI
            [System.Uri]::new($jsDelivr);
        }
        Catch{
            Write-Error $_
        }
    }
}