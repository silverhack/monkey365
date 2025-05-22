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

Function Get-MonkeyUserAgent{
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Get-MonkeyUserAgent
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    Param()
    $userAgent = $version = $manifest = $null;
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
    #Check if O365Object exists
    if($null -ne (Get-Variable -Name O365Object -Scope Script -ErrorAction Ignore)){
        #Set UserAgent
        try{
            if(![System.String]::IsNullOrEmpty($O365Object.internal_config.httpSettings.userAgent)){
                $userAgent = $O365Object.internal_config.httpSettings.userAgent
            }
        }
        catch{
            Write-Verbose $_
        }
    }
    if($null -eq $userAgent){
        $userAgent = ("Monkey365 {0} ({1}) {2}" -f $version.ToString(), `
                        [System.Environment]::OSVersion.Platform.ToString(), `
                        [System.Environment]::OSVersion.VersionString.ToString())
    }
    #return UA
    return $userAgent
}

