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

Function Get-File{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-File
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, ParameterSetName='Filename', HelpMessage="File name")]
        [string]$FileName,

        [parameter(Mandatory=$true, ParameterSetName='Filter', HelpMessage="Filter")]
        [string]$Filter,

        [parameter(Mandatory=$true, HelpMessage="Directory containing rules")]
        [String]$Rulepath
    )
    $file = $null
    $exists = [System.IO.Directory]::Exists($Rulepath)
    if($exists){
        try{
            [System.IO.DirectoryInfo]$root_dir = New-Object IO.DirectoryInfo($Rulepath)
            if($PSCmdlet.ParameterSetName -eq 'Filename'){
                $file = $root_dir.EnumerateFiles(
                            $FileName, `
                            [system.IO.SearchOption]::AllDirectories
                        )
            }
            else{
                $file = $root_dir.EnumerateFiles(
                            $Filter, `
                            [system.IO.SearchOption]::AllDirectories
                        )
            }
        }
        catch{
            Write-Warning -Message ($Script:messages.InvalidDirectoryPathError -f $FileName)
            Write-Verbose $_.Exception.Message
        }
    }
    else{
        Write-Warning -Message ($Script:messages.InvalidDirectoryPathError -f $rulepath)
        return $null
    }
    try{
        if(@($file).Count -gt 0){
            if($PSCmdlet.ParameterSetName -eq 'Filename'){
                If(@($file).Count -eq 1){
                    $file
                }
                else{
                    Write-Warning -Message ($Script:messages.DuplicateFileFound -f $fileName, $rulepath)
                    #return full name
                    ($file | Select-Object -First 1)
                }
            }
            else{
                $file
            }
        }
        else{
            Write-Warning -Message ($Script:messages.FileNotFound -f $fileName, $rulepath)
        }
    }
    catch{
        Write-Verbose $_.Exception.Message
        #Debug
        Write-Debug -Message $_.Exception
    }
}


