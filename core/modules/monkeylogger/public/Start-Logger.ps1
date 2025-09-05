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

Function Start-Logger{
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSUseShouldProcessForStateChangingFunctions", "", Scope="Function")]
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$false, HelpMessage="loggers")]
        [Array]$Loggers,

        [parameter(Mandatory= $false, HelpMessage= "Initial path")]
        [String]$InitialPath,

        [parameter(Mandatory= $false, HelpMessage= "Queue logger")]
        [System.Collections.Concurrent.BlockingCollection`1[System.Management.Automation.InformationRecord]]$LogQueue,

        [parameter(Mandatory= $false, HelpMessage= "Force creation")]
        [Switch]$Force
    )
    Try{
        New-Logger @PSBoundParameters
        #Check if already created
        If($null -ne (Get-Variable -Name monkeyLogger -ErrorAction Ignore)){
            #Start runspace
            [void]$Script:monkeyLogger.start()
        }
    }
    Catch{
        Write-Error $_.Exception
        Write-Verbose $_
    }
}