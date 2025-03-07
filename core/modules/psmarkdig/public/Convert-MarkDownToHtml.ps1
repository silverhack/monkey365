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

function Convert-MarkDownToHtml {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-MarkDownToHtml
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    [OutputType([String])]
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory = $false, ParameterSetName = 'Path', position=1)]
        [String]$Path,

        [Parameter(ValueFromPipeline=$true, Mandatory = $false, ParameterSetName = 'InputObject', position=0)]
        [String]$InputObject,

        [Parameter(Mandatory=$false, HelpMessage="Use advanced extensions")]
        [Switch]$UseAdvancedExtensions,

        [Parameter(Mandatory=$false, HelpMessage="Remove blank and tabs from text")]
        [Switch]$RemoveBlankAndTabs
    )
    Begin{
        $raw_markdown = $outHtml = $null
    }
    Process{
        If($PSCmdlet.ParameterSetName -eq 'Path'){
            If (-not(Test-Path -Path $Path)) {
                Write-Warning $messages.InvalidDirectoryPathError
                break
            }
            $raw_markdown = Get-Content -Path $Path -Raw
        }
        Else {
            $raw_markdown = $InputObject
        }
        Try{
            If($null -ne $raw_markdown){
                #Create pipeline builder
                $pipelineBuilder = [Markdig.MarkdownPipelineBuilder]::new()
                #Add markdig extensions
                switch ($PSBoundParameters.Keys)
                {
                    'UseAdvancedExtensions'
                    {
                        [void][Markdig.MarkdownExtensions]::UseAdvancedExtensions($pipelineBuilder)
                    }

                }
                # build the pipeline
                $pipeline = $pipelineBuilder.Build()
                #Check to remove blank and tabs
                If($RemoveBlankAndTabs.IsPresent){
                    $pattern = "[ \t]*\n[ \t]*"
                    $options = [text.regularexpressions.regexoptions]::Multiline
                    $text = [regex]::Replace($raw_markdown,$pattern,[system.environment]::NewLine,$options)
                    $raw_markdown = $text.Trim();
                }
                # Convert to html
                $outHtml = [Markdig.Markdown]::ToHtml($raw_markdown,$pipeline)
                If($null -ne $outHtml){
                    return $outHtml.Trim()
                }
            }
        }
        Catch{
            Write-Error $_.Exception.Message
        }
    }
    End{
        #Nothing to do here
    }
}


