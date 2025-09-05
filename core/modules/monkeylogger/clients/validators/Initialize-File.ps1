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
# See the License for the specIfic language governing permissions and
# limitations under the License.

Function Initialize-File {
    <#
        .SYNOPSIS

        .DESCRIPTION

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Initialize-File
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>

    [CmdletBinding()]
    [OutputType([System.Boolean])]
    Param (
        [object] $Configuration
    )
    $pass = $false
    $dates = @('yyyyMMdd','yyyyMMddhhmmss')
    If($null -ne $Configuration -and $null -ne $Configuration.Filename){
        #Get file name
        $filename = [io.path]::GetFileName($Configuration.Filename)
        #Get Full Path
        $fullPath = $Configuration.Filename
        #Check If bad chars
        If($filename.IndexOfAny([System.IO.Path]::GetInvalidFileNameChars()) -eq -1){
            #Get extension and filename without extension
            #$extension = [io.path]::GetExtension($Configuration.Filename)
            $file_we = [io.path]::GetFileNameWithoutExtension($Configuration.Filename)
            #check datetime format
            foreach($d in $dates){
                $dateformat = [System.Text.RegularExpressions.Regex]::Escape($d)
                If($file_we -match $dateformat){
                    $date = (Get-Date).ToString($d)
                    $fullPath = $Configuration.Filename -replace $d,$date
                }
            }
            #Create file
            Try{
                #$PWD.Path sometimes getting wrong path
                #(Get-Location).Path sometimes resolve to the wrong path (system32)
                $isPathRooted = [System.IO.Path]::IsPathRooted($fullPath)
                If(-NOT $isPathRooted){
                    $fullPath = ("{0}{1}{2}" -f (Get-Location -PSProvider FileSystem).ProviderPath, [System.IO.Path]::DirectorySeparatorChar, $fullPath)
                }
                If ((Test-Path -Path $fullPath)){
                    $msg = [hashtable] @{
                        MessageData = ("Log file {0} already exists on {1}" -f $filename, [System.IO.Path]::GetDirectoryName($fullPath))
                        InformationAction = $script:monkeyloggerinfoAction
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        logLevel = 'verbose';
                        tags = @('MonkeyLogAlreadyExists')
                    }
                    Write-Verbose @msg
                    $Configuration.Filename = $fullPath
                    $pass = $true
                }
                Else{
                    [void][System.IO.Directory]::CreateDirectory([System.IO.Path]::GetDirectoryName($fullPath));
                    [void][System.IO.File]::Create($fullPath);
                    $filename = [io.path]::GetFileName($fullPath)
                    $msg = [hashtable] @{
                        MessageData = ("Log file {0} created successfully on {1}" -f $filename, [System.IO.Path]::GetDirectoryName($fullPath))
                        InformationAction = $script:monkeyloggerinfoAction
                        callStack = (Get-PSCallStack | Select-Object -First 1);
                        ForeGroundColor = "Green"
                        tags = @('MonkeyLog')
                    }
                    Write-Information @msg
                    $Configuration.Filename = $fullPath
                    $pass = $true
                }
            }
            Catch [System.IO.IOException]{
                $msg = [hashtable] @{
                    MessageData = ("Unable to create log file in {0}" -f [System.IO.Path]::GetDirectoryName($fullPath))
                    InformationAction = $script:monkeyloggerinfoAction
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Warning';
                    tags = @('MonkeyLog')
                }
                Write-Warning @msg
                $msg.MessageData = $_.Exception.Message
                $msg.ForeGroundColor = "Red"
                Write-Error @msg
                $pass = $false
            }
            Catch{
                $msg = [hashtable] @{
                    MessageData = $_
                    InformationAction = $script:monkeyloggerinfoAction
                    callStack = (Get-PSCallStack | Select-Object -First 1);
                    logLevel = 'Error';
                    tags = @('MonkeyLog')
                }
                Write-Error @msg
                $pass = $false
            }
        }
        Else{
            $pass = $false
        }
    }
    Else{
        $pass = $false
    }
    #return pass
    return $pass
}

