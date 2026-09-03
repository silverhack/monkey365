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

Function Format-CosmosDBKey {
<#
        .SYNOPSIS
		Utility to format CosmosDB read-write keys

        .DESCRIPTION
		Utility to format CosmosDB read-write keys

        .INPUTS

        .OUTPUTS

        .EXAMPLE

        .NOTES
	        Author		: Juan Garrido
            Twitter		: @tr1ana
            File Name	: Format-CosmosDBKey
            Version     : 1.0

        .LINK
            https://github.com/silverhack/monkey365
    #>
	[CmdletBinding()]
	Param (
        [Parameter(Mandatory=$True, ValueFromPipeline = $True, HelpMessage="CosmosDB Object")]
        [Object]$InputObject
    )
    Process{
        #Format primaryMasterKey
        If($null -ne $InputObject.keys.primaryMasterKey.generationTime){
            $today = Get-Date
            $generationTime = Get-Date $InputObject.keys.primaryMasterKey.generationTime
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.primaryMasterKey.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        #Format secondaryMasterKey
        If($null -ne $InputObject.keys.secondaryMasterKey.generationTime){
            $today = Get-Date
            $generationTime = Get-Date $InputObject.keys.secondaryMasterKey.generationTime
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.secondaryMasterKey.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        #Format primaryReadonlyMasterKey
        If($null -ne $InputObject.keys.primaryReadonlyMasterKey.generationTime){
            $today = Get-Date
            $generationTime = Get-Date $InputObject.keys.primaryReadonlyMasterKey.generationTime
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.primaryReadonlyMasterKey.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        #Format primaryMasterKey
        If($null -ne $InputObject.keys.secondaryReadonlyMasterKey.generationTime){
            $today = Get-Date
            $generationTime = Get-Date $InputObject.keys.secondaryReadonlyMasterKey.generationTime
            $timeSpan = New-TimeSpan -Start $generationTime -End $today
            $InputObject.keys.secondaryReadonlyMasterKey.lastRotatedInDays = [int][Math]::Ceiling($timeSpan.TotalDays)
        }
        #Return object
        return $InputObject
    }
}
