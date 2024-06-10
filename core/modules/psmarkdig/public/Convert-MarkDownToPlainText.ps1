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

function Convert-MarkDownToPlainText {
    <#
        .SYNOPSIS
        Convert Markdown to plain text

        .DESCRIPTION
        Convert Markdown to plain text

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Convert-MarkDownToPlainText
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding(DefaultParameterSetName = 'InputObject')]
    [OutputType([String])]
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory = $false, ParameterSetName = 'Path', position=1)]
        [string] $Path,
        [Parameter(ValueFromPipeline=$true, Mandatory = $false, ParameterSetName = 'InputObject', position=0)]
        [string] $InputObject
    )
    Process{
        try{
            $raw_markdown = $null;
            if($PSCmdlet.ParameterSetName -eq 'Path'){
                if (-not(Test-Path -Path $Path)) {
                    Write-Warning $messages.InvalidDirectoryPathError
                    break
                }
                $raw_markdown = Get-Content -Path $Path -Raw
            }
            else {
                $raw_markdown = $InputObject
            }
            if($null -ne $raw_markdown){
                #Create pipeline builder
                $pipelineBuilder = [Markdig.MarkdownPipelineBuilder]::new()
                # build the pipeline
                $pipeline = $pipelineBuilder.Build()
                # Convert to txt
                [Markdig.Markdown]::ToPlainText($raw_markdown,$pipeline)
            }
        }
        catch{
            Write-Error $_.Exception.Message
        }
    }
}
