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

Function Wait-MonkeyLogger{
    <#
        .SYNOPSIS
            Wait for the message queue
        .DESCRIPTION
            Wait for the message queue
        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Wait-MonkeyLogger
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
    [cmdletbinding()]
    Param
    ()
    if($null -ne (Get-Variable -Name LogQueue -ErrorAction Ignore)){
        $now = [System.Datetime]::Now
        Start-Sleep -Milliseconds 10
        while ($LogQueue.Count -gt 0) {
            Start-Sleep -Milliseconds 20
            $timeout = [System.Datetime]::Now - $now
            if ($timeout.seconds -gt 30) {
                Write-Error -Message ("{0} :: Wait timeout." -f $MyInvocation.MyCommand) -ErrorAction SilentlyContinue
                break;
            }
        }
    }
}

