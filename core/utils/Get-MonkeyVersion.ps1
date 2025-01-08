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

Function Get-MonkeyVersion{
    <#
        .SYNOPSIS
        Get version of Monkey365
        .DESCRIPTION
        Get version of Monkey365

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyVersion
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    try{
        $version = $manifest = $null;
        $monkeymod = Get-Module -Name monkey365 -ErrorAction Ignore
        #Get version
        if($null -ne $monkeymod){
            $version = $monkeymod.Version.ToString()
            #Get manifest
            $fi = [System.IO.FileInfo]::new($monkeymod.Path)
            $manifest = Test-ModuleManifest -Path ("{0}/monkey365.psd1" -f $fi.Directory.FullName)
            if ($null -ne $manifest -and $manifest.PrivateData.PSData['Prerelease']){
                $prerelease = $manifest.PrivateData.PSData['Prerelease']
                if ($prerelease -and $prerelease.StartsWith('-')){
                    $version = [string]$version + $prerelease
                }
                else{
                    $version = [string]$version + '-' + $prerelease
                }
            }
        }
        #return version
        return $version
    }
    catch{
        Write-Error $_
    }
}

