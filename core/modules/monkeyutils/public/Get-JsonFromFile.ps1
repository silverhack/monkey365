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

Function Get-JsonFromFile{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-JsonFromFile
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param (
        [parameter(Mandatory=$true, HelpMessage="Directory containing JSON files")]
        [String]$path
    )
    $json_object = New-Object -TypeName PSCustomObject
    $exists = [System.IO.Directory]::Exists($path)
    if($exists){
        [System.IO.DirectoryInfo]$root_dir = New-Object IO.DirectoryInfo($path)
        $files = $root_dir.EnumerateFiles("*.json", `
                                        [system.IO.SearchOption]::AllDirectories)
    }
    else{
        Write-Warning -Message ($Script:messages.InvalidDirectoryPathError -f $path)
        return $null
    }
    try{
        if(@($files).Count -gt 0){
            foreach($f in $files){
                try{
                    $json_data = Get-Content -Raw -Path $f.FullName | ConvertFrom-Json -ErrorAction Ignore
                }
                catch{
                    Write-Warning ("Error in {0}" -f $f.FullName)
                    $json_data = $null
                }
                if($null -ne $json_data){
                    #Get NoteProperty
                    $raw_json = $json_data.psobject.Properties | Where-Object {$_.MemberType -eq 'NoteProperty'} -ErrorAction Ignore
                    if($null -ne $raw_json){
                        foreach($sub_element in $raw_json){
                            #Add to object
                            $json_object | Add-Member -type NoteProperty -name $sub_element.name -value $sub_element.Value
                        }
                    }
                }
                else{
                    Write-Warning -Message ($Script:messages.InvalidJsonErrorMessage -f $f.FullName)
                }
            }
            if($json_object){
                return $json_object
            }
        }
        else{
            Write-Verbose -Message ($Script:messages.JsonFilesNotFound -f $path)
            return $null
        }
    }
    catch{
        Write-Error $_
        Write-Verbose $_.Exception
        #Debug
        Write-Debug -Message $_.Exception.StackTrace
        #return false
        return $null
    }
}

