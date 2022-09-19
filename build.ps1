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

<#
.DESCRIPTION
Small script for building and tagging docker images. Dockerfiles for both Linux and Windows containers are located in the /docker directory for your use.

.NOTES
	Author		: Juan Garrido
    Twitter		: @tr1ana
    File Name	: build.ps1
    Version     : 1.0

.LINK
    https://github.com/silverhack/monkey365

.EXAMPLE
	.\build.ps1 -Name monkey365 -version latest -path ./docker/Dockerfile_linux

This example will create a linux Docker image named "monkey365"

.PARAMETER Name
	Docker image name

.PARAMETER version
	Version. Used for tag image. Default value is "latest"

.PARAMETER Path
	The Path option specifies the Docker file. The build context is set to the current working directory

#>
[CmdletBinding()]
param (
    [parameter(Mandatory= $false, HelpMessage= "Docker image name")]
    [String]$Name = "monkey365",

    [parameter(Mandatory= $false, HelpMessage= "Docker version")]
    [String]$version = "latest",

    [parameter(Mandatory= $false, HelpMessage= "dockerfile to load")]
    [ValidateScript(
        {
            if( -Not ($_ | Test-Path) ){
                throw ("The docker file does not exist in {0}" -f (Split-Path -Path $_))
            }
            return $true
    })]
    [System.IO.FileInfo]$Path
)
$buildDate = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
$tag = ("{0}:{1}" -f $Name, $version)
$DockerFile = $Path.ToString()
$buildArgs = @(
    "build",
    "--rm",
    "--file $DockerFile",
    "--tag $tag",
    "--build-arg VERSION=$version",
    "--build-arg VCS_URL='https://github.com/silverhack/monkey365'",
    "--build-arg BUILD_DATE='$buildDate'",
    "."
)
#write message
$param = @{
    MessageData = ("Building dockerfile using file {0} and tag {0}" -f $Path, $tag)
}
Write-information @param
#Start process
Start-Process docker -ArgumentList $buildArgs -NoNewWindow -Wait