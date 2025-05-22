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

function Get-LocalizedData{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-LocalizedData
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Position = 1, ParameterSetName = 'TargetedUICulture')]
        [System.String]
        $UICulture,

        [Parameter()]
        [System.String]
        $BaseDirectory,

        [Parameter()]
        [System.String]
        $FileName,

        [Parameter(Position = 1, ParameterSetName = 'DefaultUICulture')]
        [System.String]
        $DefaultUICulture
    )
    Begin{
        if (!$PSBoundParameters.ContainsKey('FileName')){
            if ($myInvocation.ScriptName){
                $file = [System.IO.FileInfo] $myInvocation.ScriptName
            }
            else{
                $file = [System.IO.FileInfo] $myInvocation.MyCommand.Module.Path
            }
            $FileName = $file.BaseName
            #$PSBoundParameters.Add('FileName', $file.Name)
        }
        if ($PSBoundParameters.ContainsKey('BaseDirectory')){
            $callingScriptRoot = $BaseDirectory
        }
        else{
            $callingScriptRoot = $MyInvocation.PSScriptRoot
            $PSBoundParameters.Add('BaseDirectory', $callingScriptRoot)
        }
        if ($PSBoundParameters.ContainsKey('DefaultUICulture') -and !$PSBoundParameters.ContainsKey('UICulture')){
            <#
                We don't want the resolution to eventually return the ModuleManifest
                so we run the same GetFilePath() logic than here:
                https://github.com/PowerShell/PowerShell/blob/master/src/Microsoft.PowerShell.Commands.Utility/commands/utility/Import-LocalizedData.cs#L302-L333
                and if we see it will return the wrong thing, set the UICulture to DefaultUI culture, and return the logic to Import-LocalizedData
            #>
            $currentCulture = Get-UICulture
            $languageFile = $null
            $localizedFileNames = @(
                $FileName + '.psd1'
                $FileName + '.strings.psd1'
            )
            while ($null -ne $currentCulture -and $currentCulture -is [System.Globalization.CultureInfo] -and !$languageFile){
                if($currentCulture.Name.Length -gt 0){
                    $cultureName = $currentCulture.Name
                }
                else{
                    $cultureName = 'en-US'
                }
                foreach ($fullFileName in $localizedFileNames){
                    $filePath = [io.Path]::Combine($callingScriptRoot, $cultureName, $fullFileName)
                    if (Test-Path -Path $filePath){
                        Write-Verbose -Message "Found $filePath"
                        $languageFile = $filePath
                        # Set the filename to the file we found.
                        $PSBoundParameters['FileName'] = $fullFileName
                        $PSBoundParameters['BaseDirectory'] = [io.Path]::Combine($callingScriptRoot, $cultureName)
                        # Exit loop if we find the first filename.
                        break
                    }
                    else{
                        Write-Verbose -Message "File $filePath not found"
                    }
                }
                $currentCulture = $currentCulture.Parent
            }
            if (!$languageFile){
                $PSBoundParameters.Add('UICulture', $DefaultUICulture)
            }
            $null = $PSBoundParameters.Remove('DefaultUICulture')
        }
    }
    Process{
        #Import localized Data
        if($PSBoundParameters.ContainsKey('FileName') -and $fullFileName){
            Import-LocalizedData @PSBoundParameters
        }
        else{
            Write-Warning "Unable to get Localized data file"
        }
    }
    End{
        #Nothing to do here
    }
}


