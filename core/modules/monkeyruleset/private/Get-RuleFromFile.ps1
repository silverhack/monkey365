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

Function Get-RuleFromFile{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-RuleFromFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    Param (
        [parameter(Mandatory=$true, HelpMessage="File name")]
        [string]$fileName,

        [parameter(Mandatory=$true, HelpMessage="Directory containing rules")]
        [String]$rulepath
    )
    $file = $null
    $exists = [System.IO.Directory]::Exists($rulepath)
    if($exists){
        [System.IO.DirectoryInfo]$root_dir = New-Object IO.DirectoryInfo($rulepath)
        $file = $root_dir.EnumerateFiles($fileName, `
                                        [system.IO.SearchOption]::AllDirectories)
    }
    else{
        Write-Warning -Message ($Script:messages.InvalidDirectoryPathError -f $rulepath)
        return $false
    }
    try{
        if(@($file).Count -gt 0){
            If(@($file).Count -eq 1){
                return $file
            }
            else{
                Write-Warning -Message ($Script:messages.DuplicateFileFound -f $fileName, $rulepath)
                #return full name
                return ($file | Select-Object -First 1)
            }
        }
        else{
            Write-Warning -Message ($Script:messages.FileNotFound -f $fileName, $rulepath)
            return $false
        }
    }
    catch{
        Write-Verbose $_.Exception.Message
        #Debug
        Write-Debug -Message $_.Exception
        #return false
        return $false
    }
}
