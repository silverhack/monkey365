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

    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [CmdletBinding(DefaultParameterSetName = 'default')]
    [OutputType([System.Uri])]
    Param (
        [parameter(Mandatory= $True, ValueFromPipeline = $True, HelpMessage= "GitHub Url")]
        [String]$Url,

        [parameter(Mandatory= $false, ParameterSetName = 'branch_repo', HelpMessage= "Branch")]
        [String]$Branch,

        [parameter(Mandatory= $false, ParameterSetName = 'repo_version', HelpMessage= "Specific tag release")]
        [String]$Tag,

        [parameter(Mandatory= $false, ParameterSetName = 'latest_version', HelpMessage= "Use latest version")]
        [Switch]$Latest
    )
    Process{
        Try{
            #Set null
            $ghUser = $jsDelivrUrl = $absolutePath = $repository = $null
            #Set URI
            $URI = [System.Uri]::new($Url);
            #Extract user, repository and absolutePath
            If($URI.Segments.Count -gt 2 -and $URI.Host.ToLower() -eq 'github.com'){
                $ghUser = $URI.Segments[1].ToLower().TrimEnd('/')
                $repository = $URI.Segments[2].ToLower().TrimEnd('/')
                $absolutePath = -join $URI.Segments[3..($uri.Segments.Count - 1)]
            }
            If($null -ne $ghUser -and $null -ne $repository -and $null -ne $absolutePath){
                Switch($PSCmdlet.ParameterSetName.ToLower()){
                    'branch_repo'{
                        $jsDelivrUrl = ("https://cdn.jsdelivr.net/gh/{0}/{1}@{2}/{3}" -f $ghUser,$repository,$Branch,$absolutePath)
                    }
                    'repo_version'{
                        $jsDelivrUrl = ("https://cdn.jsdelivr.net/gh/{0}/{1}@{2}/{3}" -f $ghUser,$repository,$Tag,$absolutePath)
                    }
                    'latest_version'{
                        $jsDelivrUrl = ("https://cdn.jsdelivr.net/gh/{0}/{1}@{2}/{3}" -f $ghUser,$repository,"latest",$absolutePath)
                    }
                    default{
                        $jsDelivrUrl = ("https://cdn.jsdelivr.net/gh/{0}/{1}@{2}/{3}" -f $ghUser,$repository,"main",$absolutePath)
                    }
                }
            }
            If($null -ne $jsDelivrUrl){
                #Clean url
                $uri = [System.Uri]::new($jsDelivrUrl);
                $segments = $uri.AbsolutePath.Split('/', [System.StringSplitOptions]::RemoveEmptyEntries);
                $jsDelivr = ("{0}/{1}" -f $uri.GetLeftPart([System.UriPartial]::Authority), [System.String]::Join('/',$segments));
                #Write-Verbose ($Script:messages.JsDelivrInfoMessage -f $jsDelivr)
                #return URI
                [System.Uri]::new($jsDelivr);
            }
        }
        Catch{
            Write-Error $_
        }
    }
}