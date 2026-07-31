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

Function Format-StorageAccountKeyCreation {
<#
        .SYNOPSIS
		Utility to format Storage Account key creation

        .DESCRIPTION
		Utility to format Storage Account key creation

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-StorageAccountKeyCreation
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="Storage Account Object")]
        [Object]$InputObject
    )
    Process{
        #Format key1
        If($null -ne $InputObject.properties.keyCreationTime.key1){
            #set key1 key creation
			$InputObject.keys.keyRotation.key1.keyCreationTime = $InputObject.properties.keyCreationTime.key1
            $today = Get-Date
            $generationTime = Get-Date $InputObject.properties.keyCreationTime.key1
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.keyRotation.key1.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        Else{
            #Set last rotation date to never
            $d = [System.DateTime]::new(1970,1,1)
            $today = Get-Date
            $generationTime = Get-Date $d
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.keyRotation.key1.keyCreationTime = $d.ToString("yyyy-MM-ddThh:mm:ss.fffZ");
            $InputObject.keys.keyRotation.key1.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        #Format key2
        If($null -ne $InputObject.properties.keyCreationTime.key2){
            #set key2 key creation
			$InputObject.keys.keyRotation.key2.keyCreationTime = $InputObject.properties.keyCreationTime.key2
            $today = Get-Date
            $generationTime = Get-Date $InputObject.properties.keyCreationTime.key2
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.keyRotation.key2.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        Else{
            #Set last rotation date to never
            $d = [System.DateTime]::new(1970,1,1)
            $today = Get-Date
            $generationTime = Get-Date $d
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.keyRotation.key2.keyCreationTime = $d.ToString("yyyy-MM-ddThh:mm:ss.fffZ");
            $InputObject.keys.keyRotation.key2.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        #Return object
        return $InputObject
    }
}
