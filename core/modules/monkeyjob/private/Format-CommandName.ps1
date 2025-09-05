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

Function Format-CommandName{
    <#
        .SYNOPSIS
        Format Command name used to distinguish tasks

        .DESCRIPTION
        Format Command name used to distinguish tasks

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-CommandName
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSReviewUnusedParameter", "", Scope="Function")]
    [CmdletBinding()]
    [OutputType([System.String])]
    Param (
        [Parameter(Mandatory=$True,position=0,ParameterSetName='ScriptBlock')]
        [System.Management.Automation.ScriptBlock]$ScriptBlock,

        [Parameter(Mandatory=$True,Position = 0, ParameterSetName = 'Command')]
        [String]$Command,

        [Parameter(Mandatory = $True, Position = 0, ParameterSetName = 'FilePath', HelpMessage = 'PowerShell Script file')]
        [ValidateScript(
            {
            if( -Not ($_ | Test-Path) ){
                throw ("The PowerShell file does not exist in {0}" -f (Split-Path -Path $_))
            }
            if(-Not ($_ | Test-Path -PathType Leaf) ){
                throw "The argument must be a ps1 file. Folder paths are not allowed."
            }
            if($_ -notmatch "(\.ps1)"){
                throw "The script specified argument must be of type ps1"
            }
            return $true
        })]
        [System.IO.FileInfo]$File,

        [Parameter(Mandatory=$false, HelpMessage="arguments")]
        [Object]$Arguments,

        [Parameter(Mandatory=$false)]
        $InputObject
    )
    Try{
        $commandName = $null;
        If($PSCmdlet.ParameterSetName -eq 'ScriptBlock'){
            $commandName = Get-CommandName -ScriptBlock $ScriptBlock
            If(@($commandName).Count -eq 1){
                $commandName
            }
            ElseIf(@($commandName).Count -gt 1 -and ($ScriptBlock | Test-IsCustomFunction)){
                ("CustomFunction{0}" -f (Get-Random -Maximum 1000 -Minimum 1));
            }
            Else{
                $ScriptBlock.ToString()
            }
        }
        ElseIf($PSCmdlet.ParameterSetName -eq 'Command'){
            $p = @{
                Command = $Command;
                InputObject = $InputObject;
                Arguments = $Arguments;
            }
            Format-Command @p
        }
        Else{
            $commandName = Get-CommandName -ScriptBlock {$File.FullName}
            If(@($commandName).Count -gt 1 -and ($ScriptBlock | Test-IsCustomFunction)){
                ("CustomFunction{0}" -f (Get-Random -Maximum 1000 -Minimum 1));
            }
            Else{
                $ScriptBlock.ToString()
            }
        }
    }
    Catch{
        Write-Error $_.Exception
        return $null
    }
}
