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

Function Get-MonkeyLatestReleaseFromGitHub{
    <#
        .SYNOPSIS
        Get the latest published full release for the repository

        .DESCRIPTION
        Get the latest published full release for the repository

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyLatestReleaseFromGitHub
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    [OutputType([System.String])]
    Param (
        [parameter(Mandatory=$true, ValueFromPipeline = $True, HelpMessage="GitHub repository")]
        [String]$Url
    )
    Process{
        #Set null
        $repoUrl = $ghUser = $repository = $null
        $URI = [System.Uri]::new($Url);
        If($URI.Segments.Count -gt 2 -and $URI.Host.ToLower() -eq 'github.com'){
            $ghUser = $URI.Segments[1].ToLower().TrimEnd('/')
            $repository = $URI.Segments[2].ToLower().TrimEnd('/')
            If($null -ne $ghUser -and $null -ne $repository){
                $repoUrl = ('https://api.github.com/repos/{0}/{1}/releases/latest' -f $ghUser,$repository);
            }
        }
        If($null -ne $repoUrl){
            Try{
                $rawContent = Invoke-WebRequest -Uri $repoUrl -UseBasicParsing
                If($rawContent.StatusCode -eq [System.Net.HttpStatusCode]::OK){
                    $content = $rawContent.Content | ConvertFrom-Json
                    Write-Verbose ("Found {0}" -f $content.html_url)
                    $content.tag_name.TrimStart('v')
                }
            }
            Catch{
                Write-Warning $_.Exception.Message
            }
        }
    }
}
